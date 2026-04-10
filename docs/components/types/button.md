---
type:
    name: Button
    updates: 6
    events: 1
    children: false
    description: A button which triggers an event.
---
# Button
A button component! Used to call a callback on the love client.

## Updates
`color` _BSColor_ (**"primary"**)
:   A bootstrap color for the entire button.

`colorOutline` _boolean_ (**false**)
:   If the button should be outlined instead of solid fill.

`text` _string_ (**""**)
:   Text the button displays

`isDisabled` _boolean_ (**false**)
:   If the button should be disabled (faded out, unable to be pressed).

`width` _BSWidth_ (**"100"**)
:   The percentage width the button takes up. Text wraps downward.

`isCentered` _boolean` (**true**)
:   Centers the button 

## Events
`onEventClick` _callbackID_
:   The callback ID to trigger. See [`mintmousse.onEvent`](../onEvent.md).

## Examples
```lua
{
  text = "Press me!",
  color = "secondary",
  onEventClick = "myButtonCallback",
}

{
  text = "My fancy button!",
  color = "warning",
  colorOutline = true,
  width = "50",
  isCentered = true,
  onEventClick = "myButtonCallback,
}
```

## See Also
- [Button Group](buttonGroup.md)