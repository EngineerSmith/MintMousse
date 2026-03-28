# (Logger):assert
Test a condition, if false, log an [`error` level](../level.md) message.

## Synopsis
```lua
Logger:assert( condition, message... )
```

## Parameters
`condition` _boolean_
:   If condition is false, the message is promoted to an [`error`](../level.md)

`message...` _ANY_
:   The varargs of the message passed to all the sinks. If you pass in a table, it will only print to a maximum depth of 3 tables.

## Returns
Nothing.

## Examples
```lua
Logger:assert("Hello" == "Hello", "World")

Logger:assert(false, "Hello World")

Logger:assert(not tbl, "Hello", 5, "World")

Logger:assert(isType(foo, "table"), nil, 1, "", true, false)

Logger:assert(not not tbl, { key = "value", ["foo"] = "bar" }) -- by default, max depth is 3, see Logger.inspect for larger depths
```

## See Also
- [Logging](../index.md)
- [Logger](index.md)
- [`(Logger):error`](error.md)
- [`(Logger).inspect`](inspect.md)