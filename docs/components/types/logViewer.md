---
type:
    name: LogViewer
    updates: 1
    pushes: 1
    description: Used to display log messages.
---
# Log Viewer
Used by the console page.

## Updates
`maxLines` _number_ (**25**)
:   The number of lines it should aim to display when viewed in a browser (used to limit height).

## Pushes
`log` _LogTable_
:   Used to send a log message for the viewer to add to itself.

## Examples
```lua
{
  maxLines = 30,
}
```