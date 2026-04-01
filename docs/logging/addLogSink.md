# `mintmousse.addLogSink`
Used to add a custom sink to direct log messages to where ever you want, for the current thread that the function is ran on.

I recommend checking out the logging sinks that the library implements to fully understand how you can implement your own.

!!! warning "Thread behaviour"

    This function is used to route logs of the thread that this function is ran on. If you just want to set a logging sink once, and handle all logs from all threads see [`mintmousse.addGlobalLogSink`](addGlobalLogSink.md). This function is recommended over global sinks for performance.

## Synopsis
```lua
mintmousse.addLogSink( sink, flushFunc )
```

## Parameters
`sink` _function_
:   A function, with the signature `(level, logger, time, debugInfo, message...)`. See below for details

`flushFunc` _function_
:   A function, with the signature `(forced)`. See [`mintmousse.flushLogs`](flushLogs.md) for details

### Sink Function Signature
`level` _[level](level.md)_
:   A string indicating the level of the log, `"info"`, `"warning"`, `"error"`, `"fatal"`, `"debug"`.

`logger` _[logger](logger.md)_
:   The logger that created the log.

    You shouldn't try to use any other function of the logger when it is in a sink other than [`(Logger):getAncestry`](logger/getAncestry.md) and [`(Logger).inspect`](logger/inspect.md).

`time` _number_
:   UNIX time in seconds, with microseconds. By default, this value is obtained by `socket.gettime` to get an accurate system time.

`debugInfo` _string_ or _nil_
:   Depending on the level, and the config -- TODO link, a simple traceback string is passed along the lines of `funcName@fileName#lineNumber`, this format isn't guaranteed, for example code in the file scope will be `fileName#lineNumber` as they aren't contained within a named function.

`message...` _ANY_
:   The varargs of the message passed from the log function.

## Returns
Nothing.

## Examples
```lua
mintmousse.addLogSink(
  function(level, logger, time, debugInfo, ...) -- Sink function
    if (level == "info" or info == "warning") and
        and math.floor(time) and not debugInfo then
      local num = select('#', ...)
      io.stdout:write(num .. "\n")
    end
  end,
  function(forced) -- Flush function
    io.stdout:flush()
  end
)

logger:info("Hello", "World", 0, nil, { }) -- 6\n
logger:warning("Foo", "Bar") -- 2\n

mintmousse.flushLogs()
```

# See Also
- [Logging](index.md)
- [`mintmousse.addGlobalLogSink`](addGlobalLogSink.md)