local tab = {}
tab.__index = tab

local component = requireMintMousse("builder.component")

tab.new = function(name, active)
  return setmetatable({
    name = name,
    active = active,
    components = {}
  }, tab)
end

tab.addComponent = function(self, ...)
  local component = component.new(self, ...)
  table.insert(self.components, component)
  return component
end
tab.addChild = tab.addComponent
tab.addSibling = function()
  errorMintMousse("Builder tab: cannot add sibling to tab, as it is a root node.")
end

return tab
