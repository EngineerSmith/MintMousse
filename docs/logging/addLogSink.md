# `mintmousse.addLogSink`
Used to add a custom sink to direct log messages to where ever you want, for example if you wanted to send them to a REST API endpoint.

I recommend checking out the logging sinks that the library implements to fully understand how you can implement your own.

## Synopsis
```lua
mintmousse.addLogSink( sink )
```

## Parameters
`sink` _function_
:   A function, with the signature `(level, logger, time, debugInfo, message...)`. See below for details

### Function signature
`level` _[level](level.md)_
:   A string indicating the level of the log, `"info"`, `"warning"`, `"error"`, `"fatal"`, `"debug"`.

`logger` _[logger](logger.md)_
:   The logger that created the log, see _[logger:getAncestry](logger/getAncestry.md)_ to get a list of the logger's hierarchy.

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
