if not love.isThread then
  love.mintmousse.warning("TCPServer: Trying to run TCPServer on main thread. There may be blocking calls!")
end

local socket = require("socket")
local http = love.mintmousse.require("thread.http")
local http1_1 = love.mintmousse.require("thread.http1_1")

local websocket13 = love.mintmousse.require("thread.websocket13")

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
  if not request.headerSet["upgrade"]                or not request.headerSet["upgrade"]["websocket"] or
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
  local accept = love.data.hash("data", "sha1", keyBD)
  accept = love.data.encode("string", "base64", accept)

  -- Return 101, Switching Protocols response
  return 101, {
    ["Sec-WebSocket-Accept"] = accept,
    ["sec-websocket-version"] = "13",
    ["connection"] = "upgrade",
    ["upgrade"] = "websocket",
  }, nil
end)

local server = {
  clients = { },
  connections = { },
  whitelist = { },
}

server.start = function(host, httpPort)
  server.cleanUp()

  local errorMessage
  server.tcp, errorMessage = socket.bind(host or "*", httpPort or 80)

  if not server.tcp then
    love.mintmousse.error("TCPServer: Could not bind to port", httpPort or 80, ". Reason:", errorMessage)
    return
  end

  server.tcp:settimeout(0)
  server.tcp:setoption("keepalive", true)
  server.tcp:setoption("linger", { on = false, timeout = 0 })

  local _, port = server.tcp:getsockname()
  if port then
    love.mintmousse.info("TCPServer: Started on port:", port)
  else
    love.mintmousse.info("TCPServer: Started.")
  end
end

server.isRunning = function()
  return server.tcp ~= nil
end

server.cleanUp = function()
  for client in pairs(server.clients) do
    if client.connection.type == "WS/13" then
      websocket13.closeConnection(client, "Server shutdown", false)
    else
      client:close()
    end
  end
  server.clients = { }
  if server.tcp then
    server.tcp:close()
    server.tcp = nil
  end
end

server.newIncomingConnection = function()
  local rawClient, errorMessage = server.tcp:accept()
  if rawClient then
    local address = rawClient:getsockname()
    if not server.isWhitelisted(address) then
      rawClient:close()
      love.mintmousse.info("TCPServer: Non-whitelisted connection attempt from:", address)
      return
    end

    local client = love.mintmousse.require("thread.client").new(rawClient)
    server.clients[client] = true

    server.connections[coroutine.wrap(function()
      client.connection.initialRaw = client:receive(14)
      if client.connection.initialRaw == "PRI * HTTP/2.0" then
        client.connection.type = "HTTP/2"
      else
        client.connection.type = "HTTP/1.1"
      end
      while true do
        local status

        if client.connection.type == "HTTP/1.1" then
          local request = http1_1.parseRequest(client, client.connection.initialRaw)
          client.connection.initialRaw = nil
          if type(request) ~= "table" then
            status = request
          else
            local code, headers, content = http.processRequest(request)
            http1_1.respond(client, code, request.parsedURI.path, headers, content)
            if headers and headers["connection"] and headers["connection"]:match("close") then
              status = "close"
            end
            if code == 101 then
              if headers["upgrade"] == "websocket" then
                client.connection.type = "WS/"..headers["sec-websocket-version"]
                if client.connection.type == "WS/13" then
                  websocket13.newConnection(client)
                else
                  love.mintmousse.warning("TCPServer: Unknown websocket version:",  client.connection.type)
                end
              else
                love.mintmousse.warning("TCPServer: HTTP 101 returned unexpected upgrade; tell a programmer to add connection type. Upgrade:", tostring(headers["upgrade"]))
              end
            end
          end
        elseif client.connection.type == "HTTP/2" then
          client.connection.initialRaw = nil
          -- HTTP/2 not yet supported; close connection and request HTTP/1.1
          http1_1.respond(client, 426, nil, { upgrade = "HTTP/1.1", connection = "upgrade, close" })
          status = "close"
          love.mintmousse.info("TCPServer: Client [", address, "] using HTTP/2 has been requested to upgrade to HTTP/1.1")
        elseif client.connection.type == "WS/13" then
          if not client:isBufferEmpty() then
            local request, errorMessage = websocket13.processRequest(client)
            if not request then
              love.mintmousse.warning("TCPServer: WebSocket encountered an error:", errorMessage)
              websocket13.close(client)
              status = "close"
            else
              if request.type == "close" then
                websocket13.close(client)
                status = "close"
              elseif request.type == "text/utf8" or request.type == "binary" then
                -- process request
                love.mintmousse.warning("TCPServer: TODO WebSocket Response:", request.type, ". Payload length:", #request.payload)

              else
                status = websocket13.handleRequest(client, request)
              end
            end
          end
          for _ = 0, 5 do
            local payload = client.queue[1]
            if not payload then
              break
            end
            local opcode = payload.type == "binary" and 0x2 or 0x1
            websocket13.send(client, opcode, payload.payload)
            table.remove(client.queue, 1)
          end
        end

        coroutine.yield(true)

        if status == "close" then
          break
        end
      end
      client:close()
    end)] = true

  elseif errorMessage ~= "timeout" and errorMessage ~= "closed" then
    love.mintmousse.info("TCPServer: Error occurred while accepting a connection:", errorMessage)
  end
end

server.updateConnections = function()
  for connection in pairs(server.connections) do
    if connection() == nil then
      server.connections[connection] = nil
    end
  end
end

local whitelistPattern = function(c)
  if c == "." then
    return "%." -- "127.0.0.1" -> "127%.0%.0%.0"
  elseif c == "*" then
    return "%d+" -- > "192.168.*.*" - > "192.168.%d+.%d+"
  end
  return c
end

server.addToWhitelist = function(address)
  table.insert(server.whitelist, "^" .. address:gsub("[%.%*]", whitelistPattern) .. "$")
end

server.isWhitelisted = function(address)
  for _, allowedAddress in ipairs(server.whitelist) do
    if address:match(allowedAddress) then
      return true
    end
  end
  return false
end

return server