if not love.isThread then
  love.mintmousse.warning("TCPServer: Trying to run TCPServer on main thread. There may be blocking calls!")
end

local http = love.mintmousse.require("thread.http")
local http1_1 = love.mintmousse.require("thread.http1_1")

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
  if not request.headerSet["update"]                or not request.headerSet["update"]["websocket"] or
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
  local accept = love.data.hash("sha1", key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
  accept = love.data.encode("string", "base64", accept)

  -- Return 101, Switching Protocols response
  return 101, {
    upgrade = "websocket",
    connection = "upgrade",
    ["sec-websocket-version"] = "13",
    ["sec-websocket-accept"] = accept,
  }, nil
end)

local server = {
  connections = { },
  whitelist = { },
}

server.start = function(host, httpPort)
  server.cleanUp()

  local errorMessage
  server.tcp, errorMessage = socket.bind(host, httpPort or 80)

  if not server.tcp then
    love.mintmousse.error("TCPServer: Could not bind to port", httpPort or 80, ". Reason:", errorMessage)
    return
  end

  server.tcp:settimeout(0)
  server.tcp:setoption("keepalive", true)
  server.tcp:setoption("linger", { false, 0 })

  local _, port = server.tcp:getsockname()
  if port then
    love.mintmousse.info("TCPServer: Started on port:", port)
  else
    love.mintmousse.info("TCPServer: Started.")
  end
end

server.cleanUp = function()
  if server.tcp then
    server.tcp:close()
    server.tcp = nil
  end
end

server.newIncomingConnection = function()
  local rawClient, errorMessage = server.tcp:accept()
  if rawClient then
    local address = client:getsockname()
    if not http.isWhitelisted(address) then
      rawClient:close()
      love.mintmousse.info("TCPServer: Non-whitelisted connection attempt from:", address)
      return
    end

    local client = love.mintmousse.require("thread.client").new(rawClient)

    server.connections[coroutine.wrap(function()
      local connection = {
        type = "undetermined"
      }
      connection.initialRaw = client:receive(16)
      if connection.initialRaw == "PRI * HTTP/2.0\r\n" then
        connection.type = "HTTP/2"
      else
        connection.type = "HTTP/1.1"
      end
      while true do
        local status

        if connection.type == "HTTP/1.1" then
          local request = http1_1.parseRequest(client, connection.initialRaw)
          connection.initialRaw = nil
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
                connection.type = "WS/"..headers["sec-websocket-version"]
              else
                love.mintmousse.error("TCPServer: HTTP 101 returned unexpected upgrade")
              end
            end
          end
        elseif connection.type == "HTTP/2" then
          connection.initialRaw = nil
          -- HTTP/2 not yet supported; close connection and request HTTP/1.1
          http1_1.respond(client, 426, nil, { upgrade = "HTTP/1.1", connection = "upgrade, close" })
          status = "close"
          love.mintmousse.info("TCPServer: Client [", address, "] using HTTP/2 has been requested to upgrade to HTTP/1.1")
        elseif connection.type == "WS/13" then
          -- TODO
          -- process connection as websocket until close
        end

        coroutine.yield(true)

        if status == "close" then
          break
        elseif status == "error" then
          return
        end

        while true do
          if client:dirty() then
            break
          end
          love.timer.sleep(0.00005)
          coroutine.yield(true)
        end
      end
      client:close()
    end)]

  elseif errorMessage ~= "timeout" and errorMessage ~= "closed" then
    love.mintmousse.warning("TCPServer: Error occurred while accepting a connection:", errorMessage)
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