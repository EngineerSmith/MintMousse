local json = require(PATH .. "libs.json")

local controller = require(PATH .. "thread.controller")
local store = require(PATH .. "thread.store")
local http = require(PATH .. "thread.server.protocol.http")
local websocket = require(PATH .. "thread.server.protocol.websocket13")

local loggerRoutes = require(PATH .. "thread.server.logger"):extend("Routes")

http.addMethod("GET", "/index", function(request, _)
  return 200, {
    ["cache-control"] = love.mintmousse.CACHE_CONTROL_HEADER,
    ["content-type"] = "text/html; charset=utf8",
  }, store.getHTML()
end)

http.addMethod("GET", "/index.js", function(request, _)
  return 200, {
    ["cache-control"] = love.mintmousse.CACHE_CONTROL_HEADER,
    ["content-type"] = "text/javascript; charset=utf8",
  }, store.getJavascript()
end)

http.addMethod("GET", "/index.css", function(request, _)
  return 200, {
    ["cache-control"] = love.mintmousse.CACHE_CONTROL_HEADER,
    ["content-type"] = "text/css; charset=utf8",
  }, store.getCSS()
end)

http.addMethod("GET", "/api/ping", function(request, _)
  return 204, {
    ["cache-control"] = "no-store"
  }, nil
end)

http.addMethod("GET", "/live-updates", function(request, client)
  if not request.headerSet["upgrade"]               or not request.headerSet["upgrade"]["websocket"] or
      not request.headerSet["connection"]            or not request.headerSet["connection"]["upgrade"] or
      not request.headerSet["sec-websocket-version"] or not request.headerSet["sec-websocket-version"]["13"] then
      return 426, {
        ["upgrade"] = "websocket",
        ["connection"] = "upgrade",
        ["sec-websocket-version"] = "13"
      }, nil
  end

  if not request.headers["sec-websocket-key"] then
    return 400, { ["content-type"] = "text/plain" }, "Missing Sec-WebSocket-Key header"
  end

  local key = request.headers["sec-websocket-key"][1]
  if not websocket.validateWebSocketKey(key) then
    return 400, { ["content-type"] = "text/plain" }, "Invalid Sec-WebSocket-Key"
  end

  local acceptKey = websocket.getWebSocketAcceptKey(key)

  client.connection = websocket
  websocket.emit("newConnection", client)

  return 101, {
    ["Sec-WebSocket-Accept"] = acceptKey,
    ["sec-websocket-version"] = "13",
    ["connection"] = "upgrade",
    ["upgrade"] = "websocket",

  }, nil
end)

local queue = function(client, message)
  table.insert(client.outgoing, message)
end

websocket.on("newConnection", function(client)
  client.outgoing = { }
  client.queue = queue

  client:queue({
    action = "limits",
    maxFrameSize = love.mintmousse.MAX_WEBSOCKET_FRAME_SIZE,
    maxMessageSize = love.mintmousse.MAX_WEBSOCKET_MESSAGE_SIZE,
  })

  store.sendInitialPayload(client)
end)

websocket.on("message", function(client, request)
  if request.type ~= "text/utf8" and request.type ~= "application/json" then
    return
  end

  local success, payload = pcall(json.decode, request.payload)
  if not success then
    return
  end

  store.incomingEvent(client, payload)
end)