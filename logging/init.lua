local PATH = ...
PATH = PATH:match("^(.*)%.init$") or PATH
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local socket = require("socket")

local mintmousse = require(ROOT .. "conf")
local codec      = require(ROOT .. "codec")

local stack     = require(PATH .. "stack")
local logger    = require(PATH .. "logger")
local inspector = require(PATH .. "inspector")

local logging = {
  logger = logger,
  isInsideError = false,
  isInsideFatal = false,
  sinks = { }, -- per thread
  globalSinks = { },
  flushFuncs = { },
  globalFlushFuncs = { },

  inspect = inspector.inspect,
}

local getTime = socket.gettime
local logChannel = love.thread.getChannel(mintmousse.LOG_EVENT_CHANNEL)

local dispatchToSinks = function(level, logger, time, debugInfo, ...)
  stack.push()
  for _, sink in ipairs(logging.sinks) do
    sink(level, logger, time, debugInfo, ...)
  end

  if love.isThread then
    local ancestry = logger and logger:getAncestry() or nil

    local args, argCount = { }, select("#", ...)
    for i = 1, argCount do
      args[i] = select(i, ...)
    end
    args.n = argCount

    logChannel:push(codec.encode({ level, ancestry, time, debugInfo, args }))
  end

  stack.pop()
end

-- Inject core dependencies into logger
logger.setup({
  dispatch = dispatchToSinks,
  getTime  = getTime,
})
logger.inspect = logging.inspect

local dummyLogger = {
  getAncestry = function(self) return self.ancestryData end,
  inspect = logging.inspect,
}

logging.processPendingLogs = function()
  if love.isThread or #logging.globalSinks == 0 then
    return
  end
  stack.push()

  local processed = 0
  while processed <= mintmousse.LOG_MAX_PENDING_LOGS_PER_FLUSH do
    local rawEvent = logChannel:pop()
    if not rawEvent then break end

    local event = codec.decode(rawEvent)
    local level, ancestry, time, debugInfo, args = event[1], event[2], event[3], event[4], event[5]

    dummyLogger.ancestryData = ancestry
    for _, sink in ipairs(logging.globalSinks) do
      sink(level, ancestry and dummyLogger or nil, time, debugInfo, table.unpack(args, 1, args.n))
    end

    processed = processed + 1
  end
  dummyLogger.ancestryData = nil -- clean up

  stack.pop()
end

local cleanupTraceback = require(PATH .. "cleanupTraceback")
logging.enableCleanupTraceback = function(bool)
  if bool and not cleanupTraceback then
    cleanupTraceback = require(PATH .. "cleanupTraceback")
  elseif not bool and cleanupTraceback then
    cleanupTraceback = nil
  end
end

--- Calls the flush callbacks for each sink
-- forced (boolean) If true, bypasses the thread lock (useful for fatal errors) when implemented for flush callbacks
logging.flushLogs = function(forced)
  if not love.isThread then
    logging.processPendingLogs()
  end

  for _, func in ipairs(logging.flushFuncs) do
    func(forced)
  end
  for _, func in ipairs(logging.globalFlushFuncs) do
    func(forced)
  end
end

--- Creates a new Logger instance
logging.newLogger = function(...)
  return logger.extend(nil, ...)
end

--- Registers a new sink function to receive log events.
-- Arguments passed to sink: (level, loggerInstance, time, debugInfo, ...)
logging.addLogSink = function(sink, flushFunc)
  assert(type(sink) == "function", "Expected sink type to be function.")
  if flushFunc then
    assert(type(flushFunc) == "function", "Expected flushFunc type to be a function or nil")
  end

  table.insert(logging.sinks, sink)
  if flushFunc then
    table.insert(logging.flushFuncs, flushFunc)
  end
end

-- Registers a new sink that runs *once* in  the main thread and receives logs from ALL threads
logging.addGlobalLogSink = function(sink, flushFunc)
  assert(not love.isThread, "addGlobalLogSink can only be called from the main thread")
  assert(type(sink) == "function", "Expected sink type to be function")
  if flushFunc then
    assert(type(flushFunc) == "function", "Expected flushFunc type to be a function or nil")
  end

  table.insert(logging.globalSinks, sink)
  if flushFunc then
    table.insert(logging.globalFlushFuncs, flushFunc)
  end
end

--- Explicitly logs an uncaught error and forces a flush.
-- This enters a fatal state.
logging.logUncaughtError = function(message, tracebackLayer)
  local time = getTime()
  logging.isInsideFatal = true

  stack.push()
  local traceback = debug.traceback("", 1 + stack.frameOffset + (tracebackLayer or 0))
  if cleanupTraceback then
    traceback = cleanupTraceback(traceback)
  end

  dispatchToSinks("fatal", nil, time, nil, message, "\n"..traceback)
  logging.flushLogs(true)

  stack.pop()
end

return logging