# Logging
MintMousse ships a powerful, thread-safe logging system that lets you:

- Create named, color-aware loggers with easy hierarchy (`module:submodule:minor`)
- Print to console with automatic ANSI stripping for files
- Route logs anywhere (file, REST, custom sink, etc.)
- Safely handle crashes via `love.errorhandle` so nothing is missed.

See also: [Logger object](logger.md) • [Color format](color.md)

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

The `:extend` method (see [Logger:extend](logger.md#logger:extend)) automatically builds the `[module:submodule:minor]` prefix to quickly organise your logs.

## Functions
|Function|Description|
|---|---|
|[`mintmousse.newLogger`](newLogger.md)|Create a named, coloured logger object|
|[`mintmousse.flushLogs`](flushLogs.md)|Flush the log buffer (thread-safe)|

## Examples
To use the logging module of MintMousse, you'll be mostly interfacing with these common uses.

```lua
-- Creating, and extending a logger
local moduleLevelLogger = mintmousse.newLogger("module", "cyan")
moduleLevelLogger:info("Module initialized")

local submoduleLogger = moduleLevelLogger:extend("submodule", "bright_blue")
submoduleLogger:warning("You're getting the hang of it now")

local minorLogger = submoduleLogger:extend("minor")
minor:debug("I print the line I'm on to help you find me! It's so easy to lose which prints are for dev")
```

You'll noticed in the example above we use (logger:extend)[logger.md#logger:extend] which allows you to string together more detailed logging which, by default, with the `minor` it'll appear as `[module:submodule:minor]` with each word having the color you define for it, or don't define one and it'll be white.

## `mintmousse.newLogger`
Creates a new logger instance

### Synopsis
```lua
mintmousse.newLogger(name, color)
```

### Parameters
`name` _string_
<dd>Identifier shown in the logs</dd>

`color` _[color](color.md)_ (**"white"**)
<dd>Color used to highlight the name in consoles that support color highlighting</dd>

### Returns
`logger` _[logger](logger.md)_
<dd>A new instance of a logger</dd>

### Examples
```lua
local logger = mintmousse.newLogger("Level")

local logger = mintmousse.newLogger("Joystick", "magenta")

local logger = mintmousse.newLogger("Physics", { fg = "white", bg = "blue" })
```

## `mintmousse.flushLogs`
Thread-safe function to flush io buffer for the base implemented logging sink.

### Synopsis
```lua
mintmousse.flushLogs(forced)
```

### Parameters
`forced` _boolean_ (**false**)
<dd>Used to override the thread lock and immediately flush the buffer. This parameter is used internally during a crash state, and not recommended to be used.</dd>

### Returns
Nothing.

### Examples
```lua
mintmousse.flushLogs()

mintmousse.flushLogs(true)
```

## `mintmousse.logUncaughtError`
Use within `love.errorhandler`, to make sure all thrown errors are caught and directed into the sinks. See the `errorhandler` that MintMousse implements, but TLDR; it's put in place of `error_printer` in the default `errorhandler`.

### Synopsis
```lua
mintmousse.logUncaughtError(message, tracebackLayer)
```

### Parameters
`message` _string_
<dd>The reported error message</dd>

`tracebackLayer` _number_ (**0**)
<dd>Increase to reduce the generated traceback to correctly report the cause of the crash. 'layer' 0 is when it is directly called within `love.errorhandler`.</dd>

### Returns
Nothing.

### Examples
```lua
love.errorhandler = function(msg)
  msg = tostring(msg)

  mintmousse.logUncaughtError(msg)
  -- or
  mintmousse.logUncaughtError(msg, 0)
  -- or
  (function()
    mintmousse.logUncaughtError(msg, 1)
  end)()

  -- etc..
end
```

## `mintmousse.addLogSink`
Used to add a custom sink to direct log messages to where ever you want, for example if you wanted to send them to a REST API endpoint.

I recommend checking out the logging sinks that the library implements to fully understand how you can implement your own.

### Synopsis
```lua
mintmousse.addLogSink(sink)
```

### Parameters
`sink` _function_
<dd>A function, with the signature `(level, logger, time, debugInfo, message...)`</dd>

---
`level` _string_
<dd>A string indicating the level of the log, `"info"`, `"warning"`, `"error"`, `"fatal"`, `"debug"`</dd>

`logger` _[logger](logger.md)_
<dd>The logger that created the log, see _[logger:getAncestry](logger.md#logger:getAncestry)_ to get the </dd>

`time` _number_
<dd>UNIX time in seconds, with microseconds. By default, this value is obtained by `socket.gettime` to get an actuate system time.</dd>

`debugInfo` _string_ or _nil_
<dd>Depending on the level, and the config, a simple traceback string is passed along the lines of `funcName@fileName#lineNumber`, this format isn't guaranteed, for example code in the file scope will be `fileName#lineNumber` as they aren't contained within a named function.</dd>

`message...` _ANY_
<dd>The varargs of the message passed to the actual log function</dd>

### Returns
Nothing.

### Examples
```lua
mintmousse.addLogSink(function(level, logger, time, debugInfo, ...)
  if (level == "info" or info == "warning") and
      logger.name and math.floor(time) and not debugInfo then
    local num = select('#', ...)
    io.stdout:write(num .. "\n")
  end
end)

logger:info("Hello", "World", 0, nil, { }) -- 6\n
logger:warning("Foo", "Bar") -- 2\n
```
