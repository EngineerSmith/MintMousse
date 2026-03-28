# (Logger):warning
Log a [`warning` level](../level.md) message.

## Synopsis
```lua
Logger:warning( message... )
```

## Parameters
`message...` _ANY_
:   The varargs of the message passed to all the sinks. If you pass in a table, it will only print to a maximum depth of 3 tables.

## Returns
Nothing.

## Examples
```lua
Logger:warning("Hello World")

Logger:warning("Hello", "World")

Logger:warning("Hello", 5, "World")

Logger:warning(nil, 1, "", true, false)

Logger:warning({ key = "value", ["foo"] = "bar" }) -- by default, max depth is 3, see Logger.inspect for larger depths
```

## See Also
- [Logging](../index.md)
- [Logger](index.md)
- [`(Logger).inspect`](inspect.md)