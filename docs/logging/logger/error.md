# (Logger):error
Log an [`error` level](../level.md) message. The default behaviour, unless the config is changed --TODO link, this will act like the typical global `error` function, and cause the program to halt and run the [`love.errorhandler`](https://love2d.org/wiki/love.errorhandler).

## Synopsis
```lua
Logger:error( message... )
```

## Parameters
`message...` _ANY_
:   The varargs of the message passed to all the sinks. If you pass in a table, it will only print to a maximum depth of 3 tables.
## Returns
Nothing.

## Examples
```lua
Logger:error("Hello World")

Logger:error("Hello", "World")

Logger:error("Hello", 5, "World")

Logger:error(nil, 1, "", true, false)

Logger:error({ key = "value", ["foo"] = "bar" }) -- by default, max depth is 3, see Logger.inspect for larger depths
```

## See Also
- [Logging](../index.md)
- [Logger](index.md)
- [`mintmousse.logUncaughtError`](../logUncaughtError.md)
- [`(Logger).inspect`](inspect.md)