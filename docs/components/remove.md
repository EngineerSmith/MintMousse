# `mintmousse.remove`
Remove a component using it's id. If the component doesn't exist, it is ignored. See [`(Component):remove`](component/remove.md) if you want to remove a component you already have a table for.

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
```

## See Also
- [Components](index.md)
- [`(Component):remove`](component/remove.md)