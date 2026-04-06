# `mintmousse.remove`
Remove a component using it's id. If the component doesn't exist, it is ignored. See [`(Component):remove`](component/remove.md) if you want to remove a component you already have a table for.

!!! warning "isDead"
    Once this method, or [`(Component):remove`](component/remove.md) is called, and there is an existing component table with the given ID. It's field `isDead` becomes true, and you will no longer be able to set, or get any field. The same is true for all it's known-locally children.

## Synopsis
```lua
mintmousse.remove( id )
```

## Parameters
`id` _string_
:   A valid ID for removal.

## Returns
Nothing.

## Examples
```lua
mintmousse.remove("dashboardList")

if not mintmousse.has("dashboardList") then
  print("Removed dashboardList")
end
```

## See Also
- [Components](index.md)
- [`(Component):remove`](component/remove.md)