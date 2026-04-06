# `(Component):moveBefore`
Move the component before one of it's siblings.

## Synopsis
```lua
component = component:moveBefore( sibling )
```

## Parameters
`sibling` _string_ or [_Component_](component/index.md)
:   Can be an ID of a sibling, or the sibling component itself.

## Returns
`component` [_Component_](component/index.md)
:   Returns the caller table, so it can be chained

## Examples
```lua
local playerComponent = mintmousse.get("player.john")
playerComponent:moveBefore("player.steven")

playerComponent:moveBefore(otherPlayerComponent)
```

## See Also
- [Components](../index.md)
- [Component](index.md)
- [`(Component):moveAfter`](moveAfter.md)