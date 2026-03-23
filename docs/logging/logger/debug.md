# (Logger):debug
Log a [`debug` level](../level.md) message. This log level usually includes prints the line it is called on.

This is usually in the format of `funcName@fileName#LineNumber`, but not always. For example, if it was called it filescope, or couldn't find a name for the function it will just be `fileName#LineNumber`.

If you use the global function `print`, it will act like a debug log message. This behaviour can be disabled by checking the config. -- TODO link

## Synopsis
```lua
Logger:debug( message... )
```

## Parameters
`message...` _ANY_
:   The varargs of the message passed to all the sinks. If you pass in a table, it will only print to a maximum depth of 3 tables.

## Returns
Nothing.

## Examples
```lua
Logger:debug("Hello World")

Logger:debug("Hello", "World")

Logger:debug("Hello", 5, "World")

Logger:debug(nil, 1, "", true, false)

Logger:debug({ key = "value", ["foo"] = "bar" }) -- by default, max depth is 3, see Logger.inspect for larger depths
```

## See Also
- [Logging](../index.md)
- [Logger](index.md)
- [`(Logger).inspect`](inspect.md)
