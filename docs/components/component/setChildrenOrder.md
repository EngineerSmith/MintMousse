# `(Component):setChildrenOrder`
Used to reorder all children that a component has, even if they're not declared locally either via creation or using [`mintmousse.get`](../get.md).

## Synopsis
```lua
component = component:setChildrenOrder( newOrder )
```

## Parameters
`newOrder` _table_ of _string_
:   The array of IDs in the order you want them to appear.

## Returns
Nothing.

## Examples
```lua
local list = tab:newList({ isNumbered = true })
  :addText({ id = "0", text = "sweetie" })
  :addText({ id = "1", text = "this" })
  :addText({ id = "2", text = "make" })
  :addText({ id = "3", text = "Does" })
  :addText({ id = "4", text = "sense" })
  :addText({ id = "5", text = "?" })

list:setChildrenOrder({
  "3", "1", "2", "4"
}) -- If IDs are missing, they are moved to the end in their relative order before the sort
-- Sorted into -> Does this make sense sweetie ?
```

## See Also
- [Components](../index.md)
- [Component](index.md)