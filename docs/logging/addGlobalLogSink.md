# `mintmousse.addGlobalLogSink`
Used to add a custom sink to direct log messages from across all threads in a single place. This function can only be used on the main thread.

I recommend checking out the logging sinks that the library implements to fully understand how you can implement your own.

!!! note "Thread behaviour"

    This function can only be called on the main thread. If you can architect it, it's recommended to use the pre-thread sinks added via [`mintmousse.addLogSink`](addLogSink.md).

## Synopsis
```lua
mintmousse.addGlobalLogSink( sink, flushFunc )
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
Not necessarily working code, but an idea.
```lua
local http = require("socket.http")

local logs = { }
mintmousse.addGlobalLogSink(
  function(level, logger, time, debugInfo, ...) -- Sink function
    if (level == "error" or info == "fatal") then
      table.insert(logs, table.concat({ ... }, " "))
    end
  end,
  function(forced) -- Flush function
    http.request({
        url = "http://example.com/endpoint/?logs=" .. table.concat(logs, "&"),
        method = "POST",
      })
  end
)
```

# See Also
- [Logging](../index.md)
- [`mintmousse.addLogSink](addLogSink.md)