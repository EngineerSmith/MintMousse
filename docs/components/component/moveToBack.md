# `(Component):moveToBack`
Move the component to back/bottom/last most position.

## Synopsis
```lua
component = component:moveToBack()
```

## Parameters
Nothing.

## Returns
`component` [_Component_](index.md)
:   Returns the caller table, so it can be chained.

## Examples
```lua
local playerContainer = mintmouse.get("player.steven", "container")
playerContainer:moveToBack()
```

## See Also
- [Components](../index.md)
- [Component](index.md)
- [`(Component):moveToFront`](moveToFront.md)