local PATH_RAW = ...
local PATH = (...):match("^(.*)%.init$") or ...
PATH = PATH .. "."

require(PATH .. "setupLove")
if not love.isThread and not love.handlers then
  -- is Main thread; Inside conf.lua
  local errorMessage = "MintMousse: You called require('%s') inside of conf.lua. " ..
                       "The library requires that you use require('%s') in conf.lua, " ..
                       "and require('%s') in main.lua or later."
  local errMsg = errorMessage:format(PATH_RAW, PATH .. "preload", PATH_RAW)
  error(errMsg, 2)
  assert(false, errMsg) -- if error was overridden, try to use assert
  return errMsg -- if all else fails, try to return the error
end
PATH_RAW = nil

local mintmousse = require(PATH .. "preload")

if love.isThread then
  return mintmousse
end
-- is Main thread

-- These love values can't be changed in conf; so we have to delay their addition until we get to main
local errorHandler = require(PATH .. "errorhandler")
love.errorhandler = errorHandler

local eventManager = require(PATH .. "eventManager")
love.handlers[mintmousse.THREAD_RESPONSE_QUEUE_ID] = function(enum, ...)
  if enum == mintmousse.EVENT_ENUM_JS_EVENT then
    eventManager.jsEvent(...)
  else
    mintmousse._logger:warning("Unhandled MintMousse event!", enum)
  end
end

return mintmousse