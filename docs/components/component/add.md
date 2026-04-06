# `(Component):add<Type>`
Used to create a new component, but returns the parent component so it can be chained. 

## Synopsis
```lua
parentComponent = parentComponent:add<Type>(component)
```

## Parameters
`Type` _string_
:   This is the component type

`component` [_Component_](index.md)
:   The initial values for the component, such as `id`.

## Returns
`parentComponent` [_Component_](index.md)
:   Returns the caller table, so it can be chained

## Examples
```lua
local list = tab:newList()
  :addText({ text = "My awesome List" })
  :addAlert({ text = "We can add siblings easily!" })
  :newContainer()
    :newCardBody()
      :addCardTitle({ text = "Card title" })
      :addCardText({ text = "Card Text" })
      :addCardFooter({ text = "Card Text" })
      .back
    .back
  :addText({ text = "The bottom of the list" })
```

## See Also
- [Components](../index.md)
- [Component](index.md)
- [`(Component):new<Type>`](new.md)