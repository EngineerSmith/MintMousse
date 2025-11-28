local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")
local threadCommunication = require(PATH .. "threadCommunication")
local componentManager
local loggingStack = require(PATH .. "logging.stack")
local contract = require(PATH .. "contract")
local utilID = require(PATH .. "util.id")

local proxyTableLogger = mintmousse._logger:extend("Proxy Table")

local proxyTable = { }
proxyTable.loadComponentManager = function()
  componentManager = require(PATH .. "componentManager")
end

local proxyTableMetatable

local isImmutableIndex = {
  id       = true,
  type     = true,
  creator  = true,
  children = true,
  parentID = true,
}
setmetatable(isImmutableIndex, {
  __index = function(tbl, index)
    if type(index) == "number" then
      return true
    end
    return rawget(tbl, index)
  end
})

local proxyTableNewIndex = function(tbl, index, value)
  if index == "__raw" then return nil end
  loggingStack.push()

  if isImmutableIndex[index] then
    proxyTableLogger:error("You cannot change that index:", tostring(index))
    loggingStack.pop()
    return
  end
  local self = rawget(tbl, "__raw")
  if rawget(self, index) == value then -- attempted to set index to the value it already is
    loggingStack.pop()
    return
  end
  rawset(self, index, value)
  local id = rawget(self, "id")
  local componentType = rawget(self, "type")

  local sendUpdate = componentType == "unknown"
  if not sendUpdate then
    local ct = contract.componentTypes[componentType]
    local updates = ct.updates
    local events = ct.events

    sendUpdate = type(updates) == "table" and updates[index] ~= nil
    if not sendUpdate and type(events) == "table" and type(index) == "string" then
      local eventName = index:match(mintmousse.COMPONENT_EVENT_FIELD_MATCH)
      sendUpdate = type(eventName) == "string" and events[eventName] == true
    end
  end

  if sendUpdate then
    threadCommunication.push({
      func = "updateComponent",
      id, index, value,
    })
  end

  -- check if parent requires the update
  local parentID = rawget(self, "parentID")
  if not parentID then
    loggingStack.pop()
    return
  end

  local parentComponentType = mintmousse.get(parentID).type
  local sendChildUpdate = parentComponentType == "unknown"
  if not sendChildUpdate then
    local childUpdates = contract.componentTypes[parentComponentType].childUpdates
    sendChildUpdate = type(childUpdates) == "table" and childUpdates[index] ~= nil
  end

  if sendChildUpdate then
    threadCommunication.push({
      func = "updateParentComponent",
      parentID, id, index, value,
    })
  end

  loggingStack.pop()
end

local proxyTableNew = function(parent, component, index)
  local parentID = rawget(parent, "__raw").id
  return componentManager.addComponent(component, parentID, index)
end

local proxyTableAdd = function(parent, component, index)
  local parentID = rawget(parent, "__raw").id
  componentManager.addComponent(component, parentID, index)
  return parent
end

local proxyTableRemoveSelf = function(tbl)
  local id = rawget(tbl, "__raw").id
  return componentManager.removeComponent(id)
end

local proxyTableMarkRemoved = function(tbl)
  local self = rawget(tbl, "__raw")
  self.removed = true -- todo change metatable to "removed" metatable
  -- This metatable should error on any index, or newIndex call
end

local validateSwapArg = function(val, argName)
  local t = type(val)
  if t == "number" then
    if val < 1 then
      return false, argName .. " cannot be less than 1."
    end
    return true
  elseif t == "string" then
    local success, errorMessage = utilID.isValidID(val)
    if not success then
      return false, argName .. " is an invalid ID. Reason: " .. errorMessage
    end
    return true
  end
  return false, argName .. " must be a type String (id), or Number (index)"
end

local proxyTableSwap = function(tbl, indexA, indexB)
  loggingStack.push()
  local okA, errA = validateSwapArg(indexA, "IndexA")
  if not okA then
    proxyTableLogger:warning("Swap failed:", errA)
    loggingStack.pop()
    return tbl
  end

  local okB, errB = validateSwapArg(indexB, "IndexB")
  if not okB then
    proxyTableLogger:warning("Swap failed:", errB)
    loggingStack.pop()
    return tbl
  end

  local id = rawget(tbl, "__raw").id
  threadCommunication.push({
    func = "swapChildren",
    id, indexA, indexB,
  })
  loggingStack.pop()
  return tbl
end

local proxyTableReorder = function(tbl, newOrderArray)
  loggingStack.push()
  if type(newOrderArray) ~= "table" then
    proxyTableLogger:warning("Reorder failed:", "NewOrderArray must be type Table")
    loggingStack.pop()
    return tbl
  end
  for index, value in ipairs(newOrderArray) do
    local ok, err = validateSwapArg(value, "newOrderArray["..index.."]")
    if not ok then
      proxyTable:warning("Reorder failed:", err)
      loggingStack.pop()
      return tbl
    end
  end

  local id = rawget(tbl, "__raw").id
  threadCommunication.push({
    func = "reorderChildren",
    id, newOrderArray,
  })
  loggingStack.pop()
  return tbl
end

local childrenMetatable
childrenMetatable = {
  __index = function(tbl, index)
    if index == "length" or index == "len" then
      return childrenMetatable.__len(tbl)
    end
    if type(index) ~= "number" then
      return nil
    end
    local self = rawget(tbl, "__raw")
    return self[index]
  end,
  __newindex = function(tbl, index, value)
    loggingStack.push()
    proxyTableLogger:error("You cannot change that index:", tostring(index), ". Children are readonly.")
    loggingStack.pop()
    return
  end,
  __len = function(tbl)
    local self = rawget(tbl, "__raw")
    return #self
  end,
}

local proxyTableGetChildren = function(raw)
  return setmetatable({
    __raw = raw,
  }, childrenMetatable)
end

local cachedCreationMethods = {
  new = { },
  add = { }
}

local getNewMethod = function(componentType)
  local cachedNewMethods = cachedCreationMethods["new"]
  if not cachedNewMethods[componentType] then
    cachedNewMethods[componentType] = function(tbl, component)
      component = component or { }
      component.type = componentType
      return proxyTableNew(tbl, component)
    end
  end
  return cachedNewMethods[componentType]
end

local getAddMethod = function(componentType)
  local cachedAddMethods = cachedCreationMethods["add"]
  if not cachedAddMethods[componentType] then
    cachedAddMethods[componentType] = function(tbl, component)
      component = component or { }
      component.type = componentType
      return proxyTableAdd(tbl, component)
    end
  end
  return cachedAddMethods[componentType]
end

local knownIndices
knownIndices = {
  parent = function(self, _)
    return mintmousse.get(self.parentID)
  end,
  back = function(...)
    return knownIndices["parent"](...)
  end,
  remove = function(_, _)
    return proxyTableRemoveSelf
  end,
  _markRemoved = function(_, _)
    return proxyTableMarkRemoved
  end,
  type = function(self, _)
    return self.type or "unknown"
  end,
  children = function(self, _)
    if not self.children then
      self.children = proxyTableGetChildren(self)
    end
    return self.children
  end,
  new = function(_, _)
    return proxyTableNew
  end,
  add = function(_, _)
    return proxyTableAdd
  end,
  swap = function(_, _)
    return proxyTableSwap
  end,
  reorder = function(_, _)
    return proxyTableReorder
  end,
  length = function(_, tbl)
    return proxyTableMetatable.__len(tbl)
  end,
  len = function(...)
    return knownIndices["length"](...)
  end,
}

local proxyTableIndex = function(tbl, index)
  if index == "__raw" then return nil end
  loggingStack.push()

  local result = nil
  local self = rawget(tbl, "__raw")

  -- Check fixed keys
  local handler = knownIndices[index]
  if handler then
    loggingStack.push()
    result = handler(self, tbl)
    loggingStack.pop()
  
  -- Check numeric keys for children
  elseif type(index) == "number" then
    result = self[index]

  -- Check dynamic keys
  elseif type(index) == "string" and #index > 3 then
    local sub = index:sub(1, 3):lower()
    local componentType = index:sub(4)
    -- ComponentType name must be in camelCase
    componentType = componentType:gsub("^(.)", function(c) return c:lower() end, 1)

    if sub == "new" then
      result = getNewMethod(componentType)
    elseif sub == "add" then
      result = getAddMethod(componentType)
    end
  end

  -- 4. Fallback
  if result == nil then
    result = rawget(self, index)
  end

  loggingStack.pop()
  return result
end

local proxyTableLen = function(tbl)
  local self = rawget(tbl, "__raw")
  return #self
end

proxyTableMetatable = {
  __newindex = proxyTableNewIndex,
  __index = proxyTableIndex,
  __len = proxyTableLen,
}

proxyTable.createProxyTable = function(raw)
  setmetatable(raw, nil)
  return setmetatable({ __raw = raw }, proxyTableMetatable)
end

return proxyTable