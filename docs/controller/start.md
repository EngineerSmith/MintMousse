# `mintmousse.start`
Used to start the web console's server so it can start serving clients.

Can only be called on the main thread.

## Synopsis
```lua
mintmousse.start( config )
```

## Parameters
`config` _table_ (**nil**)
:   A table of config values to use on startup.

### Config Table
`title` _string_
:   The title to use for the web console. Also see [`mintmousse.setTitle`](setTitle.md).

`host` _string_
:   The host to bind the server to. If nil, default it is `::` which tries to bind to IPv6 and IPv4, and fallbacks to `*` which tries to bind just to IPv4. See [`tcp:bind`](https://lunarmodules.github.io/luasocket/tcp.html#bind) for documentation on host.

`port` _number_
:   The whole number port the server will be reachable on. If nil, default behaviour is to start at `8080` and will increment until it finds a port it can bind to.

`autoIncrement` _boolean_
:   If a `port` is given, if the server should try to increment the given port until it find ones. Default disabled.

`whitelist` _string_ or _table_
:   A single rule, or an array of rules. See [`mintmousse.addToWhitelist`](addToWhitelist.md) for details.

## Returns
Nothing.

## Examples
```lua
mintmousse.start({ whitelist = "localhost" }) -- Quickstart

mintmousse.start({ -- Default
  title = "MintMousse",
  host = nil,
  port = nil,
  autoIncrement = false,
  whitelist = nil, -- Note, with no whitelist, no connections will be accepted
})

mintmousse.start({
  title = love.window.getTitle() .. " Console",
  host = "::",
  port = 80,
  autoIncrement = false,
  whitelist = {
    "localhost",         -- Covers "local", "127.0.0.1", and "::1"
    "192.168.4.27",      -- Specific IPv4 address
    "192.168.0.0/16",    -- Private IPv4 Range (CIDR)
    "10.0.0.0/8",        -- Large Private IPv4 Range
    "2001:db8::/32",     -- IPv6 Range CIDR
    "2001:db8::cafe",    -- Single IPv6 Host
    "::ffff:127.16.0.1", -- IPv4-mapped IPv6 address support
  },
})
```

## See Also
- [Controller](index.md)
- [`mintmousse.addToWhitelist`](addToWhitelist.md)