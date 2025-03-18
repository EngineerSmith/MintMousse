local ffi = require("ffi")
-- https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers#format
ffi.cdef([[
  typedef struct {
    uint8_t fin:1;
    uint8_t rsv1:1;
    uint8_t rsv2:1;
    uint8_t rsv3:1;
    uint8_t opcode:4;
    uint8_t masked:1;
    uint8_t payload_len:7;
  } websocket_header;
]])

local websocket13 = { }

websocket13.processRequest = function(client)
  local request = {
    payload = "",
  }

  while true do
    local header_bytes = client:receive(2)
    if not header_bytes then return nil, "UNKNOWN" end

    local header = ffi.cast("websocket_header*", header_bytes)

    -- All client-server frames must be masked
    if header.masked == 0 then return nil, "client sent unmasked frames" end  

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
        request.type = "ping" --todo handle; ping should return the exact same payload
      elseif header.opcode == 0xA then
        if header.fin == 0 then return nil, "client sent pong with unclosed frame" end
        request.type = "pong" --todo handle
      end
    else
      -- all continuation frames must have a 0x0 continuation opcode
      if header.opcode ~= 0x0 then
        return nil, "client sent non-continuation in latter frames"
      end
    end

    local payloadLength = header.payload_len
    if request.type == "ping" and payloadLength > 125 then
      return nil, "client sent ping with invalid payload"
    end

    if payloadLength == 126 then
      local len_bytes = client:receive(2)
      if not len_bytes or #len_bytes ~= 2 then return nil, "UNKNOWN" end
      payloadLength = love.data.unpack(">I[2]", len_bytes)
    elseif payload_len == 127 then
      local len_bytes = client:receive(8)
      if not len_bytes or #len_bytes ~= 8 then return nil, "UNKNOWN" end
      payloadLength = love.data.unpack(">I[8]", len_bytes)
    end

    local masking_key = client:receive(4)
    if not masking_key then return nil, "UNKNOWN" end
    local payload = client:receive(payloadLength)
    if not payload then return nil, "UNKNOWN" end

    local unmaskedPayloadTable = {}
    for i = 0, #payload + 1 do
      local maskedByte = string.byte(payload, i + 1)
      local maskingByte = string.byte(masking_key, i % 4 + 1)
      unmaskedPayloadTable[i + 1] = string.char(bit.xor(maskedByte, maskingByte))
    end
    local unmaskedPayload = table.concat(unmaskedPayloadTable)

    request.payload = request.payload .. unmaskedPayload

    if header.fin == 1 then
      break
    end
  end

  return request
end

return websocket13