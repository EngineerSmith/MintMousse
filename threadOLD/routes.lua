local PATH = (...):match("^(.*)routes$")

local http = require(PATH .. "http")
local http1_1 = require(PATH .. "http1_1")

-- We only support HTTP/1.1 for now
local upgradeValue = "HTTP/1.1" --"HTTP/1.1, HTTP/2"
http1_1.upgradeValue = upgradeValue

local function validateWebSocketKey(key)
  if type(key) ~= "string" or not key:match("^[%u%l%d+/]+=*$") then
    return false
  end

  local success, decodedKey = pcall(love.data.decode, "string", "base64", key)
  return success and #decodedKey == 16
end

http.addMethod("GET", "/live-updates", function(request)
  -- Check for websocket upgrade headers
  if not request.headerSet["upgrade"]               or not request.headerSet["upgrade"]["websocket"] or
     not request.headerSet["connection"]            or not request.headerSet["connection"]["upgrade"] or
     not request.headerSet["sec-websocket-version"] or not request.headerSet["sec-websocket-version"]["13"] then
      return 426, { ["upgrade"] = "websocket", ["connection"] = "upgrade", ["sec-websocket-version"] = "13" }, nil
  end

  -- Check for sec-websocket-key header
  if not request.headers["sec-websocket-key"] then
    return 400, { ["content-type"] = "text/plain" }, "Missing Sec-WebSocket-Key header"
  end

  -- Validate Key
  local key = request.headers["sec-websocket-key"][1]
  if not validateWebSocketKey(key) then
    return 400, { ["content-type"] = "text/plain" }, "Invalid Sec-WebSocket-Key"
  end

  -- Calculate sec-websocket-accept
  local keyBD = love.data.newByteData(key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
  local accept
  if love._version_major >= 12 then
    accept = love.data.hash("data", "sha1", keyBD)
  else
    accept = love.data.hash("sha1", keyBD)
  end
  accept = love.data.encode("string", "base64", accept)

  -- Return 101, Switching Protocols response
  return 101, {
    ["Sec-WebSocket-Accept"] = accept,
    ["sec-websocket-version"] = "13",
    ["connection"] = "upgrade",
    ["upgrade"] = "websocket",
  }, nil
end)

http.addMethod("GET", "/api/ping", function(request)
  return 204, {
    ["cache-control"] = "no-store",
  }, nil
end)