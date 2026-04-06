# `mintmousse.has`
Use this function to check if a component exists locally already. Useful if you want to use [`mintmousse.get`](get.md), but not accidentally create a new component.

## Synopsis
```lua
doesExist = mintmousse.has( id )
```

## Parameters
`id` _string_
:   The ID of the component you're trying to check if it exists locally.

## Returns
`doesExist` _boolean_
:   If the given ID already has a component table on the current thread.

## Examples
```lua
if mintmousse.has("dashboardTab") then
  local dashboard = mintmousse.get("dashboardTab")
end

if not mintmousse.has("foobar") then
  mintmousse.get("foobar", "Accordion")
end
```

## See Also
- [Components](index.md)
- [`mintmousse.get`](get.md)