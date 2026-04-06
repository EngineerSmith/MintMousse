# `(Component):new<Type>`
Used to create a new Component, and return that new component.

## Synopsis
```lua
newComponent = parentComponent:new<Type>(component)
```

## Parameters
`Type` _string_
:   This is the component type that you want to create.

`component` [_Component_](index.md)
:   The initial values for the component, such as `id`.

## Returns
`newComponent` [_Component_](index.md)
:   The newly created component.

## Examples
```lua
local card = tab:newCard()

local list = card:newList({ id = "myList", isNumbered = true })

list:newContainer()
  :newText({ text = "Hello world" })
    .back
  :newText({ text = "Example" })
```

## See Also
- [Components](../index.md)
- [Component](index.md)
- [`(Component):add<Type>`](add.md)