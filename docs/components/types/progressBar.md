---
type:
    name: ProgressBar
    updates: 5
    description: Used to show progress.
---
# Progress Bar
Used to show progress visually.

## Updates
`percentage` _number_ (**0.0**)
:   A value between `0.0` and `1.0`

`showLabel` _boolean_ (**false**)
:   Adds the percentage as text to the progress bar

`ariaLabel` _string_ (**nil**)
:   A value to set the aria label (used for accessibility/screen readers)

`isStriped` _boolean_ (**false**)
:   If the progress bar should have a stripped animation added to it.

`color` _BSColor_ (**nil**)
:   The color of the progress bar

## Examples
```lua
{
  percentage = 0.0,
  showLabel = true,
  color = "success",
}

local p = 0.33
{
  percentage = p,
  showLabel = true,
  ariaLabel = "Battle Royal map progress",
  isStripped = isCircleShrinking(),
  color = p < 0.7 and "success" or p < 0.9 and "warning" else "error",
}
```

## See Also
- [Bootstrap docs](https://getbootstrap.com/docs/5.3/components/progress/)