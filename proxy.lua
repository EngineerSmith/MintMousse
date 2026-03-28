local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse       = require(PATH .. "conf")
local threadCommand    = require(PATH .. "threadCommand")
local componentLogic   = require(PATH .. "componentLogic")
local contract         = require(PATH .. "contract")
local utilID           = require(PATH .. "util.id")
local loggingStack     = require(PATH .. "logging.stack")

local log = mintmousse._logger:extend("Proxy")

local proxy = {
  proxyComponents = { },
  localChildren   = { },
}

local protectedStatic = {
  -- variables
  id               = true,
  type             = true,
  parentID         = true,
  children         = true, -- variable used on MM thread
  -- functions
  parent           = true,
  back             = true,
  remove           = true,
  setChildrenOrder = true,
  moveBefore       = true,
  moveAfter        = true,
  moveToFront      = true,
  moveToBack       = true,
  children         = true,
  isDead           = true,
}

local keyProtectionCache = { }
local isProtectedKey = function(k)
  if keyProtectionCache[k] ~= nil then return keyProtectionCache[k] end
  local result = false
  if type(k) == "number" then result = true
  elseif protectedStatic[k] then result = true
  elseif type(k) ~= "string" then result = false
  elseif k == "new" or k == "add" then result = true
  elseif #k >= 4 then
    local s = k:sub(1,3):lower()
    if s == "new" or s == "add" then
      result = true
    end
  end
  keyProtectionCache[k] = result
  return result
end

local needsComponentUpdate = function(compType, key)
  if compType == "unknown" then return true end
  local ct = contract.componentTypes[compType]
  if type(ct.updates) == "table" and ct.updates[key] then return true end
  if type(key) == "string" and ct.events then
    local event = key:match("^onEvent(.+)")
    if event and ct.events[event] then return true end
  end
  return false
end

local needsChildUpdate = function(parentType, key)
  if parentType == "unknown" then return true end
  local ct = contract.componentTypes[parentType]
  return type(ct.childUpdates) == "table" and ct.childUpdates[key]
end

local needsComponentPush = function(compType, key)
  if compType == "unknown" then return true end
  local ct = contract.componentTypes[compType]
  if type(ct.pushes) == "table" and ct.pushes[key] then return true end
  return false
end

local funcKeys = {
  parent = function(raw)
    loggingStack.push()
    local v = proxy.get(raw.parentID)
    loggingStack.pop()
    return v
  end,
  back = function(raw) -- Alias for parent
    loggingStack.push()
    local v = proxy.get(raw.parentID)
    loggingStack.pop()
    return v
  end,

  remove           = function(_) return proxy.removeSelf       end,
  setChildrenOrder = function(_) return proxy.setChildrenOrder end,
  moveBefore       = function(_) return proxy.moveBefore       end,
  moveAfter        = function(_) return proxy.moveAfter        end,
  moveToFront      = function(_) return proxy.moveToFront      end,
  moveToBack       = function(_) return proxy.moveToBack       end,
  children         = function(_) return proxy.childrenIterator end,

  type = function(raw) return raw.type or "unknown" end, -- alias for type
  isDead = function(_) return false end, -- can't be dead if it has this metafunction
}

local proxyNewIndex = function(proxyTbl, key, value)
  if key == "__raw" then return end
  loggingStack.push()

  if isProtectedKey(key) then
    log:error("Cannot change immutable key:", key)
    loggingStack.pop()
    return
  end

  local raw = rawget(proxyTbl, "__raw")
  if raw[key] == value then
    loggingStack.pop()
    return
  end

  local id       = raw.id
  local compType = raw.type or "unknown"
  local parentID = raw.parentID

  if needsComponentUpdate(compType, key) then
    threadCommand.call("updateComponent", { id = id, index = key, value = value })
  elseif needsComponentPush(compType, key) then
    threadCommand.call("pushComponent", { id = id, index = key, value = value })
    loggingStack.pop()
    return
  elseif parentID then
    local parentType = proxy.get(parentID).type
    if needsChildUpdate(parentType, key) then
      threadCommand.call("updateComponent", { id = id, index = key, value = value })
    end
  end

  rawset(raw, key, value)

  loggingStack.pop()
end

local creationCache = { }
local proxyIndex = function(proxyTbl, key)
  if key == "__raw" then return nil end
  loggingStack.push()

  local raw = rawget(proxyTbl, "__raw")
  local handler = funcKeys[key]
  local result
  if handler then
    loggingStack.pop()
    return handler(raw)
  elseif type(key) == "string" and #key >= 4 then
    if not creationCache[key] then
      local prefix = key:sub(1, 3):lower()
      local typ    = key:sub(4)
      if prefix == "new" then
        creationCache[key] = function(parentProxy, component)
          loggingStack.push()
          component = component or { }
          component.type = typ
          local childProxy = proxy._addComponent(component, parentProxy)
          loggingStack.pop()
          return childProxy
        end
      elseif prefix == "add" then
        creationCache[key] = function(parentProxy, component)
          loggingStack.push()
          component = component or { }
          component.type = typ
          proxy._addComponent(component, parentProxy)
          loggingStack.pop()
          return parentProxy
        end
      end
    end
    if creationCache[key] ~= nil then
      loggingStack.pop()
      return creationCache[key]
    end
  end
  -- else
  loggingStack.pop()
  return rawget(raw, key)
end

local proxyMetatable = {
  __index    = proxyIndex,
  __newindex = proxyNewIndex,
}

proxy.childrenIterator = function(proxyTbl)
  local parentID = proxyTbl.parentID
  local list = parentID and proxy.localChildren[parentID] or { }
  return ipairs(list)
end

proxy._registerLocalChild = function(parentID, childProxy)
  if not proxy.localChildren[parentID] then
    proxy.localChildren[parentID] = { }
  end
  table.insert(proxy.localChildren[parentID], childProxy)
end

proxy._unregisterLocalChild = function(parentID, childID)
  local list = proxy.localChildren[parentID]
  if not list then return end
  for i = #list, 1, -1 do
    if list[i].id == childID then
      table.remove(list, i)
      break
    end
  end
  if #list == 0 then
    proxy.localChildren[parentID] = nil
  end
end

local removedMT = {
  __newindex = function(tbl, key, value)
    loggingStack.push()
    log:warning("Component has been removed (attempted to write key:", key, ")")
    loggingStack.pop()
  end,
  __index = function(tbl, key)
    if key == "isDead" then return true end
    loggingStack.push()
    log:warning("Component has been removed (attempted to read key:", key, ")")
    loggingStack.pop()
    return nil
  end,
}

local removeProxyFromLocal
removeProxyFromLocal = function(component)
  local id = component.id
  local list = proxy.localChildren[id]
  if list then
    for _, child in ipairs(list) do
      removeProxyFromLocal(child)
    end
  end

  proxy.localChildren[id], proxy.proxyComponents[id] = nil, nil
  setmetatable(component, removedMT)
end

proxy.removeSelf = function(tbl)
  loggingStack.push()
  local raw = rawget(tbl, "__raw")
  local id = raw.id

  if proxy.proxyComponents[id] then
    proxy._unregisterLocalChild(raw.parentID, id)
    removeProxyFromLocal(tbl)
  end

  threadCommand.call("removeComponent", { id = id })
  loggingStack.pop()
end

proxy.setChildrenOrder = function(tbl, newOrder)
  loggingStack.push()
  if type(newOrder) ~= "table" then
    log:warning("setChildrenOrder: newOrder must be a table of IDs")
    loggingStack.pop()
    return tbl
  end

  local raw = rawget(tbl, "__raw")
  if raw.parentID and proxy.localChildren[raw.parentID] then
    local list = proxy.localChildren[raw.parentID]
    
    local orderedIDs = { }
    local seen = { }
    for _, id in ipairs(newOrder) do
      table.insert(orderedIDs, id)
      seen[id] = true
    end
    for _, p in ipairs(list) do
      if not seen[p.id] then
        table.insert(orderedIDs, p.id)
      end
    end

    local newList = { }
    for _, id in ipairs(orderedIDs) do
      local found = false
      for _, p in ipairs(list) do
        if p.id == id then
          table.insert(newList, p)
          found = true
          break
        end
      end
      if not found then
        -- Assume sibling is of parent, try to find it, otherwise assume it is a component created by another thread
        local p = proxy.get(id)
        local pRaw = rawget(p, "__raw")
        if not pRaw.parentID then
          rawset(pRaw, "parentID", raw.parentID)
        end
        if pRaw.parentID == raw.parentID then
          table.insert(newList, p)
        else
          log:warning("newOrder: Tried to 'reparent' component!",
            "Gave ID that wasn't a child of this component. Gave:", id,
            ". Actual Parent:", pRaw.parentID, ". Tried to assign to:", raw.parentID)
        end
      end
    end

    proxy.localChildren[raw.parentID] = newList
  end

  threadCommand.call("setChildrenOrder", {
    id = raw.id,
    newOrder = newOrder,
  })
  loggingStack.pop()
  return tbl
end

proxy.moveBefore = function(tbl, siblingID)
  loggingStack.push()
  if type(siblingID) == "table" then siblingID = siblingID.id end
  if type(siblingID) ~= "string" then
    log:warning("moveBefore: siblingID must be type string or component proxy")
    loggingStack.pop()
    return tbl
  end
  local success, reason = utilID.isValidID(siblingID)
  if not success then
    log:warning("moveBefore: siblingID has invalid ID:", reason)
    loggingStack.pop()
    return tbl
  end

  local raw = rawget(tbl, "__raw")
  if raw.id == siblingID then
    loggingStack.pop()
    return tbl -- trying to move the child to the child?
  end

  if raw.parentID and proxy.localChildren[raw.parentID] then
    local list = proxy.localChildren[raw.parentID]

    local childIndex, siblingIndex
    for i, p in ipairs(list) do
      if p.id == raw.id then childIndex = i end
      if p.id == siblingID then siblingIndex = i end
      if childIndex and siblingIndex then break end
    end
    if childIndex and siblingIndex and childIndex ~= siblingIndex then
      local childProxy = table.remove(list, childIndex)
      if childIndex < siblingIndex then siblingIndex = siblingIndex - 1 end
      table.insert(list, siblingIndex, childProxy)
    end
  end

  threadCommand.call("moveBefore", {
    id = raw.id,
    siblingID = siblingID,
  })
  loggingStack.pop()
  return tbl
end

proxy.moveAfter = function(tbl, siblingID)
  loggingStack.push()
  if type(siblingID) == "table" then siblingID = siblingID.id end
  if type(siblingID) ~= "string" then
    log:warning("moveAfter: siblingID must be type string or component proxy")
    loggingStack.pop()
    return tbl
  end
  local success, reason = utilID.isValidID(siblingID)
  if not success then
    log:warning("moveAfter: siblingID has invalid ID:", reason)
    loggingStack.pop()
    return tbl
  end

  local raw = rawget(tbl, "__raw")
  if raw.id == siblingID then
    loggingStack.pop()
    return tbl-- trying to move the child to the child?
  end

  if raw.parentID and proxy.localChildren[raw.parentID] then
    local list = proxy.localChildren[raw.parentID]

    local childIndex, siblingIndex
    for i, p in ipairs(list) do
      if p.id == raw.id then childIndex = i end
      if p.id == siblingID then siblingIndex = i end
      if childIndex and siblingIndex then break end
    end
    if childIndex and siblingIndex and childIndex ~= siblingIndex then
      local childProxy = table.remove(list, childIndex)
      if childIndex < siblingIndex then siblingIndex = siblingIndex - 1 end
      table.insert(list, siblingIndex + 1, childProxy)
    end
  end

  threadCommand.call("moveAfter", {
    id = raw.id,
    siblingID = siblingID,
  })
  loggingStack.pop()
  return tbl
end

proxy.moveToFront = function(tbl)
  loggingStack.push()

  local raw = rawget(tbl, "__raw")
  if raw.parentID and proxy.localChildren[raw.parentID] then
    local list = proxy.localChildren[raw.parentID]

    local childIndex
    for i, p in ipairs(list) do
      if p.id == raw.id then
        childIndex = i
        break
      end
    end
    if childIndex and childIndex ~= 1 then
      local childProxy = table.remove(list, childIndex)
      table.insert(list, 1, childProxy)
    end
  end

  threadCommand.call("moveToFront", { id = raw.id })
  loggingStack.pop()
  return tbl
end

proxy.moveToBack = function(tbl)
  loggingStack.push()

  local raw = rawget(tbl, "__raw")
  if raw.parentID and proxy.localChildren[raw.parentID] then
    local list = proxy.localChildren[raw.parentID]

    local childIndex
    for i, p in ipairs(list) do
      if p.id == raw.id then
        childIndex = i
        break
      end
    end
    if childIndex and childIndex ~= #list then
      local childProxy = table.remove(list, childIndex)
      table.insert(list, childProxy)
    end
  end

  threadCommand.call("moveToBack", { id = raw.id })
  loggingStack.pop()
  return tbl
end

proxy._addComponent = function(component, parentProxy)
  loggingStack.push()
  if type(component) == "string" then
    component = { type = component }
  end

  log:assert(type(component) == "table", "Component must be type string or table")

  if not component.id then
    component.id = utilID.generateID()
  end
  component.id = proxy._autocorrectID(component.id)
  component.parentID = rawget(parentProxy, "__raw").id

  local success, reason = utilID.isValidID(component.id)
  log:assert(success, "Invalid ID:", reason)

  log:assert(type(component.type) == "string", "component.type must be string")
  log:assert(component.type ~= "unknown", "component.type mustn't be protected keyword: 'unknown'")
  log:assert(component.type ~= "Tab", "Use mintmousse.newTab() instead of type 'tab'")

  local ct = contract.componentTypes[component.type]
  log:assert(ct, "Unknown component type:", component.type)
  log:assert(ct.hasCreateFunction, "component.type has no create function:", component.type)

  componentLogic.run(component, parentProxy)
  threadCommand.call("addComponent", { component = component })

  local childProxy = proxy.createProxyTable(component)
  proxy._registerLocalChild(component.parentID, childProxy)

  loggingStack.pop()
  return childProxy
end

proxy._autocorrectID = function(preferredID)
  loggingStack.push()
  local id = preferredID
  if proxy.proxyComponents[id] then
    id = utilID.generateID()
    log:warning(("ID clash locally. ID '%s' is in use. Changing it to '%s'"):format(preferredID, id))
  end
  loggingStack.pop()
  return id
end

-- Public functions
-- These should be in their own table really.
proxy.get = function(id, typeHint)
  local p = proxy.proxyComponents[id]
  if p then return p end
  if typeHint and not contract.componentTypes[typeHint] then typeHint = nil end
  return proxy.createProxyTable({ id = id, type = typeHint })
end

proxy.has = function(id)
  return proxy.proxyComponents[id] ~= nil
end

proxy.createProxyTable = function(raw)
  setmetatable(raw, nil)
  local p = setmetatable({ __raw = raw }, proxyMetatable)
  proxy.proxyComponents[raw.id] = p
  return p
end

proxy.createTempProxy = function(raw)
  setmetatable(raw, nil)
  return setmetatable({ __raw = raw }, proxyMetatable)
end

proxy.newTab = function(title, id, index)
  loggingStack.push()
  id = id or utilID.generateID()
  local success, reason = utilID.isValidID(id)
  log:assert(success, "Invalid tab ID:", reason)

  local component = { id = id, type = "Tab", title = title, parentID = nil }

  componentLogic.run(component)
  threadCommand.call("newTab", { id = id, title = title, index = index })

  local p = proxy.createProxyTable(component)
  loggingStack.pop()
  return p
end

proxy.getProtectedKeys = function()
  local keys = { }
  for k in pairs(protectedStatic) do
    table.insert(keys, k)
  end
  return keys
end

return proxy