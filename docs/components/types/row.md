---
type:
    name: Row
    updates: 1
    children: true
    description: Used to have components next to each other.
---
# Row
A container to have components on the same horizontal row.

## Updates
children.`columnWidth` _number_ or _nil_ (**nil**)
:   A whole number between `1` and `12`, the sum of the row should add up to `12`. If you use `nil`, they will attempt to equalise the width between children. You can freely mix values.

## Examples
```lua
-- Within a child component
{
  columnWidth = 4,
}

-- For example:
local row = card:newRow()

row
  :newContainer({ columnWidth = 4 })
    :addText({ text = "1st" })
    .back
  :newContainer({ columnWidth = 4 })
    :addText({ text = "2nd" })
    .back
  :newContainer({ columnWidth = 4 })
    :addText({ text = "3rd" })
    .back
```