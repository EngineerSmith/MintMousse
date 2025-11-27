local mintmousse = ...

local loggerTab = mintmousse._logger:extend("Components"):extend("Tab")

local tab = { }

tab.onChildCreate = function(_, childComponent)
  if type(childComponent.size) ~= "number" then
    childComponent.size = 2
    return
  end

  local wasSize = childComponent.size
  childComponent.size = math.min(5, math.max(1, childComponent.size))

  if childComponent.size ~= wasSize then
    loggerTab:info("Tab child component[", childComponent.id, "].size required clamping. Changed from", wasSize, "to", childComponent.size)
  end
end

-- todo tab.onChildUpdate = function(_, childComponent, index)
-- or tab.onChildUpdate_size = function(_, childComponent) -- This would better match the javascript side

--[[ on update size:
if index == "size" then
  clamp(size)
end
]]

return tab