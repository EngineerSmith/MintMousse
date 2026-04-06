# `(Component).parent`
A field of [Component](index.md) that lets you grab the parent component table, if the component knows it's parent.

!!! warning "Type"
    This field can be `nil` in such cases where the local thread doesn't know the parent of this component, or it is a root component of type `Tab`.

## Alias
`(Component).back`
:   This alias is to make chaining functions more readable. But you can still use `.parent` if it's your preference.

## Example
```lua
tab:newCard({ size = 5, title = "Info" })
  :newContainer()
    :addText({ text = "Hello World" })
    :addText({ text = "I like Mousse!" })
    .back
  :newCardBody() -- Call on the `Card` component
    :addCardTitle({ text = "Card Title" })
    :addCardText({ text = "Card Text" })
    :addCardFooter({ text = "Card footer" })
    .parent
  :newContainer()
    :addText({ text = "I really like Mint flavoured Mousse!" })
```

## See Also
- [Components](../index.md)
- [Component](index.md)