local PATH = (...):match("^(.*)init$") or ...
local ROOT = PATH:match("^(.-)thread%.server%.$")
PATH = PATH .. "."

local socket = require("socket")

local whitelist = require(PATH .. "whitelist")
local connection = require(PATH .. "connection")

local mintmousse = require(ROOT .. "conf")

local clientWrapper = require(ROOT .. "thread.client")

local loggerServer = mintmousse._logger:extend("Server")

local server = {
  clients = { },
  connections = { },
}

server.start = function(host, httpPort)
  server.cleanUp()

  local errorMessage
  server.tcp, errorMessage = socket.bind(host or "*", httpPort or 80)

  if not server.tcp then
    loggerServer:error("Could not bind to port", httpPort or 80, ". Reason:", errorMessage)
    return
  end

  server.tcp:settimeout(0)
  server.tcp:setoption("keepalive", true)
  server.tcp:setoption("linger", { on = false, timeout = 0 })

  local _, port = server.tcp:getsockname()
  if port then
    loggerServer:info("Started on port:", port)
  else
    loggerServer:info("TCPServer: Started.")
  end
end

server.isRunning = function()
  return server.tcp ~= nil
end

server.cleanUp = function()
  for client in pairs(server.clients) do
    if client.connection.type == "WS/13" then
      websocket13.closeConnection(client, "Server shutdown")
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
    if not whitelist.check(address) then
      rawClient:close()
      loggerServer:info("Non-whitelisted connection attempt from:", address)
      return
    end

    local client = clientWrapper.new(rawClient) -- not in file scope because "client" is a variable that can easily get mixed up between "class" and table
    server.clients[client] = true

    server.connections[connection.run(client, server.handleIncomingEvent)] = true
  elseif errorMessage ~= "timeout" and errorMessage ~= "closed" then
    loggerServer:info("Error occurred while accepting a connection:", errorMessage)
  end
end

server.updateConnections = function()
  for connection in pairs(server.connections) do
    if connection() == nil then
      server.connections[connection] = nil
    end
  end
end

return server