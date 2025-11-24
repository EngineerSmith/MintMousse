local PATH = (...):match("^(.*)%.init$") or ...
PATH = PATH .. "."

local mintmousse = require(PATH .. "preload")

if love.isMintMousseThread then
  return
end

if not love.isThread then -- is Main thread
  local errorHandler = require(PATH .. "errorhandler")
  love.errorhandler = errorHandler

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

return mintmousse