local builder = {}
builder.__index = builder

local tab = requireMintMousse("builder.tab")

builder.new = function(title, icon)
  return setmetatable({
    title = title,
    icon = icon,
    tabs = {}
  }, builder)
end

builder.addTab = function(self, name, index, active)
  local tab = tab.new(name, active)
  if index then
    table.insert(self.tabs, index, tab)
  else
    table.insert(self.tabs, tab)
  end
  return tab
end

--[[destructive function]]
builder._build = function(self)
  for _, tab in ipairs(self.tabs) do
    if tab.components then
      for _, component in ipairs(tab.components) do
        component:_removeParent()
      end
    end
    setmetatable(tab, nil)
  end
  return setmetatable(self, nil)
end

return builder
