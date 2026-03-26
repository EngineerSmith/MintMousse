# (Logger):getAncestry
Used internally to get all hierarchy of the current [`Logger`](index.md). The array is in "reverse", with the first logger at the first position, and the next one is the one the current [`Logger`](index.md) was [`(Logger):extend`ed](extend.md) from.

This is useful if you're writing your own [log sink](../addLogSink.md).

## Synopsis
```lua
chain = Logger:getAncestry()
```

## Parameters
None.

## Returns
`ancestryData` _table_
:   An array of the logger's ancestry information. `ancestryData[1]` will be the upmost root, `ancestryData[#ancestryData]` will be the Logger that called the function.

    Each entry in the table, is a table with the two fields `name` _string_ and `colorDef` _[color](../color.md)_

## Examples
```lua
local ancestryData = Logger:getAncestry()
local prefixParts = { }
for _, node in ipairs(ancestryData) do
  table.insert(prefixParts, node.name)
end
print(table.concat(prefixParts, ":"))
```

## See Also
- [Logging](../index.md)
- [Logger](index.md)
- [(Logger):extend](extend.md)
