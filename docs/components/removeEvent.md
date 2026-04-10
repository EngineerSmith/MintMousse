# `mintmousse.removeEvent`
Used ot removed any functions assigned to a given callback ID.

!!! warning "Thread behaviour"

    This function can only be called on the main thread. As no callback details are kept on individual threads.

## Synopsis
```lua
mintmousse.removeEvent( callbackID )
```

## Parameters
`callbackID` _string_
:   The ID to clear any assigned function from.

## Returns
Nothing.

## Examples
```lua
mintmousse.removeEvent("myButtonEvent")
```

## See Also
- [`mintmousse.onEvent`](onEvent.md)