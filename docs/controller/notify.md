# `mintmousse.notify`
Send a notification to all connected clients to see timestamped. It will not appear for new clients.

## Synopsis
```lua
mintmousse.notify( message )
```

## Parameters
`message` _string_ or _table_
:   The message to show, if you pass in a string, it will be set to the table's `text` argument.

### Message Table
`title` _string_
:   String used as the title of the notification.

`text` _string_
:   String used as the text of the notification.

## Returns
Nothing.

## Examples
```lua
mintmousse.notify("A player went out of bounds!")

mintmousse.notify({
  title = "Player Ban",
  text = player:getName() .. " was banned by " .. admin:getName(),
})
```

## See Also
- [Controller](index.md)