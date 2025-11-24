local PATH = (...):match("^(.-)[^%.]+$")

local le = love.event

local mintmousse = require(PATH .. "conf")
local codec = require(PATH .. "codec")

local threadCommunication = {
  commandQueue = love.thread.getChannel(mintmousse.THREAD_COMMAND_QUEUE_ID),
  eventQueue = mintmousse.THREAD_RESPONSE_QUEUE_ID,
}

threadCommunication.push = function(message)
  threadCommunication.commandQueue:push(codec.encode(message))
end

if love.isMintMousseThread then
  threadCommunication.pop = function()
    local encodedMessage = threadCommunication.commandQueue:pop()
    if not encodedMessage then
      return
    end
    return codec.decode(encodedMessage)
  end

  threadCommunication.pushEvent = function(enum, ...)
    le.push(threadCommunication.eventQueue, enum, ...)
  end
end

return threadCommunication