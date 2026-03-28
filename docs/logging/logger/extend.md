# (Logger):extend
Builds upon an existing logger object to make a 'chained' name to appear within the logs.

For example, the default behaviour is to 'chain' left-to-right, `[a:b:c]` with each name appearing in the chosen color.

## Synopsis
```lua
logger = Logger:extend( name, color )
```
## Parameters
`name` _string_
:   Identifier shown in the logs.

`color` _[color](../color.md)_ (**"white"**)
:   Color used to highlight the name in consoles that support color highlighting.

## Returns
`logger` _[logger](logger/index.md)_
:   A new object of a logger.

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