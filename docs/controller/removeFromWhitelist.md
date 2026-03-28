# `mintmousse.removeFromWhitelist`
Removes the given rules from the whitelist.

!!! warning "Active Connections"
    Removing a rule **does not** disconnect clients who are already connected. The whitelist is only checked at the moment a new connection is attempted.

## Synopsis
```lua
mintmousse.removeFromWhitelist( removals )
```

## Parameters
`removals` _string_ or _table_ (**nil**)
:   The rule(s) you want to remove.
    * If a _string_ is passed, it is treated as a single rule.
    * If a _table_ is passed, it must be a continuous array of strings.

### Rule Matching
To successfully remove a rule, the string must exactly match the format used when it was added (e.g. if you add a CIDR range, you must provide the same CIDR range to remove it).

Note, removing `"localhost"`, `"local"`, `"127.0.0.1"`, or `"::1"` will remove both the IPv4 and IPv6 loopback entries simultaneously.

## Returns
Nothing.

## Examples
```lua
mintmousse.removeFromWhitelist("192.167.4.27")

mintmousse.removeFromWhitelist({
  "localhost",
  "10.0.0.0/8",
})

```

## See Also
- [Controller](index.md)
- [`mintmousse.addToWhitelist`](addToWhitelist.md)