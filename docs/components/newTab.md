# `mintmousse.newTab`

## Synopsis
```lua
tab = mintmousse.newTab( title, id, index )
```

## Parameters
`title` _string_ (**"UNKNOWN"**)
:   The name of the tab you want to create

`id` _string_ (**nil**)
:   The ID to use for the new tab. If one isn't given, one is generated.

`index` _number_ (**-1**)
:   The index you want to insert the new tab into the navbar. By default, it is placed at the end of the navbar.

## Returns
`tab` [_Component_](component/index.md)
:   The newly created tab.

## Examples
```lua
local tab = mintmousse.newTab("Dashboard", "dbTab", 1)

local console = mintmousse.newTab("Console", nil, -1)

local unknown = mintmousse.newTab(nil, nil, -2)
```

## See Also
- [Components](index.md)