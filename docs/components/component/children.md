# `(Component):children`
Used to iterate over the locally known children. 

## Synopsis
```lua
itFunc, childList, index = component:children()
```

## Parameters
Nothing.

## Returns
This function returns an iterator that can be used directly like `ipairs`. You shouldn't alter the order of the children directly, and use one of the many `move` helper functions. However, don't call move functions within the loop, as you can break the ordering.

## Examples
```lua
for i, child in component:children() do
  print(i, child.id)
end
```

## See Also
- [Components](../index.md)
- [Component](index.md)