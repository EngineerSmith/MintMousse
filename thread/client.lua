local ROOT = (...):match("^(.-)[^%.]+%.[^%.]+$") or ""

local mintmousse = require(ROOT .. "mintmousse")

local loggerClient = mintmousse._logger:extend("Client")

-- Wrapper for LuaSocket TCPsocket
local client = { }
client.__index = client

client.new = function(socketClient)
  local self = setmetatable({
    client = socketClient,
    connection = {
      type = "undetermined",
    },
    queue = { },
  }, client)

  self.client:settimeout(0)
  self.client:setoption("keepalive", true)
  self.client:setoption("linger", { on = true, timeout = .5 })

  return self
end

client.close = function(self)
  self.client:close()
end

client.getsockname = function(self)
  return self.client:getsockname()
end

client.peek = function(self, length)
  length = length or 1
  local currentBufferLen = #(self.buffer or "")
  if currentBufferLen >= needed then
    return true
  end

  local missing = needed - currentBufferLen
  local data, err = self.client:receive(missing)
  if data then
    self.buffer = (self.buffer or "") .. data
    return true
  end
  return false
end

client.hasData = function(self)
  local data, errorMessage = self.client:receive(1)

  if data then
    self.buffer = (self.buffer or "") .. data
    return true
  elseif errorMessage == "timeout" then
    return false
  else
    loggerClient:warning("Unhandled error message during hasData check:", errorMessage)
    return false
  end
end

client.receive = function(self, pattern)
  if self.buffer and #self.buffer > 0 then
    if type(pattern) == "number" and #self.buffer >= pattern then
      local data = self.buffer:sub(1, pattern)
      self.buffer = self.buffer:sub(pattern + 1)
      return data
    end
  end

  while true do
    local data, errorMessage = self.client:receive(pattern)
    if data then
      return data
    end

    if errorMessage == "timeout" then
      coroutine.yield(true) -- if timeout; wait
    elseif errorMessage == "closed" then
      coroutine.yield(nil) -- if closed; finish coroutine
    else
      -- Handle unexpected errors
      loggerClient:warning("Unhandled error message during receive:", errorMessage)
      return nil
    end
  end
end

client.send = function(self, data)
  local i, size = 1, #data
  while i <= size do
    local sentCount, errorMessage, indexUnsent = self.client:send(data, i)
    if sentCount then
      i = i + sentCount
    else
      if errorMessage == "closed" then
        if coroutine.running() then
          coroutine.yield(nil)
        end
        return
      elseif errorMessage ~= "timeout" then
        loggerClient:warning("Unhandled error during send:", errorMessage)
        return
      end
    end
    coroutine.yield(true)
  end

  return true
end

return client