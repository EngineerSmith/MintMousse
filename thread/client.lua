--[[

This was added as a wrapper for ease of implementing TLS/SSL later

]]

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

client.receive = function(self, pattern, prefix)
  -- todo; max number of tries? Timer?
  while true do
    local data, errorMessage = self.client:receive(pattern, prefix)
    if not data then
      if errorMessage == "timeout" then
        coroutine.yield(true) -- if timeout; wait
      elseif errorMessage == "closed" then
        coroutine.yield(nil)
      else
        -- documentation only mentions "timeout" and "closed" events, but we can never be sure
        love.mintmousse.warning("CLIENT: Receive unhandled error message! Tell a programmer:", errorMessage)
        return nil
      end
    else
      return data
    end
  end
end

client.send = function(self, data, i, j)
  local i, size = 1, #data
  while i < size do
    local j, errorMessage, k = self.client:send(data, i)
    if not j then
      if errorMessage == "closed" then
        coroutine.yield(nil)
      end
      i = k + 1
    else
      i = i + j
    end
    coroutine.yield(true)
  end
end

client.isBufferEmpty = function(self)
  return not self.client:dirty()
end

return client