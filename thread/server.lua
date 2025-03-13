if not love.isThread then
  love.mintmousse.warning("TCPServer: Trying to run TCPServer on main thread. There may be blocking calls!")
end

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
      local connection = { type = "http" } -- Assume all incoming connections are HTTP requests; fail them if not
      while true do
        local status
        if connection.type == "http" then
          -- process connection as HTTP until it says upgrade to websocket or close

        elseif connection.type == "websocket" then
          -- process connection as websocket until close
        end

        if status == "close" then
          break
        elseif status == "error" then
          return
        end

        coroutine.yield(true)
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