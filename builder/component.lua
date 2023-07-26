local component = {}
component.__index = component

component.new = function(parent, type, id, settings)
  settings = settings or { }
  settings._parent = parent
  settings.type = settings.type or type
  settings.id = settings.id or id
  return setmetatable(settings, component)
end

component.addChild = function(self, type, id, settings)
  if type(id) == "table" then
    settings = id
    id = nil
  end
  if not self.children then
    self.children = {}
  end
  table.insert(self.children, component.new(self, type, id, settings))
end

component.addChildRaw = function(self, component, ...)
  if not component then
    return
  end
  if not self.children then
    self.children = {}
  end
  table.insert(self.children, component)
end

component.addSibling = function(self, ...)
  self._parent:addChild(...)
end

component.addSiblingRaw = function(self, ...)
  self._parent:addChildRaw(...)
end

component._removeParent = function(self)
  if self.children then
    for _, child in ipairs(self.children) do
      child:_removeParent()
    end
  end
  self._parent = nil
  setmetatable(self, nil)
end

return component
