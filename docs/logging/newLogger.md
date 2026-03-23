# `mintmousse.newLogger`
Creates a new _[logger](logger/index.md)_ object.

## Synopsis
```lua
mintmousse.newLogger( name, color )
```

## Parameters
`name` _string_
:   Identifier shown in the logs

`color` _[color](color.md)_ (**"white"**)
:   Color used to highlight the name in consoles that support color highlighting

## Returns
`logger` _[logger](logger/index.md)_
:   A new object of a logger

## Examples
```lua
local logger = mintmousse.newLogger("Level")

local logger = mintmousse.newLogger("Joystick", "magenta")

local logger = mintmousse.newLogger("Physics", { fg = "white", bg = "blue" })
```

# See Also
- [`(Logger):extend`](logger/extend.md)
