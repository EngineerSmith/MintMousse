# `(Component):moveToFront`
Move the component to front/top/first most position.

## Synopsis
```lua
component = component:moveToFront()
```

## Parameters
Nothing.

## Returns
`component` [_Component_](index.md)
:   Returns the caller table, so it can be chained.

## Examples
```lua
local playerList = mintmousse.get("playerList")
playerList:moveToFront()

local tab = mintmousse.get("tab", "Tab")
tab:moveToFront()
```

## See Also
- [Components](../index.md)
- [Component](index.md)
- [`(Component):moveToBack](moveToBack.md)