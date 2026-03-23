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
`chain` _table_
:   An array of the current logger [1], until the parent is `nil`.

## Examples
```lua
local chain = Logger:getAncestry()
local prefixParts = { }
for i = #chain, 1, -1 do
  local node = chain[i]
  table.insert(prefixParts, node.name)
end
print(table.concat(prefixParts, ":"))
```

## See Also
- [Logging](../index.md)
- [Logger](index.md)
- [(Logger):extend](extend.md)
