local PATH = ...
PATH = PATH:match("^(.*)%.init$") or PATH
PATH = PATH .. "."

local socket = require("socket")
local stack = require(PATH .. "stack")
local logger = require(PATH .. "logger")

local cleanupTraceback = require(PATH .. "cleanupTraceback")

-- Snapshot the default print to prevent recursion if config REPLACE_FUNC_PRINT is used
GLOBAL_print = print

local logging = {
  logger = logger,
  isInsideError = false,
  isInsideFatal = false,
  sinks = { },
}

local getTime = socket.gettime

local dispatchToSinks = function(...)
  stack.push()
  for _, sink in ipairs(logging.sinks) do
    sink(...)
  end
  stack.pop()
end

local flushStdOut = function()
  io.stdout:flush()
end

local bufferLockChannel

--- Config the stdout buffer and thread locking channel
logging.setupBuffer = function(bufferSize, lockChannel)
  io.stdout:setvbuf("full", bufferSize)
  bufferLockChannel = love.thread.getChannel(lockChannel)
end

--- Flushes the log buffer to stdout.
-- @param forced (boolean) If true, bypasses the thread lock (useful for fatal errors)
logging.flushLogs = function(forced)
  if not forced and bufferLockChannel then
    bufferLockChannel:performAtomic(flushStdOut)
  else
    flushStdOut()
  end
end

--- Creates a new Logger instance
logging.newLogger = function(...)
  return logger.extend(nil, ...)
end

--- Registers a new sink function to receive log events.
-- Arguments passed to sink: (level, loggerInstance, time, debugInfo, ...)
logging.addLogSink = function(sink)
  assert(type(sink) == "function", "Expected sink type to be function.")
  table.insert(logging.sinks, sink)
end


--- Explicitly logs an uncaught error and forces a flush.
-- This enters a fatal state.
logging.logUncaughtError = function(message, tracebackLayer)
  local time = getTime()
  logging.isInsideFatal = true

  stack.push()
  local traceback = debug.traceback("", 1 + stack.frameOffset + (tracebackLayer or 0))
  traceback = cleanupTraceback(traceback)

  dispatchToSinks("fatal", nil, time, nil, message, "\n"..traceback)
  logging.flushLogs(true)

  stack.pop()
end

-- Inject core dependencies into logger
logger.setup({
  dispatch = dispatchToSinks,
  getTime = getTime,
})

return logging