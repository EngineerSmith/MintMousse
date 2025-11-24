local PATH = (...):match("^(.*)%.init$") or ...
PATH = PATH .. "."

local mintmousse = require(PATH .. "preload")

if love.isMintMousseThread then
  return
end

if not love.isThread then -- is Main thread
  local eventManager = require(PATH .. "eventManager")

  -- love.handlers doesn't exist until main.lua; have to setup late
  love.handlers[mintmousse.THREAD_RESPONSE_QUEUE_ID] = function(enum, ...)
    if enum == mintmousse.EVENT_ENUM_JS_EVENT then
      eventManager.jsEvent(...)
    else
      mintmousse._logger:warning("Unhandled MintMousse event!", enum)
    end
  end
end

-- TODO move to preload.lua; add setting for "full load", or "partial"; partial is how the code below does it
-- should we just force "full load"? It would be slower load times; but less overhead per function

-- Wait for component types to be parsed: this can be a quick operation, but it is blocking
local start = love.timer.getTime()
local timeoutValue = love.mintmousse.COMPONENT_PARSE_TIMEOUT
repeat
  love.mintmousse._checkTypeCompleteness()

  local success = love.mintmousse._componentTypes ~= nil
  local timedOut = love.timer.getTime() - start >= timeoutValue

  if not success and not timedOut then
    love.timer.sleep(0.0005) -- 0.5 ms
  end
until success or timedOut

-- If timeout is reached
if love.mintmousse._componentTypes == nil then
  local logger = love.mintmousse._logger
  logger:warning(
    "Timeout reached ("..timeoutValue.."s) while waiting for MintMousse thread to parse components.",
    "Attempting to check for thread error."
  )

  local channel = love.thread.getChannel(love.mintmousse.READONLY_THREAD_LOCATION)
  local thread = channel:peek()
  if not thread then
    logger:warning("MintMousse Thread channel was empty after timeout.",
      "Thread may have not properly initialized. Check preload.lua.")
    return
  end
  local errorMessage = thread:getError()
  if errorMessage then
    local success = false
    if type(love.handlers) == "table" and love.handlers["threaderror"] then
      pcall(love.handlers["threaderror"], thread, errorMessage)
    end
    logger:error(errorMessage) -- ensure we log the error even if `threaderror` was successfully called
  else
    logger:warning("The thread object reported no error.",
      "This suggests the MintMousse Thread is stuck or overloaded.",
      "Consider increasing the timeout ("..timeoutValue.."s).")
  end
  return
end