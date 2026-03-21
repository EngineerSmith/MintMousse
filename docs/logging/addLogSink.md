# `mintmousse.addLogSink`
Used to add a custom sink to direct log messages to where ever you want, for example if you wanted to send them to a REST API endpoint.

I recommend checking out the logging sinks that the library implements to fully understand how you can implement your own.

## Synopsis
```lua
mintmousse.addLogSink( sink )
```

## Parameters
`sink` _function_
<dd>A function, with the signature `(level, logger, time, debugInfo, message...)`</dd>

---
`level` _[level](level.md)_
<dd>A string indicating the level of the log, `"info"`, `"warning"`, `"error"`, `"fatal"`, `"debug"`</dd>

`logger` _[logger](logger.md)_
<dd>The logger that created the log, see _[logger:getAncestry](logger.md#logger:getAncestry)_ to get the </dd>

`time` _number_
<dd>UNIX time in seconds, with microseconds. By default, this value is obtained by `socket.gettime` to get an accurate system time.</dd>

`debugInfo` _string_ or _nil_
<dd>Depending on the level, and the config -- TODO link, a simple traceback string is passed along the lines of `funcName@fileName#lineNumber`, this format isn't guaranteed, for example code in the file scope will be `fileName#lineNumber` as they aren't contained within a named function.</dd>

`message...` _ANY_
<dd>The varargs of the message passed from the log function</dd>

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
