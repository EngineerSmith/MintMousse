local lt = love.timer
local ffi = require("ffi")
local bit = require("bit")

local json = require(PATH .. "libs.json")

local loggerWS13 = require(PATH .. "thread.server.protocol.logger"):extend("WebSocket13")

-- Useful links:
-- - https://www.rfc-editor.org/rfc/rfc6455 
-- - https://en.wikipedia.org/wiki/WebSocket
-- - https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API
local websocket13 = {
  events = { },
}

websocket13.on = function(eventName, callback)
  websocket13.events[eventName] = callback
end

websocket13.emit = function(eventName, ...)
  if websocket13.events[eventName] then
    websocket13.events[eventName](...)
  end
end

websocket13.validateWebSocketKey = function(key)
  if type(key) ~= "string" or not key:match("^[%u%l%d+/]+=*$") then
    return false
  end

  local success, decodedKey = pcall(love.data.decode, "string", "base64", key)
  return success and #decodedKey == 16
end

if love._version_major >= 12 then
  websocket13.getWebSocketAcceptKey = function(key)
    local keyBD = love.data.newByteData(key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
    local accept = love.data.hash("data", "sha1", keyBD)
    return love.data.encode("string", "base64", accept)
  end
else
  websocket13.getWebSocketAcceptKey = function(key)
    local keyBD = love.data.newByteData(key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
    local accept = love.data.hash("sha1", keyBD)
    return love.data.encode("string", "base64", accept)
  end
end

websocket13.process = function(client)
  local request, errorMessage, errorCode = websocket13.processRequest(client)

  if not request then
    if errorMessage == "timeout" then
      return "keep-alive"
    end
    loggerWS13:warning("WebSocket encountered an error:", errorMessage)
    websocket13.close(client, errorCode or 1002, errorMessage or "Protocol Error")
    return "close"
  end

  if request.type == "text/utf8" or request.type == "binary" then
    websocket13.emit("message", client, request)
  elseif request.type == "close" then
    -- Client requested close
    websocket13.close(client, request.statusCode, request.reason, true)
    return "close"
  end

  return "keep-alive"
end

websocket13.idle = function(client)
  local now = lt.getTime()
  client.lastSeen = client.lastSeen or now
  client.lastPing = client.lastPing or now

  if now - client.lastSeen > love.mintmousse.TIMEOUT_WEBSOCKET then
    return "close"
  end

  if now - client.lastPing > love.mintmousse.PING_WEBSOCKET then
    websocket13.send(client, 0x9, "")
    client.lastPing = now
  end

  if #client.outgoing == 0 then
    return "keep-alive"
  end

  local maxSize = love.mintmousse.MAX_WEBSOCKET_MESSAGE_SIZE
  local batch = client.outgoing
  local outgoingSize = #batch

  local payload
  local numSent = 0

  if outgoingSize <= 25 then
    local success, encoded = pcall(json.encode, batch)
    if success and #encoded <= maxSize then
      payload = encoded
      numSent = outgoingSize
    end
  end

  if not payload then
    local parts = { }
    local totalLength = 2 -- incl. '[' and ']'

    for i = 1, outgoingSize do
      local success, encoded = pcall(json.encode, batch[i])
      if not success then
        loggerWS13:warning("Failed to encode outgoing message #" .. i .. " (dropped). Reason:", encoded)
        if i == 1 then
          table.remove(batch, 1)
          return 'keep-alive'
        end
        break
      end
      local addLength = (i == 1 and 0 or 1) + #encoded -- incl. ',' after first index
      if i > 1 and totalLength + addLength > maxSize then
        break
      end

      table.insert(parts, encoded)
      totalLength = totalLength + addLength
    end
    payload = "[" .. table.concat(parts, ",") .. "]"
    numSent = #parts
  end

  websocket13.send(client, 0x1, payload)

  if numSent == outgoingSize then
    client.outgoing = { }
  else
    local remaining = { }
    for i = numSent + 1, outgoingSize do
      table.insert(remaining, batch[i])
    end
    client.outgoing = remaining
  end

  return 'keep-alive'
end

local outSize = love.mintmousse.MAX_WEBSOCKET_FRAME_SIZE
local out_PTR = ffi.new("uint8_t[?]", outSize)
local out32_PTR = ffi.cast("uint32_t*", out_PTR)

websocket13.processRequest = function(client)
  local request = {
    payload = nil,
    payloadBD = nil,
    totalSize = 0,
  }

  while true do
    local headerBytes, err = client:receive(2)
    if not headerBytes then return nil, err, 1002 end

    local firstByte = string.byte(headerBytes, 1)
    local fin = bit.band(bit.rshift(firstByte, 7), 1)
    local opcode = bit.band(firstByte, 0x0F)

    local secondByte = string.byte(headerBytes, 2)
    local masked = bit.band(bit.rshift(secondByte, 7), 1)
    local length7 = bit.band(secondByte, 0x7F)

    if masked == 0 then
      return nil, "client sent unmasked frame", 1002
    end

    local actualLength = length7
    if length7 == 126 then
      local ext, err = client:receive(2)
      if not ext then return nil, err, 1002 end
      actualLength = love.data.unpack(">I2", ext)
    elseif length7 == 127 then
      local ext, err = client:receive(8)
      if not ext then return nil, err, 1002 end
      actualLength = love.data.unpack(">I8", ext)
    end

    if actualLength > love.mintmousse.MAX_WEBSOCKET_FRAME_SIZE then
      return nil, "payload too large", 1009
    end

    local maskingKey, err = client:receive(4)
    if not maskingKey then return nil, err, 1002 end

    local rawPayload, err = client:receive(actualLength)
    if not rawPayload then
      return nil, err == "timeout" and "timeout" or "incomplete payload", 1002
    end

    if client.sentCloseFrame and opcode ~= 0x8 then
      goto continue
    end

    if actualLength > 0 then
      local payload_PTR = ffi.cast("const uint8_t*", rawPayload)
      local payload32_PTR = ffi.cast("uint32_t*", payload_PTR)
      local masking_PTR = ffi.cast("const uint8_t*", maskingKey)
      local masking32 = love.data.unpack("I4", maskingKey)

      local count32 = bit.rshift(actualLength, 2) -- number of 4-byte chunks
      for i = 0, count32 - 1 do
        out32_PTR[i] = bit.bxor(payload32_PTR[i], masking32)
      end

      -- Read trailing non-4 byte aligned bytes
      for i = bit.lshift(count32, 2), actualLength - 1 do
        out_PTR[i] = bit.bxor(payload_PTR[i], masking_PTR[bit.band(i, 3)])
      end
    end

    if opcode >= 0x8 then
      if fin == 0 then return nil, "illegal control frame fragmentation", 1002 end
      if actualLength > 125 then return nil, "control frame payload too large", 1002 end

      local controlPayloadStr = actualLength > 0 and ffi.string(out_PTR, actualLength) or ""

      if opcode == 0x9 then -- PING
        websocket13.send(client, 0xA, controlPayloadStr)
      elseif opcode == 0xA then -- PONG
        client.lastSeen = lt.getTime()
      elseif opcode == 0x8 then
        request.type = "close"
        if #controlPayloadStr >= 2 then
          request.statusCode = love.data.unpack(">I2", controlPayloadStr:sub(1, 2))
          request.reason = controlPayloadStr:sub(3)
        else
          request.statusCode = 1005
        end
        request.payload, request.payloadBD, request.totalSize = nil, nil
        return request, nil, nil
      end

      goto continue
    end

    if actualLength > 0 then
      request.totalSize = request.totalSize + actualLength
      if request.totalSize > love.mintmousse.MAX_WEBSOCKET_MESSAGE_SIZE then
        return nil, "Total payload too large", 1009
      end

      if not request.payloadBD then
        request.payloadBD = love.data.newByteData(actualLength)
        ffi.copy(request.payloadBD:getFFIPointer(), out_PTR, actualLength)
      else
        local oldSize = request.payloadBD:getSize()
        request.payloadBD = love.data.newByteData(request.payloadBD, 0, oldSize + actualLength)
        local dest = ffi.cast("uint8_t*", request.payloadBD:getFFIPointer()) + oldSize
        ffi.copy(dest, out_PTR, actualLength)
      end
    end

    if not request.type then
      if opcode == 0x0 then return nil, "illegal continuation", 1002 end
      request.type = (opcode == 0x1) and "text/utf8" or "binary"
    elseif opcode ~= 0x0 then
      return nil, "expected continuation frame", 1002
    end

    if fin == 1 then
      if not request.payloadBD then
        request.payload = request.type == "text/utf8" and "" or love.data.newByteData(0)
      else
        request.payload = request.type == "text/utf8" and request.payloadBD:getString() or request.payloadBD
      end
      request.payloadBD = nil
      break
    end

    if coroutine.running() then
      coroutine.yield()
    else
      lt.sleep(1e-4)
    end
    ::continue::
  end

  return request, nil, 1011 -- return 1011, encase request is nil as fallback
end

websocket13.send = function(client, opcode, payload)
  if client.sentCloseFrame then
    return -- No more sends are allowed after close frame has been sent
  end
  if opcode == 0x8 then
    client.sentCloseFrame = true
  end

  local payloadLength, isData = 0, false
  if type(payload) == "string" then
    payloadLength = #payload
  elseif type(payload) == "userdata" and payload.typeOf and payload:typeOf("Data") then
    payloadLength = payload:getSize()
    isData = true
  end

  if payloadLength == 0 then
    client:send(string.char(bit.bor(0x80, opcode), 0x0))
    return
  end

  local maxChunk = love.mintmousse.MAX_WEBSOCKET_FRAME_SIZE

  for offset = 0, payloadLength - 1, maxChunk do
    local remaining = payloadLength - offset
    local chunkSize = math.min(maxChunk, remaining)

    local isLast = offset + chunkSize >= payloadLength
    local isFirst = offset == 0

    local chunk
    if isData then
      chunk = payload:getString(offset, chunkSize)
    else
      chunk = payload:sub(offset + 1, offset + chunkSize)
    end

    local firstByte = bit.bor(isLast and 0x80 or 0x00, isFirst and opcode or 0x00)
    
    local header
    if chunkSize <= 125 then
      header = string.char(firstByte, chunkSize)
    elseif chunkSize <= 65535 then
      header = string.char(firstByte, 126) .. love.data.pack("string", ">I2", chunkSize)
    else
      header = string.char(firstByte, 127) .. love.data.pack("string", ">I8", chunkSize)
    end

    client:send(header .. chunk)
  end
end

websocket13.close = function(client, statusCode, reason, isClientInitiated)
  if type(statusCode) ~= "number" then
    reason = statusCode
    statusCode = 1000
    isClientInitiated = false
  end

  if client.sentCloseFrame then
    if client.client then
      client.client:close()
      client.client = nil
    end
    return
  end

  local closePayload = nil
  if statusCode ~= 1005 then
    closePayload = love.data.pack("string", ">I2", statusCode or 1000) .. (reason or "Server Closing")
  end
  pcall(websocket13.send, client, 0x8, closePayload)

  if not isClientInitiated then
    local startTime, timeout = lt.getTime(), coroutine.running() and 3 or 1
    while lt.getTime() - startTime < timeout do
      if client:isReadable() then
        local success, response = pcall(websocket13.processRequest, client)
        if not success or not response or response.type == "close" then
          break
        end
      end
      if coroutine.running() then
        coroutine.yield()
      else
        lt.sleep(1e-4)
      end
    end
  end
  if client.client then
    client.client:close()
    client.client = nil
  end
end

return websocket13