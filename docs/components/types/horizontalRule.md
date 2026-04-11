---
type:
    name: HorizontalRule
    updates: 2
    description: Add a line to split up content
---
# Horizontal Rule
Add a horizontal line to split up elements. Like how you would use `---` within markdown. Can check out [Bootstrap's docs for an example](https://getbootstrap.com/docs/5.3/content/reboot/#horizontal-rules).

## Updates
`color` _BSColor_ (**nil**)
:   If you want a particular color for the horizontal rule.

`margin` _BSMargin_ (**nil**)
:   Add a margin (space above, and below) the line.

## Examples
```lua
{ }

{
  color = "danger",
  margin = 5,
}

{
  color = "primary",
  margin = 1, 
}
```

## See Also
- [Bootstrap docs](https://getbootstrap.com/docs/5.3/content/reboot/#horizontal-rules)