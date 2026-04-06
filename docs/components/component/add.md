# `(Component):add<Type>`
Used to create a new component, but returns the parent component so it can be chained. 

-- TODO explain `<Type>`

## Synopsis
```lua
parentComponent = parentComponent:add<Type>(component)
```

## Parameters
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