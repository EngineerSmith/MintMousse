# `mintmousse.newLogger`
Creates a new _[logger](logger/index.md)_ object.

## Synopsis
```lua
mintmousse.newLogger( name, color )
```

## Parameters
`name` _string_
<dd>Identifier shown in the logs</dd>

`color` _[color](color.md)_ (**"white"**)
<dd>Color used to highlight the name in consoles that support color highlighting</dd>

## Returns
`logger` _[logger](logger/index.md)_
<dd>A new object of a logger</dd>

## Examples
```lua
local logger = mintmousse.newLogger("Level")

local logger = mintmousse.newLogger("Joystick", "magenta")

local logger = mintmousse.newLogger("Physics", { fg = "white", bg = "blue" })
```

# See Also
- [`(Logger):extend`](logger/extend.md)
