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

-- Check if there is something in the client buffer; this method is used because client:dirty does not work
client.peek = function(self, length)
  local peeking = self.client:receive(length or 1)
  if not peeking then
    return false
  end

  self.buffer = (self.buffer or "") .. peeking

  return true
end

client.receive = function(self, pattern, prefix)
  -- todo; max number of tries? Timer?
  if prefix or self.buffer then
    prefix = (prefix or "")..(self.buffer.."")
    self.buffer = nil
  end
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
        if coroutine.running() then
          coroutine.yield(nil)
        end
        return
      else
        print("TODO HIT ERROR:", errorMessage)
      end
      i = k + 1
    else
      i = i + j
    end
    if coroutine.running() then
      coroutine.yield(true)
    end
  end
end

-- TCPSocket:dirty is broken and doesn't work. Use receive directly; and add it back as a prefix.
--    Tip: the prefix length is included in the size check no need to alter the size you want by the length of the prefix
-- client.isBufferEmpty = function(self)
--   return not self.client:dirty()
-- end

return client