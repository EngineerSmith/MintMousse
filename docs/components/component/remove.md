# `(Component):remove`
Used to remove a component.

!!! warning "isDead"
    Once this method, or [`mintmousse.remove`](../remove.md) is called. The component table's field `isDead` becomes true, and you will no longer be able to set, or get any other field. The same is true for all it's known-locally children.

## Synopsis
```lua
component:remove()
```

## Parameters
Nothing.

## Returns
Nothing.

## Examples
```lua
local tab = mintmousse.newTab("Remove me")

tab:remove()
if not tab.isDead then
  tab:addText({ text = "This will never run" })
end
```

## See Also
- [Components](../index.md)
- [Component](index.md)
- [`mintmousse.remove`](../remove.md)