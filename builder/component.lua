local component = {}
component.__index = component

component.new = function(parent, componentType, id, settings)
  if type(id) == "table" then
    settings = id
    id = nil
  end

  settings = settings or { }
  settings._parent = parent
  settings.type = settings.type or componentType
  settings.id = settings.id or id
  return setmetatable(settings, component)
end

component.addChild = function(self, type, id, settings)
  if not self.children then
    self.children = {}
  end
  local child = component.new(self, type, id, settings)
  table.insert(self.children, child)
  return child
end

component.addChildRaw = function(self, component, ...)
  if not component then
    return
  end
  if not self.children then
    self.children = {}
  end
  table.insert(self.children, component)
  self:addChildRaw(...)
  return self
end

component.addSibling = function(self, ...)
  return self._parent:addChild(...)
end

component.addSiblingRaw = function(self, ...)
  return self._parent:addChildRaw(...)
end

component._removeParent = function(self)
  if self.children then
    for _, child in ipairs(self.children) do
      if getmetatable(child) == component then
        child:_removeParent()
      end
    end
  end
  self._parent = nil
  setmetatable(self, nil)
end

return component
