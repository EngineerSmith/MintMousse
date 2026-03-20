local lt = love.timer
local socket = require("socket")

-- default protocol
local http1_1 = require(PATH .. "thread.server.protocol.http1_1")

local loggerClient = require(PATH .. "thread.server.logger"):extend("Client")

local client = { }
client.__index = client

client.new = function(socketClient, defaultConnection)
  local self = setmetatable({
    client = socketClient,
    lastSeen = lt.getTime(),
    closing = false,
    connection = defaultConnection or http1_1
  }, client)

  self.client:settimeout(0)
  self.client:setoption("keepalive", true)
  self.client:setoption("linger", { on = true, timeout = .5 })

  return self
end

client.run = function(self)
  return coroutine.create(function()
    while self.connection do
      local status = self.connection.process(self)
      if status == "close" then
        break
      end
      -- Safety yield, prevents maxing out CPU if process() returns 'keep-alive' without ever yielding
      coroutine.yield()
    end
    -- Client should already have been closed, but catch if not
    self:close("Connection terminated by protocol")
    return "close"
  end)
end

client.close = function(self, reason)
  if self.closing then return end
  self.closing = true

  if self.connection and type(self.connection.close) == "function" then
    pcall(self.connection.close, self, reason)
  elseif self.client then
    -- fallback
    self.client:close()
  end

  self.client = nil
  self.connection = nil
end

client.getpeername = function(self)
  return self.client:getpeername()
end

client.isReadable = function(self)
  local readable, _, _ = socket.select({ self.client }, nil, 0)
  return #readable > 0
end

client.receive = function(self, pattern, timeoutSeconds)
  local prefix
  local waitStart = lt.getTime()
  while true do
    if not self.client then
      return nil, "closed"
    end

    local data, errorMessage, partial = self.client:receive(pattern, prefix)
    if data then
      self.lastSeen = lt.getTime()
      return data, nil
    end

    if errorMessage == "timeout" then
      prefix = partial or prefix

      if timeoutSeconds and lt.getTime() - waitStart > timeoutSeconds then
        return nil, "timeout"
      end

      if not self.closing and self.connection and
         type(self.connection.idle) == "function" then
        local success, status = pcall(self.connection.idle, self)
        if not success or status == "close" then
          return nil, "closed"
        end
      end

      if coroutine.running() then
        coroutine.yield()
      else
        lt.sleep(1e-4)
      end
    elseif errorMessage == "closed" then
      return nil, "closed"
    else
      return nil, errorMessage
    end
  end
end

client.send = function(self, data, timeoutSeconds)
  if not self.client then
    return nil, "closed"
  end

  timeoutSeconds = timeoutSeconds or 10
  local waitStart = lt.getTime()

  local i, size = 1, #data
  while i <= size do
    local lastIndex, errorMessage, lastByteSent = self.client:send(data, i)

    if lastIndex then
      i = lastIndex + 1
      waitStart = lt.getTime()
    else
      i = (lastByteSent or i - 1) + 1
      if errorMessage == "closed" then
        return nil, "closed"
      elseif errorMessage == "timeout" then
        if lt.getTime() - waitStart > timeoutSeconds then
          return nil, "timeout"
        end

        if coroutine.running() then
          coroutine.yield()
        else
          lt.sleep(1e-4)
        end
      else
        return nil, errorMessage
      end
    end
  end
  return true
end

return client