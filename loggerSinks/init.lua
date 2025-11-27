local PATH = ...
PATH = PATH:match("^(.*)%.init$") or PATH
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local logging = require(ROOT .. "logging")

if mintmousse.LOG_ENABLE_CONSOLE_OUT then
  logging.addLogSink(require(PATH .. "console"))
end