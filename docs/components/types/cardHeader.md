---
type:
  name: CardHeader
  updates: 2
  description: Sectioned off header for cards.
---
# Card Header
A header for [Cards](card.md). Can check out [Bootstrap's docs for an example](https://getbootstrap.com/docs/5.3/components/card/#header-and-footer)

## Updates
`text` _string_ (**nil**)
:   The text displayed within the header.

`isTransparent` _boolean_ (**false**)
:   If the element should have a the same background color as the page/card.

## Examples
```lua
{
  text = "I'm a header",
}

{
  text = "Important Section",
  isTransparent = true,
}
```

## See Also
- [Bootstrap docs](https://getbootstrap.com/docs/5.3/components/card/#header-and-footer)
- [Card](card.md)
- [Card Body](cardBody.md)
- [Card Footer](cardFooter.md)
- [Card Subtitle](cardSubtitle.md)
- [Card Text](cardText.md)
- [Card Title](cardTitle.md)