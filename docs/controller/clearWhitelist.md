# `mintmousse.clearWhitelist`
Clears all currently added to the whitelist, so you can start fresh.

!!! warning "Active Connections"
    Removing a rule **does not** disconnect clients who are already connected. The whitelist is only checked at the moment a new connection is attempted.

!!! danger "Lockout Risk"
    Calling this function while the server is running will prevent **any** new connections from being established, including those from `localhost`. Ensure you add a new rule immediately after clearing if you intend to keep the console accessible.

## Synopsis
```lua
mintmousse.clearWhitelist()
```

## Parameters
Nothing.

## Returns
Nothing.

## Examples
```lua
mintmousse.clearWhitelist()

mintmousse.addWhitelist("localhost")
```

## See Also
- [Controller](index.md)
- [`mintmousse.removeFromWhitelist`](removeFromWhitelist.md)
- [`mintmousse.addToWhitelist`](addToWhitelist.md)