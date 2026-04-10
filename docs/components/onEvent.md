# `mintmousse.onEvent`
Used to assign callback functions to callback IDs.

!!! warning "Thread behaviour"

    This function can only be called on the main thread. Thus, all events are piped back to the main thread with a snapshot of the component if it doesn't exist on the main thread allowing you to make general changes, or get values - but it won't update the thread the component was originally created on with any changes you make to this temp object.

## Synopsis
```lua
mintmousse.onEvent( callbackID, callbackFunction )
```

## Parameters
`callbackID` _string_
:   The ID used to direct events

`callbackFunction` _function_
:   The function called when an event occurs for a specific callbackID

## Returns
Nothing.

## Examples
```lua
mintmousse.onEvent("myButtonEvent", function(component)
  component.text = component.text .. "!"
  if component.type == "Button" then
    component.color = component.color == "primary" and "secondary" or "primary"
  end
end)

mintmousse.onEvent("myImportEvent", function(component)
  print(component.id .. " triggered an important event!")
end)
```

## See Also
- [`mintmousse.removeEvent`](removeEvent.md)