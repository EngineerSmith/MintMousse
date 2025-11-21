local PATH = ...
PATH = PATH:match("^(.*)%.init$") or PATH
local ROOT = PATH:match("^(.-)[^%.]+$")
PATH = PATH .. "."

local ANSI = require(ROOT .. "logger.ANSI")

local consoleSink
if ANSI.isANSISupported then
  consoleSink = require(PATH .. "ANSIConsole")
else
  consoleSink = require(PATH .. "console")
end

love.mintmousse.addLogSink(consoleSink)