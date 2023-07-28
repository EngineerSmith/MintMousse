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

component.addBeforeText = function(self, ...)
  self.beforeText = component.new(self, ...)
  return self
end

component.addAfterText = function(self, ...)
  self.afterText = component.new(self, ...)
  return self
end

component._removeParent = function(self)
  if self.children then
    for _, child in ipairs(self.children) do
      if getmetatable(child) == component then
        child:_removeParent()
      end
    end
  end
  if self.beforeText then
    self.beforeText:_removeParent()
  end
  if self.afterText then
    self.afterText:_removeParent()
  end
  self._parent = nil
  setmetatable(self, nil)
end

return component
