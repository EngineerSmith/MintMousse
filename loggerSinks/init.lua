local PATH = ...
PATH = PATH:match("^(.*)%.init$") or PATH
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local mintmousse = require(ROOT .. "conf")
local logging = require(ROOT .. "logging")

if mintmousse.LOG_ENABLE_STREAM_OUT then
  logging.addLogSink(require(PATH .. "streamOut"))
end