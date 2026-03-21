# (Logger).inspect
Used to look into a given table, it will prevent circular dependency, and use a max depth to prevent "too much".

!!! warning "Warning"

    No two returns may be equal, due to internally using the global `pairs` function which is known to not always return the same order.

## Synopsis
```lua
str = Logger.inspector( value, level )
```

## Parameters
`value` _ANY_
<dd>If a non-table type is given, it will return it using `tostring`.</dd>

`level` [_depth_](#) or _number_ (**"light"**)
<dd>The maximum recursive depth to look into a table if it contains tables. `"light"` goes a depth of 1, `"deep"` goes a depth of 3, and `number` lets you fine tune how much depth.</dd>

## Returns
`str` _string_
<dd>A formatted string of the given table, or non-table value, to the specified depth.</dd>

## Examples
```lua
local tbl = {
  foo = "bar",
  tbl = { "foo", "bar" }
}

local str = Logger.inspect(tbl, "light")
print(str)

Logger:info(Logger.inspect(tbl, "deep"))

Logger:info(Logger.inspect(tbl, 3))
```

## See Also
- [Logging](../index.md)
- [Logger](index.md)
