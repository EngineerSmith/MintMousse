local PATH = (...):match("^(.*)%.init$") or ...
PATH = PATH .. "."

local mintmousse = require(PATH .. "preload")

if love.isThread then
  return mintmousse
end
-- is Main thread

-- TODO; what if we're still in conf? and user has done `require("mintmousse")` inside conf.lua
-- Uhh - I need to think about it

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