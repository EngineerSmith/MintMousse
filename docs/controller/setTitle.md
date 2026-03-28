# `mintmousse.setTitle`
Set the title of the web console, and the name in the tab. By default, the title is preset to **"MintMousse"**.

## Synopsis
```lua
mintmousse.setTitle( title )
```

## Parameters
`title` _string_
:   Sets the title of the console to the given string.

## Returns
Nothing.

## Examples
```lua
mintmousse.setTitle("MintMousse")

mintmousse.setTitle("Game Console")

mintmousse.setTitle(love.window.getTitle() .. " Console")
```

## See Also
- [Controller](index.md)
- [`mintmousse.start`](start.md)