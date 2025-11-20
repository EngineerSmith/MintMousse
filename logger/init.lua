-- Creates global which points to the default print function; to ensure we aren't
-- being destructive if config `REPLACE_FUNC_PRINT` is active
GLOBAL_print = print

-- Internal usage
love.mintmousse._logging = {
  _sinks = { },
}

---- Util functions

local socket = require("socket")
local getTime = socket.gettime

-- Used to dynamically change the depth required to find the stack trace information (caller file/line).
local stackFrameOffset = 0

--- Increases the stack frame offset.
-- Must be called before making an internal logging call from a wrapper function
-- to ensure the stack trace points to the original user/caller code.
love.mintmousse._stackFramePush = function()
  stackFrameOffset = stackFrameOffset + 1
end

--- Decreases the stack frame offset.
-- Must be called immediately after the logging operation completes to reset the depth.
love.mintmousse._stackFramePop = function()
  stackFrameOffset = stackFrameOffset - 1
end

local getDebugInfo = function()
  love.mintmousse._stackFramePush()
  local debugInfo
  local info = debug.getinfo(1 + stackFrameOffset, "nSl")
  if info then
    if not info.name and info.what == "C" then
      info.name = "CFunc" -- if C function is anonymous
    elseif info.what == "main" then
      info.name = nil -- file/chunk scope
    end

    if info.short_src then
      debugInfo = (info.name and info.name .. "@" or "") .. info.short_src .. (info.currentline and "#" .. info.currentline or "")
    else
      debugInfo = info.name or "UNKNOWN"
    end
  end
  love.mintmousse._stackFramePop()
  return debugInfo
end

---- Sinks

local dispatchToSinks = function(...)
  love.mintmousse._stackFramePush()
  for _, sink in ipairs(love.mintmousse._logging._sinks) do
    sink(...)
  end
  love.mintmousse._stackFramePop()
end

-- Add a new logging sink function to receive all log messages.
--
-- A sink function is called each time a log event occurs with the following arguments:
-- (1) level (string): The log level: "info", "warning", "error", "fatal", "debug"
-- (2) logger (table/nil): The logger instance that initiated the log.
-- (3) time (number): The precise unix timestamp of the event: `socket.gettime()`, offering better than second precision
-- (4) debugInfo (string/nil): Trace information, formatted as `[func@file#line]`
-- (5) ... (vararg): The log message parts. (strings, numbers)
love.mintmousse.addLogSink = function(sink)
  assert(type(sink) == "function", "Expected sink type to be function.")
  table.insert(love.mintmousse._logging._sinks, sink)
end

love.mintmousse.formatTimestamp = function(time)
  local seconds = math.floor(time)
  local milliseconds = math.floor((time - seconds)*1000)
  -- todo optimise; calculate timestamp format once; aim to remove the gsub
  local dateFormat = love.mintmousse.LOG_TIMESTAMP_FORMAT:gsub("%%f", ("%03d"):format(milliseconds))
  return os.date(dateFormat, seconds)
end

-- Used to explicitly log an uncaught error through to the sinks
love.mintmousse.logUncaughtError = function(message, tracebackLayer)
  local time = getTime()
  love.mintmousse._insideFatal = true -- FATAL is non-recoverable, so never switch back

  local traceback = debug.traceback("", (tracebackLayer or 1) + 1)
  traceback = love.mintmousse._cleanUpTraceback(traceback)
  dispatchToSinks("fatal", nil, time, nil, message, "\n"..traceback)
end

---- Logging Initialization

love.mintmousse._require("logger.sinks")
love.mintmousse._require("logger.traceback")

---- Logger face
local colorVal = love.mintmousse._require("logger.color")

local logger = { }
logger.__index = logger

-- extend(name, colorDef) OR extend(parent, name, colorDef) -> logger:extend(name, colorDef)
logger.extend = function(parent, name, colorDef)
  if type(parent) == "string" then
    colorDef, prefix, parent = name, parent, nil
  end

  local self = setmetatable({
    name = name,
    colorDef = colorVal.validateColorDef(colorDef),
    parent = parent,
  }, logger)
  -- init
  self:getAncestry()

  return self
end

logger.getAncestry = function(self)
  if self.chain then
    return self.chain
  end

  local chain = { }

  local current = self
  while current do
    if type(current.name) == "string" then
      table.insert(chain, current)
    end
    current = current.parent
  end

  self.chain = chain
  return self.chain
end

logger.info = function(self, ...)
  local time = getTime()
  love.mintmousse._stackFramePush()
  dispatchToSinks("info", self, time, nil, ...)
  love.mintmousse._stackFramePop()
end

logger.warning = function(self, ...)
  local time = getTime()
  love.mintmousse._stackFramePush()
  dispatchToSinks("warning", self, time, nil, ...)
  if love.mintmousse.LOG_WARNINGS_CAUSE_ERRORS then
    -- Reroute the call to the error handler to raise a clean error
    -- Note, this will call dispatchToSinks again, which is intended.
    self:error("[PROMOTED WARNING]", ...)
  end
  love.mintmousse._stackFramePop()
end

logger.debug = function(self, ...)
  local time = getTime()
  love.mintmousse._stackFramePush()
  -- Always get debug info for debug messages
  dispatchToSinks("debug", self, time, getDebugInfo(), ...)
  love.mintmousse._stackFramePop()
end

logger.error = function(self, ...)
  local time = getTime()
  love.mintmousse._stackFramePush()
  -- Always get debug info for errors
  dispatchToSinks("error", self, time, getDebugInfo(), ...)

  if love.mintmousse.LOG_ENABLE_ERROR or love.isMintMousseThread then
    local logMessage = table.concat({ ... }, " ")
    love.mintmousse._insideError = true
    error(logMessage, stackFrameOffset + 1)
    love.mintmousse._insideError = false
  end
  love.mintmousse._stackFramePop()
end

logger.assert = function(self, condition, ...)
  if not condition then
    love.mintmousse._stackFramePush()
    self:error(...)
    love.mintmousse._stackFramePop()
  end
end

return logger