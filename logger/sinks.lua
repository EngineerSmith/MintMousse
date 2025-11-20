-- Add a new logging sink function to receive all log messages.
--
-- A sink function is called each time a log event occurs with the following arguments:
-- (1) level (string): The log level: "info", "warning", "error", "fatal", "debug"
-- (2) logger (table/nil): The logger instance (with `.prefix`) that initiated the log.
-- (3) time (number): The unix timestamp of the event: `os.time()`
-- (4) debugInfo (string/nil): Trace information, formatted as `[func@file#line]`
-- (5) ... (vararg): The log message parts. (strings, numbers)
love.mintmousse.addLogSink = function(sink)
  assert(type(sink) == "function", "Expected sink type to be function.")
  table.insert(love.mintmousse._logging._sinks, sink)
end

local getTimestamp = function(time)
  local seconds = math.floor(time)
  local milliseconds = math.floor((time - seconds)*1000)
  local dateFormat = love.mintmousse.LOG_TIMESTAMP_FORMAT:gsub("%%f", ("%03d"):format(milliseconds))
  return os.date(dateFormat, seconds)
end

--- Internal Sink Implementation (Standard print)
love.mintmousse.addLogSink(function(level, logger, time, debugInfo, ...)
  if not love.mintmousse.LOG_ENABLE_PRINT then
    return -- Early exit if there are no enabled output destinations
  end

  local message = { }

  local logStyles = love.mintmousse._logging._logStyles
  table.insert(message, love.mintmousse._applyANSIColor(level, logStyles[level].prefix))

  if love.mintmousse.LOG_ENABLE_TIMESTAMP then
    table.insert(message, love.mintmousse._applyANSIColor("timestamp", getTimestamp(time)))
  end

  if logger and logger.prefix ~= "" then
    table.insert(message, love.mintmousse._applyANSIColor("prefix", logger.prefix))
  end

  if debugInfo and debugInfo ~= "" then
    table.insert(message, love.mintmousse._applyANSIColor("debug", debugInfo))
  end

  local logMessage
  if level == "fatal" then
    local errorMessage, traceback = select(1, ...), select(2, ...)
    if type(traceback) == "string" and type(errorMessage) == "string" then
      if love.mintmousse.LOG_CLEAR_UP_TRACEBACK then
        traceback = love.mintmousse._cleanUpTraceback(traceback)
      end

      logMessage = errorMessage.."\n"..traceback

      local header = "Traceback:"
      logMessage = logMessage:gsub("stack traceback:\n", header.."\n", 1)

      if not logMessage:find(header) then -- Catch anything unexpected
        logMessage = errorMessage.."\n"..header.."\n"..traceback
      end

    elseif type(errorMessage) == "string" then
      logMessage = errorMessage
    else -- Attempt to catch anything else
      logMessage = table.concat({ ... }, " ")
    end
  else
    logMessage = table.concat({ ... }, " ")
  end
  logMessage = logMessage:gsub("\r?\n", "\n\t")
  table.insert(message, love.mintmousse._applyANSIColor("message", logMessage))


  local formattedMessage = table.concat(message, " ")

  if not love.mintmousse._isANSISupported then
    -- We strip any ANSI escape codes users may have added to their prefixes, or message
    formattedMessage = love.mintmousse._stripANSIColor(formattedMessage)
  end

  GLOBAL_print(formattedMessage)
end)