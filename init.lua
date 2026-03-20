local PATH_RAW = ...
local PATH = PATH_RAW:match("^(.*)%.init$") or ...
PATH = PATH .. "."

local attemptError = function(errorMessage)
  error(errorMessage, 3)
  assert(false, errorMessage) -- if error was overridden, try to use assert
  return errorMessage -- fallback, try to return the error
end

if PATH_RAW:find("[[/\\]") then
  local errorMessage = "MintMousse: You called require('%s'). "..
                       "Invalid path format, please use dot-notion (e.g. libs.mintmousse) instead of file paths. " ..
                       "Use `.` (periods) in place of `/` (forward slash) or `\\` (back slash). "
  return attemptError(errorMessage:format(PATH_RAW))
end

require(PATH .. "setupLove")
if not love.isThread and not love.handlers then
  -- is Main thread; Inside conf.lua
  local errorMessage = "MintMousse: You called require('%s') inside of conf.lua. " ..
                       "The library requires that you use require('%s') in conf.lua, " ..
                       "and use require('%s') in main.lua or later. "
  return attemptError(errorMessage:format(PATH_RAW, PATH .. "preload", PATH_RAW))
end
PATH_RAW = nil

-- Run preload if it hasn't been ran yet, or just grab the result
local mintmousse = require(PATH .. "preload")

if love.isThread then
  return mintmousse
end
-- is Main thread

-- These love values can't be changed in conf; so we have to delay their addition until we get to main
if mintmousse.REPLACE_DEFAULT_ERROR_HANDLER then
  local errorHandler = require(PATH .. "errorhandler")
  love.errorhandler = errorHandler
end

local eventManager = require(PATH .. "eventManager")
love.handlers[mintmousse.THREAD_RESPONSE_QUEUE_ID] = function(enum, ...)
  if enum == "MintMousseJSEvent" then
    eventManager.jsEvent(...)
  else
    mintmousse._logger:warning("Unhandled MintMousse event!", enum)
  end
end

mintmousse._logger:info("Successfully loaded MintMousse")

return mintmousse