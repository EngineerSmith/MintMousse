# `(Component):moveAfter`
Move the component after one of it's siblings.

## Synopsis
```lua
component = component:moveAfter( sibling )
```

## Parameters
`sibling` _string_ or [_Component_](component/index.md)
:   Can be an ID of a sibling, or the sibling component itself.

## Returns
`component` [_Component_](component/index.md)
:   Returns the caller table, so it can be chained

## Examples
```lua
local container = mintmousse.get("container")
container.moveAfter("otherContainer")

container.moveAfter(mintmousse.get("container"))
```

## See Also
- [Components](../index.md)
- [Component](index.md)
- [`(Component):moveBefore`](moveBefore.md)