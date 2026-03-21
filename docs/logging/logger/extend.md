# (Logger):extend
Builds upon an existing logger object to make a 'chained' name to appear within the logs.

For example, the default behaviour is to 'chain' left-to-right, `[a:b:c]` with each name appearing in the chosen color.

## Synopsis
```lua
logger = Logger:extend( name, color )
```
## Parameters
`name` _string_
<dd>Identifier shown in the logs.</dd>

`color` _[color](../color.md)_ (**"white"**)
<dd>Color used to highlight the name in consoles that support color highlighting.</dd>

## Returns
`logger` _[logger](logger/index.md)_
<dd>A new object of a logger.</dd>

## Examples
```lua
local a = Logger:extend("a")

local b = a:extend("b", "blue")

local c = c:extend("c", { fg = "white", bg = "blue" })
```

## See Also
- [Logging](../index.md)
- [Logger](index.md)
- [`mintmousse.newLogger`](../newLogger.md)
