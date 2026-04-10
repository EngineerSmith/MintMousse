---
type:
    name: Accordion
    updates: 1
    children: true
    description: Vertically collapsing list.
---
# Accordion
A vertical collapsing list. Can check out [Bootstrap's docs for an example](https://getbootstrap.com/docs/5.3/components/accordion/).

## Updates
### Children
`title` _string_ (**"Untitled"**)
:   The title to show for the collapsible item

## Example
```lua
-- Within a child component
{
  title = "My first entry",
}

{
  title = "A second entry",
}

-- For example:
local accordion = tab:newAccordion()

accordion:addContainer({
  title = "My first entry",
})

accordion:addContainer({
  title = "A second entry",
})
```

## See Also
- [Bootstrap docs](https://getbootstrap.com/docs/5.3/components/accordion/)