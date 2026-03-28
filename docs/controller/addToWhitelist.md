# `mintmousse.addToWhitelist`
Used to add new rules to the whitelist. The whitelist is always enforced and cannot be turned off. Use this to grant specific IP addresses or network ranges access to the web console.

|Rule Type|Example|Logic|
|---|---|---|
|Loopback Aliases|`"localhost"`|Automatically whitelist both `127.0.0.1` and `::1`|
|IPv4 Host|`"198.168.1.5"`|Matches a single specific IPv4 address|
|IPv6 Host|`"2001:db8::cafe"`|Matches a single specific IPv6 address (supports compression)|
|IPv4 Range|`"10.0.0.0/8"`|Standard CIDR notation for IPv4 subnets|
|IPv6 Range|`"2001:db8::/32"`|Standard CIDR notation for IPv6 subnets|
|IPv4-Mapped|`"::ffff:172.16.0.1"`|Supports IPv4 addresses wrapped in IPv6 for tunneled traffic|

!!! info "Pro-active Protection
    With no whitelist entries, no connections will be accepted. It is highly recommended to at least include `"localhost"` during development.

## Synopsis
```lua
mintmousse.addToWhitelist( additions )
```

## Parameters
`additions` _string_ or _table_ (**nil**)
:   The rule(s) you want to add.
    * If a _string_ is passed, it is treated as a single rule.
    * If a _table_ is passed, it must be a continuous array of strings.


### Rule Definitions
A rule can be one of the following:
- Aliases: `"localhost"`, `"local"`, `"127.0.0.1"`, or `"::1"`. All four strings perform the same action: whitelisting the IPv4 and IPv6 loopback addresses.
- IPv4 Address: A standard dot-decimal address (e.g. `"192.168.4.27"`)
- IPv6 Address: A standard colon-separated hex address. Supports compression (e.g. `"2001:db8::cafe"`)
- IPv4 CIDR: An IPv4 range (e.g. `"192.168.0.0/16"`)
- IPv6 CIDR: An IPv6 range (e.g. `"2001:db8::/32"`)
- IPv4-mapped IPv6: An IPv4 address expressed in IPv6 format (e.g. `"::ffff:172.16.0.1"`)

## Returns
Nothing.

## Examples
```lua
mintmousse.addToWhitelist("localhost")

mintmousse.addToWhitelist({
  "local",
  "10.0.0.0/8",
})

mintmousse.addToWhitelist({
  "localhost",         -- Covers loopback for v4 and v6
  "192.168.4.27",      -- Specific IPv4 address
  "192.168.0.0/16",    -- IPv4 subnet
  "2001:db8::/32",     -- IPv6 subnet
  "2001:db8::cafe",    -- Single IPv6 Host
  "::ffff:127.16.0.1", -- IPv4-mapped IPv6 support
})
```

## See Also
- [Controller](index.md)
- [`mintmousse.start`](start.md)
- [`mintmousse.removeFromWhitelist](removeFromWhitelist.md)