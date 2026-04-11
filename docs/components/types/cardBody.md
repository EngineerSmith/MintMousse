---
type:
    name: CardBody
    children: true
    description: A contained for inside a Card.
---
# Card Body
A container for inside a [Card](card.md). Realistically, all this achieves is adding padding to it's children. Can check out [Bootstrap's docs for an example](https://getbootstrap.com/docs/5.3/components/card/#body)

## Examples
```lua
local cardBody = card:newCardBody()

cardBody
  :addCardTitle({ text = "Title" })
  :addCardSubtitle({ text = "Subtitle" })
  :addCardText({ text = "Some card text! Very important information." })
  :addCardFooter({ text = "9 weeks ago" })
```

## See Also
- [Bootstrap docs](https://getbootstrap.com/docs/5.3/components/card/#body)
- [Card](card.md)
- [Card Footer](cardFooter.md)
- [Card Header](cardHeader.md)
- [Card Subtitle](cardSubtitle.md)
- [Card Text](cardText.md)
- [Card Title](cardTitle.md)