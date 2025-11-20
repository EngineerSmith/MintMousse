-- Creates global which points to the default print function; to ensure we aren't
-- being destructive if config `REPLACE_FUNC_PRINT` is active
GLOBAL_print = print

-- Internal usage
love.mintmousse._logging = {
  _sinks = { },
  _logStyles = {
    info      = { prefix = "[INFO]",  color = "\27[32m"        }, -- `color` use ANSI color codes
    warning   = { prefix = "[WARN]",  color = "\27[33m"        },
    error     = { prefix = "[ERROR]", color = "\27[31m"        },
    fatal     = { prefix = "[FATAL]", color = "\27[41m\27[97m" },
    debug     = { prefix = "[DEBUG]", color = "\27[36m"        },

    -- Non-log level elements:
    message   = {                    color = "\27[0m"  }, -- Color used for normal messages
    timestamp = {                    color = "\27[90m" }, -- Color used for timestamp
    prefix    = {                    color = "\27[2m"  }, -- Color used for logger prefix
    STOP      = {                    color = "\27[0m"  }, -- Reset color at end of text
  },
  _ANSIPattern = "\27%[[%d;]-m", -- Used to find ANSI codes in strings
}

love.mintmousse._require("logger.ANSI")
love.mintmousse._require("logger.sinks")
love.mintmousse._require("logger.traceback")

--- Util functions

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
      info.name = "CFunc" -- if C funciton is anonymous
    elseif info.what == "main" then
      info.name = nil -- file/chunk scope
    end

    if info.short_src then
      debugInfo = (info.name and info.name .. "@" or "") .. info.short_src .. (info.currentline and "#" .. info.currentline or "")
    else
      debugInfo = info.name or "UNKNOWN"
    end
    debugInfo = "[".. debugInfo .."]"
  end
  love.mintmousse._stackFramePop()
  return debugInfo
end

--- Sinks

local dispatchToSinks = function(...)
  love.mintmousse._stackFramePush()
  for _, sink in ipairs(love.mintmousse._logging._sinks) do
    sink(...)
  end
  love.mintmousse._stackFramePop()
end

-- Used to explicitly log an uncaught error through to the sinks
love.mintmousse.logUncaughtError = function(message, tracebackLayer)
  local time = getTime()
  love.mintmousse._insideFatal = true -- FATAL is non-recoverable, so never switch back

  local traceback = debug.traceback("", (tracebackLayer or 1) + 1)
  traceback = traceback:sub(2)
  dispatchToSinks("fatal", nil, time, nil, message, traceback)
end

---- Logger face

local logger = { }
logger.__index = logger

-- logger.extend(parent, prefix) / logger.extend(prefix) -> logger:extend(prefix)
logger.extend = function(parent, prefix)
  if type(parent) == "string" then
    prefix, parent = parent, nil
  end

  assert((type(parent) == "table" and getmetatable(parent) == logger) or type(parent) == "nil",
    "Expected parent type to be logger, or nil")

  local self
  if type(parent) == "nil" then
    if type(prefix) == "nil" or prefix == "" then
      self = { prefix = "" }
    else
      self = { prefix = "[" .. prefix .. "]" }
    end
  else
    if parent.prefix == "" then
      self = { prefix = "[" .. prefix .. "]"}
    else
      -- Combines prefixes to [A:B] e.g. [ProxyTable:__index]
      self = { prefix = parent.prefix:sub(1, -2) .. ":" .. prefix .. "]" }
    end
  end
  setmetatable(self, logger)

  return self
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
    -- We strip ANSI colors here, as the message is destined for an incompatible renderer.
    error(love.mintmousse._stripANSIColor(logMessage), stackFrameOffset + 1)
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