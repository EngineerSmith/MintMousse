local ANSI = love.mintmousse._require("logger.ANSI")

local consoleSink
if ANSI.isANSISupported then
  consoleSink = love.mintmousse._require("logger.sinks.ANSIConsole")
else
  consoleSink = love.mintmousse._require("logger.sinks.console")
end

love.mintmousse.addLogSink(consoleSink)