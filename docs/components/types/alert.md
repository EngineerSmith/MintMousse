---
type:
    name: Alert
    updates: 3
    description: A brightly colored message.
---
# Alert
A brightly colored message that can be dismissed within browsers. Useful for getting eye catching information across. Can check out [Bootstrap's docs for an example](https://getbootstrap.com/docs/5.3/components/alerts/).

## Updates
`text` _string_ (**"UNKNOWN"**)
:   The text for the alert to display.

`color` _BSColor_ (**"warning"**)
:   The outline, and background color of the message.

`isDismissible` _boolean_ (**true**)
:   If the message can be dismissed locally in a browser. This doesn't remove the alert from the page, it just hides it for the user. It will reappear on refresh.

## Examples
```lua
{
  text = "Hello world!",
  color = "primary",
}

{
  text = "Oh no! Something went terribly wrong!",
  color = "danger",
  isDismissible = true,
}
```

## See Also
- [Bootstrap docs](https://getbootstrap.com/docs/5.3/components/alerts/)