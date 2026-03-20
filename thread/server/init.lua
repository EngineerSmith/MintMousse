local lt = love.timer
local socket = require("socket")

local whitelist = require(PATH .. "thread.server.whitelist")
local clientWrapper = require(PATH .. "thread.server.client")

local loggerServer = require(PATH .. "thread.server.logger")

local server = {
  clients = { },
}

server.start = function(host, port, autoIncrement)
  if server.isRunning() then
    server.cleanUp()
  end

  local currentPort = port or 8080
  local shouldIncrement = port == nil or autoIncrement
  local attempts = 0

  local tcp, errorMessage
  while attempts < love.mintmousse.MAX_PORT_ATTEMPTS do
    if host then
      tcp, errorMessage = socket.bind(host, currentPort, love.mintmousse.SOCKET_BACKLOG)
    else
      local s = socket.tcp()
      pcall(s.setoption, "reuseaddr", true)
      pcall(s.setoption, "ipv6-v6only", false)

      local bindOk, bindErr = s:bind("::", currentPort)
      if bindOk == 1 then
        local listenOk, listenErr = s:listen(love.mintmousse.SOCKET_BACKLOG)
        if listenOk == 1 then
          tcp = s
        else
          s:close()
          loggerServer:info("IPv6 bind succeeded but listen failed (" .. (listenErr or "unknown") .. "), falling back to IPv4")
          tcp, errorMessage = socket.bind("*", currentPort, love.mintmousse.SOCKET_BACKLOG)
        end
      else
        s:close()
        tcp, errorMessage = socket.bind("*", currentPort, love.mintmousse.SOCKET_BACKLOG)
        if tcp then
          loggerServer:info("IPv6 bind fail (" .. (bindErr or "unknown") .. "), fell back to IPv4")
        end
      end
    end

    if tcp then
      server.tcp = tcp
      break
    end

    if not shouldIncrement then
      loggerServer:error("Could not bind to port", currentPort, ". Reason:", errorMessage)
      return
    end

    if (attempts + 1) < love.mintmousse.MAX_PORT_ATTEMPTS then
      loggerServer:info("Port", currentPort, "busy, trying next...")
      currentPort = currentPort + 1
    end
    attempts = attempts + 1
  end

  if not server.tcp then
    loggerServer:error("Failed to bind after", attempts, "attempts.")
    return
  end

  server.tcp:settimeout(0)
  server.tcp:setoption("keepalive", true)
  server.tcp:setoption("linger", { on = false, timeout = 0 })

  local localAddress, actualPort, family = server.tcp:getsockname()
  family = family or "unknown"
  localAddress = localAddress or (host or "*")

  if family == "inet6" and (localAddress == "::" or localAddress == "::0") then
    loggerServer:info("Started on port", actualPort, "(dual-stack IPv6 + IPv4-mapped)")
  elseif family == "inet" then
    loggerServer:info("Started on port", actualPort, "(IPv4 only)")
  else
    loggerServer:info("Started on port:", actualPort, "family:", family, "address:", localAddress)
  end

  -- TODO report back to all threads, so they can programmatically grab using a getter
  server.port = actualPort
  server.family = family
  server.localAddress = localAddress
end

server.isRunning = function()
  return server.tcp ~= nil
end

server.cleanUp = function()
  loggerServer:info("Server shutting down. Closing all connections...")

  if server.tcp then
    pcall(server.tcp.close, server.tcp)
    server.tcp = nil
  end

  local closingRoutines = { }
  for client in pairs(server.clients) do
    local co = coroutine.create(function()
      client:close("Server Shutdown")
    end)
    table.insert(closingRoutines, co)
  end

  local start = lt.getTime()
  while lt.getTime() - start < 3.5 do
    local active = 0
    for _, co in ipairs(closingRoutines) do
      if coroutine.status(co) ~= "dead" then
        active = active + 1
        local success, err = coroutine.resume(co)
        if not success then
          loggerServer:warning("Error during client cleanup:", err)
        end
      end
    end
    if active == 0 then
      break
    end
    love.timer.sleep(1e-4)
  end

  for client in pairs(server.clients) do
    if client.client then
      pcall(client.client.close, client.client)
      client.client = nil
    end
  end

  server.clients = { }
  server.port = nil

  loggerServer:info("Shutdown complete.")
end

server.update = function()
  if not server.isRunning() then
    return
  end
  server.newIncomingConnection()
  server.updateConnections()
end

server.newIncomingConnection = function()
  local rawClient, errorMessage = server.tcp:accept()
  if not rawClient then
    if errorMessage ~= "timeout" and errorMessage ~= "closed" then
      loggerServer:info("Error occurred while accepting a connection:", errorMessage)
    end
    return
  end

  local address, _, family = rawClient:getpeername()
  if not address or (family ~= "inet" and family ~= "inet6") then
    pcall(rawClient.close, rawClient)
    loggerServer:info("Accepted connection with invalid peername (closed immediately)")
    return
  end

  if not whitelist.check(address, family) then
    rawClient:close()
    loggerServer:info("Non-whitelisted connection attempt from:", address)
    return
  end

  local client = clientWrapper.new(rawClient)
  local co = client:run()
  server.clients[client] = co
end

server.updateConnections = function()
  for client, co in pairs(server.clients) do
    if coroutine.status(co) == "dead" then
      server.clients[client] = nil
    else
      local success, status = coroutine.resume(co)
      if not success then
        loggerServer:warning("Coroutine crashed:", status)
        server.clients[client] = nil
        if client.client then
          client.client:close()
          client.client = nil
        end
      elseif status == "close" then
        server.clients[client] = nil
      end
    end
  end
end

return server