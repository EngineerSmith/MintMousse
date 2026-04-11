---
type:
    name: Card
    updates: 5
    children: true
    description: Flexible content container.
---
# Card
A flexible content container for all sort of layouts.

## Updates
`color` _BSColor_ (**nil**)
:   Set the color of the background of the card.

`borderColor` _BSColor_ (**nil**)
:   Set the color of the border.

`isContentCenter` _boolean_ (**false**)
:   If the card should center all of it's children.

`title` _string_ (**nil**)
:   A basic [Card Title](cardTitle.md) you can set. Will be hidden if nil.

`text` _string_ (**nil**)
:   A basic [Card text](cardText.md) you can set. Will be hidden if nil.

## Example
```lua
{
  title = "My brand new card",
  text = "And a short message,\nto all my fans!",
}

{
  title = "Card Title",
  text = "Card Text",
  isContentCenter = true,
  color = "primary",
  borderColor = "secondary",
}
```

## See Also
- [Bootstrap docs](https://getbootstrap.com/docs/5.3/components/card/)
- [Card Body](cardBody.md)
- [Card Footer](cardFooter.md)
- [Card Header](cardHeader.md)
- [Card Subtitle](cardSubtitle.md)
- [Card Text](cardText.md)
- [Card Title](cardTitle.md)