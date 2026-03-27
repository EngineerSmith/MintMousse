local idUtil = require(PATH .. "util.id")

local signal = require(PATH .. "thread.signal")

return function(store, logger)
  local loggerTree = logger:extend("Tree")

  local tree = { }

  local validateID = function(id)
    local success, reason = idUtil.isValidID(id)
    if not success then
      loggerTree:warning("Invalid component ID", id, ". Reason:", reason)
      return false
    end
    if store.idLookUp[id] then
      loggerTree:warning("Duplicate ID", id)
      return false
    end
    return true
  end

  local getTypeInfo = function(typeName)
    if not store.componentTypes then
      loggerTree:error("componentTypes not registered yet!")
      return nil
    end
    local t = store.componentTypes[typeName]
    if not t then
      loggerTree:warning("Unknown component type:", typeName)
    end
    return t
  end

  tree.newTab = function(id, title, index)
    id = id or idUtil.generateID()
    if not validateID(id) then return end

    local tab = {
      id       = id,
      type     = "Tab",
      title    = title or "",
      children = { },
    }

    if type(index) == "number" then
      table.insert(store.root, index, tab)
    else
      table.insert(store.root, tab)
      index = #store.root
    end

    store.idLookUp[tab.id] = tab

    signal.emit("broadcast", {
      action = "new",
      id     = id,
      values = { title = tab.title },
      index  = index
    })
  end

  tree.addComponent = function(component, insertIndex)
    -- Normalise and validate
    component.id = component.id or idUtil.generateID()
    component.children = { }
    if not validateID(component.id) then
      return
    end
    if type(component.type) ~= "string" or component.type == "unknown" then
      logger:warning("Bad type on component", component.id)
      return
    end
    if not component.parentID then
      loggerTree:warning("treeissing parentID on", component.id)
      return
    end

    local parent = store.idLookUp[component.parentID]
    if not parent then
      loggerTree:warning("Parent not found", component.parentID, "for", component.id)
      return
    end

    local parentType = getTypeInfo(parent.type)
    local childType = getTypeInfo(component.type)
    if not parentType or not parentType.hasInsertFunction then
      loggerTree:warning("Parent cannot have children", parent.type)
      return
    end
    if not childType or not childType.hasCreateFunction then
      loggerTree:warning("Type cannot be created", component.type)
      return
    end

    -- Prep
    if childType.pushes then
      for push in pairs(childType.pushes) do
        component[push] = { }
      end
    end

    -- Insert
    store.idLookUp[component.id] = component
    if type(insertIndex) == "number" then
      table.insert(parent.children, insertIndex, component)
    else
      table.insert(parent.children, component)
      insertIndex = #parent.children
    end

    -- Delta
    local values = { }
    if parentType.childUpdates then
      for k in pairs(parentType.childUpdates) do
        values[k] = component[k]
      end
    end
    if childType.updates then
      for k in pairs(childType.updates) do
        values[k] = component[k]
      end
    end

    local pushes = { }
    if childType.pushes then
      for k in pairs(childType.pushes) do
        pushes[k] = component[k]
      end
    else
      pushes = nil
    end

    signal.emit("broadcast", {
      action        = "insert",
      parentID      = component.parentID,
      childType     = component.type,
      childPosition = insertIndex,
      id            = component.id,
      values        = values,
      pushes        = pushes,
    })
  end

  local _sendInitialPayloadComponent
  tree.sendInitialPayload = function(client)
    if not client.queue then return end
    for i, tab in ipairs(store.root) do
      client:queue({
        action = "new",
        id     = tab.id,
        values = { title = tab.title },
        index  = i,
      })
      for j, child in ipairs(tab.children) do
        _sendInitialPayloadComponent(client, store.componentTypes[tab.type], child, j)
      end
    end
  end

  _sendInitialPayloadComponent = function(client, parentType, component, position)
    local values = { }
    if parentType and parentType.childUpdates then
      for field in pairs(parentType.childUpdates) do
        values[field] = component[field]
      end
    end
    local childType = store.componentTypes[component.type]
    if childType and childType.updates then
      for field in pairs(childType.updates) do
        values[field] = component[field]
      end
    end

    local pushes = { }
    if childType.pushes then
      for k in pairs(childType.pushes) do
        pushes[k] = component[k]
      end
    end

    client:queue({
      action        = "insert",
      parentID      = component.parentID,
      childType     = component.type,
      childPosition = position,
      id            = component.id,
      values        = values,
      pushes        = pushes,
    })

    for i, child in ipairs(component.children or { }) do
      _sendInitialPayloadComponent(client, childType, child, i)
    end
  end

  local _removeComponentChildren
  tree.removeComponent = function(id)
    local component = store.idLookUp[id]
    if not component then return end

    _removeComponentChildren(component)

    signal.emit("broadcast", {
      action = "remove",
      id     = id,
    })
  end

  _removeComponentChildren = function(component)
    store.idLookUp[component.id] = nil

    if not component.children then
      return
    end
    for _, child in ipairs(component.children) do
      _removeComponentChildren(child)
    end
    component.children = nil
  end

  tree.updateComponent = function(id, index, value)
    -- Validate
    local component = store.idLookUp[id]
    if not component then return end

    local childType = getTypeInfo(component.type)
    local isDirectUpdate = childType and childType.updates and childType.updates[index]

    local isParentChildUpdate = false
    if not isDirectUpdate then
      local parent = store.idLookUp[component.parentID]
      if not parent then
        loggerTree:warning("Parent not found", component.parentID, "for", component.id)
        return
      end
      local parentType = getTypeInfo(parent.type)
      isParentChildUpdate = parentType and parentType.childUpdates and parentType.childUpdates[index]
    end

    if not isParentChildUpdate and not isDirectUpdate then
      loggerTree:warning("Unsupported update field '" .. tostring(index) .. "' on component", component.id, "(type:", component.type or "UNKNOWN", ")")
      return
    end

    -- Apply
    component[index] = value

    -- Delta
    signal.emit("broadcast", {
      action = "update",
      id     = id,
      field  = index,
      values = { [index] = value },
    })
  end

  tree.pushComponent = function(id, index, value)
    -- Validate
    local component = store.idLookUp[id]
    if not component then return end

    local childType = getTypeInfo(component.type)

    if not childType.pushes[index] then
      loggerTree:warning("Unsupported push field '" .. tostring(index) .. "' on component", component.id, "(type:", component.type or "UNKNOWN", ")")
      return
    end

    -- Apply
    table.insert(component[index], value)

    -- Delta
    signal.emit("broadcast", {
      action = "push",
      id     = id,
      field  = index,
      pushes = { [index] = value },
    })
  end

  tree.moveComponent = function(id, newIndex)
    -- Validate
    local component = store.idLookUp[id]
    if not component then return end

    local parent = store.idLookUp[component.parentID]
    if not parent then
      loggerTree:warning("Parent not found", component.parentID, "for", component.id)
      return
    end

    local oldIndex
    for i, child in ipairs(parent.children) do
      if child == component then
        oldIndex = i
        break
      end
    end
    if oldIndex == nil then
      loggerTree:warning("Couldn't find child in parent", component.id)
      return
    end

    if newIndex == 0 then
      newIndex = 1
    end
    if newIndex < 0 then
      newIndex = #parent.children + newIndex + 1
    end

    newIndex = math.max(1, math.min(newIndex, #parent.children))
    if newIndex == oldIndex then return end

    -- Apply
    table.remove(parent.children, oldIndex)
    table.insert(parent.children, newIndex, component)

    -- Delta
    signal.emit("broadcast", {
      action   = "move",
      id       = component.parentID,
      newIndex = newIndex,
      oldIndex = oldIndex,
    })
  end

  -- TODO remove this function, i.e. make tree.setChildrenOrder the only 'moveChildren' function
  tree.reorderChildren = function(id, newOrderArray)
    -- Validate
    local parent = store.idLookUp[id]
    if not parent then
      loggerTree:warning("Parent not founds for reorder", id)
      return
    end

    local children = parent.children or { }
    local numChildren = #children

    if type(newOrderArray) ~= "table" then
      loggerTree:warning("newOrderArray must be type table", id)
      return
    end

    if #newOrderArray ~= numChildren then
      loggerTree:warning("newOrderArray length mismatch", id, ". Expected:", numChildren, ". Got:", #newOrderArray)
      return
    end

    local seen = { }
    for i, oldIndex in ipairs(newOrderArray) do
      if type(oldIndex) ~= "number" then
        loggerTree:warning("newOrderArray[" .. tostring(i) .. "] must be type number", id, ". Array:", loggerTree.inspect(newOrderArray, 1))
        return
      end
      if oldIndex < 1 and oldIndex > numChildren then
        loggerTree:warning("newOrderArray[" .. tostring(i) .. "] is out of bounds", id, ". Array:", loggerTree.inspect(newOrderArray, 1))
        return
      end
      if seen[oldIndex] then
        loggerTree:warning("newOrderArray[" .. tostring(i) .. "] contains a duplicate index already seen", ". Array:", loggerTree.inspect(newOrderArray, 1))
        return
      end
      seen[oldIndex] = true
    end

    -- Apply
    local reorderedChildren = { }
    for i, oldIndex in ipairs(newOrderArray) do
      reorderedChildren[i] = children[oldIndex]
    end
    parent.children = reorderedChildren

    -- Delta
    signal.emit("broadcast", {
      action   = "reorder",
      id       = id,
      newOrder = newOrderArray,
    })
  end

  tree.setChildrenOrder = function(parentID, newOrder)
    local parent = store.idLookUp[parentID]
    if not parent then
      loggerTree:warning("Parent not found for setChildrenOrder", parentID)
      return
    end

    local children = parent.children or { }
    local numChildren = #children
    if numChildren == 0 then return end

    local seen = { }
    local finalIDs = { }

    for _, id in ipairs(newOrder) do
      if type(id) == "string" then
        local comp = store.idLookUp[id]
        if comp and comp.parentID == parentID and not seen[id] then
          table.insert(finalIDs, id)
          seen[id] = true
        end
      end
    end
    for _, child in ipairs(children) do
      if not seen[child.id] then
        table.insert(finalIDs, child.id)
        seen[child.id] = true
      end
    end

    local oldIndexByID = { }
    for i, child in ipairs(children) do
      oldIndexByID[child.id] = i
    end

    local newOrderArray = { }
    for _, id in ipairs(finalIDs) do
      table.insert(newOrderArray, oldIndexByID[id])
    end

    tree.reorderChildren(parentID, newOrderArray)
  end

  local calculateMoveTarget = function(parent, component, siblingID, after)
    local oldIndex, siblingIndex
    for i, child in ipairs(parent.children) do
      if child == component then
        oldIndex = i
      elseif child.id == siblingID then
        siblingIndex = i
      end
      if oldIndex and siblingIndex then break end
    end
    if not oldIndex or not siblingIndex or oldIndex == siblingIndex then
      return nil
    end
    if oldIndex < siblingIndex then
      siblingIndex = siblingIndex - 1
    end
    return after and siblingIndex + 1 or siblingIndex
  end

  tree.moveBefore = function(id, siblingID)
    if id == siblingID then return end

    local component = store.idLookUp[id]
    if not component then return end

    local parent = store.idLookUp[component.parentID]
    if not parent then
      loggerTree:warning("Parent not found", component.parentID, "for", component.id)
      return
    end
    if component.id == siblingID then return end

    local target = calculateMoveTarget(parent, component, siblingID, false)
    if target then
      tree.moveComponent(id, target)
    else
      loggerTree:warning("Invalid sibling for moveBefore", siblingID, "of", id)
      return
    end
  end

  tree.moveAfter = function(id, siblingID)
    if id == siblingID then return end

    local component = store.idLookUp[id]
    if not component then return end

    local parent = store.idLookUp[component.parentID]
    if not parent then
      loggerTree:warning("Parent not found", component.parentID, "for", component.id)
      return
    end
    if component.id == siblingID then return end

    local target = calculateMoveTarget(parent, component, siblingID, true)
    if target then
      tree.moveComponent(id, target)
    else
      loggerTree:warning("Invalid sibling for moveAfter", siblingID, "of", id)
      return
    end
  end

  tree.moveToFront = function(id)
    tree.moveComponent(id, 1)
  end

  tree.moveToBack = function(id)
    tree.moveComponent(id, -1)
  end

  return tree
end