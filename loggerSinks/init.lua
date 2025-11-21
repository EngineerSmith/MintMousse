local PATH = ...
PATH = PATH:match("^(.*)%.init$") or PATH
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local logging = require(ROOT .. "logging")
local ANSI = require(ROOT .. "logging.ANSI")

local consoleSink
if ANSI.isANSISupported then
  consoleSink = require(PATH .. "ANSIConsole")
else
  consoleSink = require(PATH .. "console")
end

logging.addLogSink(consoleSink)