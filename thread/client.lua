--[[

This was added as a wrapper for ease of implementing TLS/SSL later

]]

local client = { }
client.__index = client

client.new = function(socketClient)
  local self = setmetatable({ client = socketClient }, client)

  self.client:settimeout(0)
  self.client:setoption("keepalive", true)
  self.client:setoption("linger", { true, .5 })

  return self
end

client.close = function(self)
  self.client:close()
end

client.getsockname = function(self)
  return self.client:getsockname()
end

client.receive = function(self, pattern, prefix)
  while true do
    local data, errorMessage = self.client:receive(pattern, prefix)
    if not data then
      if errorMessage == "timeout" then
        coroutine.yield(true) -- if timeout; wait
      elseif errorMessage == "closed" then
        coroutine.yield(nil)
      else
        love.mintmousse.warning("CLIENT: Receive unhandled error message! Tell a programmer:", errorMessage)
        return nil
      end
    else
      local size = #data
      if size > love.mintmousse.MAX_DATA_RECEIVE_SIZE then
        love.mintmousse.warning("CLIENT: Surpassed maxed data size force closing connection! Got:", size, ". Limit:", love.mintmousse.MAX_DATA_RECEIVE_SIZE)
        self:close()
        coroutine.yield(nil)
        return
      end
      return data
    end
  end
end

client.send = function(self, data, i, j)
  local i, size = 1, #data
  while i < size do
    local j, errorMessage, k = client:send(data, i)
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

return client