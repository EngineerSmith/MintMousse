# `mintmousse.get`
Use this function to get a component with a given ID. This function will always return a component with the given ID. You can use the `typeHint` parameter to suggest what type this component is if it doesn't exist on the local thread.

## Synopsis
```lua
component = mintmousse.get( id, typeHint )
```

## Parameters
`id` _string_
:   The ID of the component you're trying to get a reference of.

`typeHint` _string_
:   If the component is not found locally, it create's a local version with the given hint. This hint is ignored if it found.

## Returns
`component` [_Component_](component/index.md)
:   The returned component with the given ID. It will always return a component that can be updated.

## Examples
```lua
local list = mintmousse.get("playerList")
list.isNumbered = true

local dbList = mintmousse.get("dashboardList", "List")
list:newContainer()
```

## See Also
- [Components](index.md)
- [`mintmousse.has`](has.md)