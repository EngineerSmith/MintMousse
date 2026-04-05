# `mintmousse.getThreadID`
Get the unique ID for the current thread.

## Synopsis
```lua
threadID = mintmousse.getThreadID()
```

## Parameters
Nothing.

## Returns
`threadID` _string_
:   The threadID assigned to the current thread.

## Examples
```lua
local threadID = mintmousse.getThreadID()
print("Hello from " .. threadID)
```

## See Also
- [Controller](index.md)