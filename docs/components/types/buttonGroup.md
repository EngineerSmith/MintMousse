---
type:
    name: ButtonGroup
    children: true
    description: A row container for buttons.
---
# Button Group
A row of buttons graphically stacked next to each other.  Can check out [Bootstrap's docs for an example](https://getbootstrap.com/docs/5.3/components/button-group/).

## Example
```lua
local btnGrp = tab:newButtonGroup()

btnGrp:addButton({ text = "1st", onEventClick = "Press" })
btnGrp:addButton({ text = "2nd", onEventClick = "Press" })
btnGrp:addButton({ text = "3rd", onEventClick = "Other" })

mintmousse.onEvent("Press", function(component)
  if component.text == "1st" then print("YA HOO!")
  elseif component.text == "2nd" then print("This is professional")
  end
end)
```

## See Also
- [Bootstrap docs](https://getbootstrap.com/docs/5.3/components/button-group/)