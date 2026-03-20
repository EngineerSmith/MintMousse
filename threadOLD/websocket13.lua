local ffi = require("ffi")

local lt = love.timer

-- As bitfield order (LSB or MSB) isn't defined in C standard.
--   We aim to support both compilers to avoid issues for end users.
--   We do this by testing how it packs a dummy struct and then defining a struct for that system.

ffi.cdef([[
  typedef struct {
    uint8_t front:1;
    uint8_t last:7;
  } mm_bitfieldTest;
]])

local bitfieldTest = ffi.new("mm_bitfieldTest");
bitfieldTest.front = 1

local rawByteValue = ffi.cast("uint8_t*", bitfieldTest)[0];
if rawByteValue == 0x01 then
  love.mintmousse.info("WS13: Switching to using LSB for bitfields")
  -- https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers#format
  ffi.cdef([[
    typedef struct {
    // Byte 1
      uint8_t opcode:4;
      uint8_t rsv3:1;
      uint8_t rsv2:1;
      uint8_t rsv1:1;
      uint8_t fin:1;
    // Byte 2
      uint8_t payload_len:7;
      uint8_t masked:1;
    } mm_websocket_header;
  ]])
elseif rawByteValue == 0x80 then
  love.mintmousse.info("WS13: Switching to using MSB for bitfields")
  ffi.cdef([[
    typedef struct {
    // Byte 1
      uint8_t fin:1;
      uint8_t rsv1:1;
      uint8_t rsv2:1;
      uint8_t rsv3:1;
      uint8_t opcode:4;
    // Byte 2
      uint8_t masked:1;
      uint8_t payload_len:7;
    } mm_websocket_header;
  ]])
else
  love.mintmousse.warning("Could not determine bitfield packing order. This might indicate unusual compiler behaviour or padding. Attempting to use LSB, expect possible errors.")
  ffi.cdef([[
    typedef struct {
    // Byte 1
      uint8_t opcode:4;
      uint8_t rsv3:1;
      uint8_t rsv2:1;
      uint8_t rsv1:1;
      uint8_t fin:1;
    // Byte 2
      uint8_t payload_len:7;
      uint8_t masked:1;
    } mm_websocket_header;
  ]])

  -- todo, switch to using bit library as a backup for non-ffi support, but that still requires bit
end
bitfieldTest, rawByteValue = nil, nil

local websocket13 = { }

websocket13.processRequest = function(client)
  local request = {
    payload = "",
  }

  while true do
    local header_bytes = client:receive(2)

    if not header_bytes then return nil, "UNKNOWN" end

    local header = ffi.cast("mm_websocket_header*", header_bytes)

    -- All client-server frames must be masked
    if header.masked == 0 then return nil, "client sent unmasked frames: 0x"..love.data.encode("string", "hex", ffi.string(header_bytes, 2)) end  

    -- Opcode https://en.wikipedia.org/wiki/WebSocket#Opcodes
    if not request.type then
      if header.opcode == 0x0 then
        return nil, "error" -- First frame cannot have a 0x0 continuation opcode
      elseif header.opcode == 0x1 then
        request.type = "text/utf8"
      elseif header.opcode == 0x2 then
        request.type = "binary"
      elseif header.opcode == 0x8 then
        request.type = "close"
      elseif header.opcode == 0x9 then
        if header.fin == 0 then return nil, "client sent ping with unclosed frame" end
        request.type = "ping"
      elseif header.opcode == 0xA then
        if header.fin == 0 then return nil, "client sent pong with unclosed frame" end
        request.type = "pong"
      end
    else
      -- all continuation frames must have a 0x0 continuation opcode
      if header.opcode ~= 0x0 then
        return nil, "client sent non-continuation in later frames"
      end
    end

    local payloadLength = header.payload_len
    if request.type == "ping" and payloadLength > 125 then
      return nil, "client sent ping with invalid payload"
    end

    if payloadLength == 126 then
      local len_bytes = client:receive(2)
      if not len_bytes or #len_bytes ~= 2 then return nil, "UNKNOWN" end
      payloadLength = love.data.unpack(">I2", len_bytes)
    elseif payload_len == 127 then
      local len_bytes = client:receive(8)
      if not len_bytes or #len_bytes ~= 8 then return nil, "UNKNOWN" end
      payloadLength = love.data.unpack(">I8", len_bytes)
    end

    local masking_key = client:receive(4)
    if not masking_key then return nil, "UNKNOWN" end
    local payload = client:receive(payloadLength)
    if not payload then return nil, "UNKNOWN" end

    local unmaskedPayloadTable = { }
    for i = 0, #payload - 1 do
      local maskedByte = string.byte(payload, i + 1)
      local maskingByte = string.byte(masking_key, i % 4 + 1)
      unmaskedPayloadTable[i + 1] = string.char(bit.bxor(maskedByte, maskingByte))
    end
    local unmaskedPayload = table.concat(unmaskedPayloadTable)

    request.payload = request.payload .. unmaskedPayload

    if coroutine.running() then
      coroutine.yield(true)
    end
    if header.fin == 1 then
      break
    end
    if not coroutine.running() then
      lt.sleep(0.0001)
    end
  end

  return request
end

local maxChunk = 65535
websocket13.send = function(client, opcode, payload)
  local header = ffi.new("mm_websocket_header")
  header.fin = 0
  header.rsv1, header.rsv2, header.rsv3 = 0, 0, 0
  header.opcode = opcode
  header.masked = 0

  local payloadLength = payload and #payload or 0
  if payloadLength == 0 then
    header.fin = 1
    header.payload_len = 0
    local headerBytes = ffi.string(ffi.cast("void*", header), 2)
    client:send(headerBytes)
    return
  end

  for offset = 1, payloadLength, maxChunk do
    local chunk = payload:sub(offset, offset + maxChunk - 1)

    if offset + maxChunk - 1 >= payloadLength then
      header.fin = 1
    end

    local headerBytes
    if #chunk <= 125 then
      header.payload_len = #chunk
      headerBytes = ffi.string(ffi.cast("void*", header), 2)
    elseif #chunk <= 65535 then
      header.payload_len = 126
      headerBytes = ffi.string(ffi.cast("void*", header), 2)
      headerBytes = headerBytes .. love.data.pack("string", ">I2", #chunk)
    else
      header.payload_len = 127
      headerBytes = ffi.string(ffi.cast("void*", header), 2)
      headerBytes = headerBytes .. love.data.pack("string", ">I8", #chunk)
    end
    client:send(headerBytes .. chunk)

    header.opcode = 0x0
  end
end

websocket13.handleRequest = function(client, request)
  if request.type == "ping" then
    websocket13.send(client, 0xA, request.payload)
  elseif request.type == "pong" then
    love.mintmousse.info("WS13: Received pong from client")
  elseif request.type == "close" then
    websocket13.send(client, 0x8, "Close response")
    return "close"
  end
end

websocket13.newConnection = function(client)
  love.mintmousse.warning("WS13: Need to overwrite websocket13.newConnection callback")
end

websocket13.closeConnection = function(client, reason)

  websocket13.send(client, 0x8, reason or "Request closing")

  local startTime, timeout = lt.getTime(), coroutine.running() and 5 or 1
  while lt.getTime() - startTime < timeout do
    local peek = client.client:receive(1)
    if peek then
      local request, errorMessage = websocket13.processRequest(client, peek)
      if not request then
        love.mintmousse.info("WS13: Received error when trying to close WebSocket:", errorMessage)
      elseif request.type == "close" then
        break
      end
    end
    if coroutine.running() then
      coroutine.yield(true)
    else
      lt.sleep(0.0001)
    end
  end 
  client:close()
  if coroutine.running() then
    coroutine.yield(nil) -- ending the coroutine
  end
end

return websocket13