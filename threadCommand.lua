local PATH = (...):match("^(.-)[^%.]+$")

local le = love.event

local mintmousse = require(PATH .. "conf")
local codec = require(PATH .. "codec")

local loggerCommand = mintmousse._logger:extend("Command")

local threadCommand = {
  commandQueue = love.thread.getChannel(mintmousse.THREAD_COMMAND_QUEUE_ID),
  eventQueue = mintmousse.THREAD_RESPONSE_QUEUE_ID,
}

threadCommand.batchStart = function()
  if threadCommand._batch then
    loggerCommand:warning("batchStart called while a batch is already active. Ignoring nested call.")
  else
    threadCommand._batch = { }
  end
end

threadCommand.batchEnd = function()
  if not threadCommand._batch then
    loggerCommand:warning("batchEnd called without a matching batchStart. No batch to close.")
    return
  end

  local batch = threadCommand._batch
  threadCommand._batch = nil
  if #batch ~= 0 then
    threadCommand.call("batch", batch)
  end
end

threadCommand.push = function(message)
  if threadCommand._batch then
    table.insert(threadCommand._batch, message)
    return
  end
  threadCommand.commandQueue:push(codec.encode(message))
end

threadCommand.call = function(func, args)
  threadCommand.push({ func = func, args = args })
end

if isMintMousseThread then
  threadCommand.pop = function()
    local encodedMessage = threadCommand.commandQueue:pop()
    if not encodedMessage then
      return
    end
    return codec.decode(encodedMessage)
  end

  threadCommand.pushEvent = function(enum, ...)
    le.push(threadCommand.eventQueue, enum, ...)
  end
end

return threadCommand