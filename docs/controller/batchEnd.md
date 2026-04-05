# `mintmousse.batchEnd`
Used to end batching changes into a single thread message. This function also processes all the current batched messages, and could take a moment to process on large amount of changes (but overall takes less time than individual changes).

See [`mintmousse.batchStart`] to start a batch.

## Synopsis
```lua
mintmousse.batchEnd()
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
- [`mintmousse.batchEnd](batchEnd.md)