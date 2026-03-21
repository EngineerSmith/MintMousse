# Logging
MintMousse ships a powerful, thread-safe logging system that lets you:

- Create named, color-aware loggers with easy hierarchy (`module:submodule:minor`)
- Print to console with automatic ANSI stripping for files
- Route logs anywhere (file, REST, custom sink, etc.)
- Safely handle crashes via [`love.errorhandler`](https://love2d.org/wiki/love.errorhandler) so nothing is missed.

## Quick Start
```lua
-- 1. Create & extend loggers (the most common use)
local moduleLogger = mintmousse.newLogger("module", "cyan")
moduleLogger:info("Module initialized")

local subLogger = moduleLogger:extend("submodule", "bright_blue")
subLogger:warning("You're getting the hang of it now")

local minorLogger = subLogger:extend("minor")
minorLogger:debug("I print the line I'm on - useful during development!")

print("Quick out") -- works like `logger:debug`, but super quick and dirty

-- 2. Catch all error that don't route the expected way
love.errorhandler = function(msg)
  msg = tostring(msg)
  mintmousse.logUncaughtError(msg) -- automatically logs and flushes
  -- ... error screen here
end

-- 3. Advanced: send logs to a server
mintmousse.addLogSink(function(level, logger, time, debugInfo, ...)
  if level == "error" or level == "fatal" then
    -- send to your analytic endpoint
  end
end)
```

The [`(Logger):extend`](logger/extend.md) method automatically builds the `[module:submodule:minor]` prefix to quickly organise your logs.

## Types
|Type|Description|
|---|---|
|[Logger](logger/index.md)|Logging instance|

## Functions
|Function|Description|
|---|---|
|[`mintmousse.newLogger`](newLogger.md)|Create a new named, colored logger object|
|[`mintmousse.flushLogs`](flushLogs.md)|Flush the log buffer (thread-safe)|
|[`mintmousse.logUncaughtError`](logUncaughtError.md)|Catch errors in [`love.errorhandler`](https://love2d.org/wiki/love.errorhandler)|
|[`mintmousse.addLogSink`](addLogSink.md)|Register a custom destination for all log messages|

## Enums
|Enum|Description|
|---|---|
|[Color](color.md)|Color definitions for the logging module|
