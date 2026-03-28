# `mintmousse.setIcon`
Set the icon of the console to use to make your tab recognisable. Don't have an image? No problem, use the SVG generator to quickly create something!

## Synopsis
```lua
mintmousse.setIcon( icon )
```

## Parameters
`icon` _string_ or _table_ or [_Data_](https://love2d.org/wiki/Data)
:   -- TODO _Data_ becomes a _string_, _table_ is for SVG generator; if _string_ is a file path, it is read, if it is raw binary, magic numbers for PNG and jpeg are searched for.

## Returns
Nothing.

## Examples
```lua
mintmousse.setIcon({
  emoji = "🍮",
  easterEgg = "MM",
})

mintmousse.setIcon("assets/console.icon.jpeg")

mintmousse.setIcon(love.filesystem.read("assets/console/icon.png"))
```

## See Also
- [Controller](index.md)
- [`mintmousse.setIconRaw`](setIconRaw.md)