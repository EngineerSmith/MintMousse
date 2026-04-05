# `mintmousse.batchStart`
Used to batch huge amount of changes into a single thread message. Useful for when first constructing an entire tab.

## Synopsis
```lua
mintmousse.batchStart()
```

## Parameters
Nothing.

## Returns
Nothing.

## Examples
```lua
mintmousse.batchStart()

local tab = mintmousse.newTab("Dashboard")
local list = tab:newCard({ title = "Players" }):newList()
for _, player in ipairs(server.connectedPlayers) do
  list:newContainer({ id = "dashboardList_" .. player.username })
    :addCardTitle(player.username)
    :newRow()
      :newContainer({ columnWidth = 4 }):newRow()
        :addText({ text = "Health" })
        :addText({ text = player.health })
      .back
      :newContainer({ columnWidth = 4 }):newRow()
        :addText({ text = "Mana" })
        :addText({ text = player.mana })
      .back.back
      :newContainer({ columnWidth = 4 }):newRow()
        :addText({ text = "Kills" })
        :addText({ text = player.kills })
end

mintmousse.batchEnd()
```

## See Also
- [Controller](index.md)
- [`mintmousse.batchEnd`](batchEnd.md)