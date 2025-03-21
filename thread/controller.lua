local controller = {
  updateSinks = { },
  tabs = { },
  idMap = { },
}

controller.getSink = function(threadID)
  for index, sink in ipairs(controller.updateSinks) do
    if sink.threadID == threadID then
      return sink, index
  end
  return nil
end

local syncSinkExplore
syncSinkExplore = function(component, typeMap, relationships, target, isInTargetSubtree)
  isInTargetSubtree = isInTargetSubtree or component.id == target

  if isInTargetSubtree then
    typeMap[component.id] = component.type
    relationships[component.id] = { }
  end

  for index, child in ipairs(component.children) do
    if isInTargetSubtree then
      relationships[component.id][index] = child.id
    end
    syncSinkExplore(child, typeMap, relationships, target, isInTargetSubtree)
  end
end

controller.syncSink = function(sink)
  local package = {
    type = "latest",
    typeMap = { },
    relationships = { },
  }
  for _, tab in ipairs(controller.tabs) do
    syncSinkExplore(tab, package.typeMap, package.relationships, sink.target, sink.target == "all")
  end
  sink.channel:clear()
  sink.channel:push(love.mintmousse._encode(package))
end

controller.updateThreadSubscription = function(threadID, target)
  if threadID == "MintMousse" then
    love.mintmousse.warning("Controller: 'MintMousse' cannot subscribe to updates. The 'MintMousse' thread is the owner and already has the most up-to-date information.")
    return
  end
  local sink, index = controller.getSink(threadID)
  if target == "none" then
    if sink then
      sink.channel:clear()
      table.remove(controller.updateSinks, index)
    end
    return
  end
  if not sink then
    sink = {
      threadID = threadID,
      channel = love.thread.getChannel(love.mintmousse.THREAD_COMPONENT_UPDATES_ID:format(threadID))
    }
    table.insert(controller.updateSinks, sink)
  end
  sink.target = target
  -- Clear sink, and push latest
  sink.channel:performAtomic(controller.syncSink, sink)
end

local isIDRelevant
isIDRelevant = function(component, target)
  if component.id == target then
    return true
  end
  if not component.id then
    return false
  end
  return isIDRelevant(component.parent, target)
end

local packageComponent
packageComponent = function(component)
  local package = {
    id = component.id,
    type = component.type,
    parentID = component.parent.id
  }
  if #component.children ~= 0 then
    package.children = { }
    for index, child in ipairs(component.children) do
      package.children[index] = format(child)
    end
  end
  return package
end

controller.notifySubscribersComponentAdded = function(targetComponent, parentChildIndex)
  if not parentChildIndex then
    for i, child in ipairs(targetComponent.parent.children) do
      if child == targetComponent then
        parentChildIndex = i
        break
      end
    end
    if not parentChildIndex then
      love.mintmousse.warning("Controller: Couldn't find child in parent's children! Tell a programmer:", targetComponent.id, ". Parent:", targetComponent.parent.id)
      return
    end
  end
  for _, sink in ipairs(controller.updateSinks) do
    if sink.target == "all" or isIDRelevant(targetComponent, sink.target) then
      sink.channel:push(love.mintmousse._encode({
        type = "componentAdded",
        packageComponent(targetComponent), parentChildIndex
      }))
    end
  end
end

controller.notifySubscribersComponentRemoved = function(targetComponent)
  for _, sink in ipairs(controller.updateSinks) do
    if sink.target == "all" or isIDRelevant(targetComponent, sink.target) then
      sink.channel:push(love.mintmousse._encode({
        type = "componentRemoved",
        packageComponent(targetComponent)
      }))
    end
  end
end

controller.newTab = function(id, title, index)
  if not id then
    return love.mintmousse.warning("Controller: No ID passed to newTab")
  end
  if not title then
    return love.mintmousse.warning("Controller: No Title passed to newTab")
  end

  if controller.idMap[id] then
    love.mintmousse.warning("Controller: Tried to create Tab with pre-existing ID:", id)
    return
  end

  if not index then
    index = #controller.tabs
  end

  local tab = {
    id = id,
    parent = controller.tabs,
    children = { },
    title = title,
    treeRef = treeTab,
  }

  controller.idMap[tab.id] = tab
  table.insert(controller.tabs, index, tab)

end

-- local TREE_VERSION_CHANNEL = love.thread.getChannel(love.mintmousse.COMPONENT_TREE_VERSION_ID)
-- local TREE_DATA_CHANNEL = love.thread.getChannel(love.mintmousse.COMPONENT_TREE_DATA_ID)
-- controller.updateTree = function()
--   TREE_VERSION_CHANNEL:performAtomic(function()
--   TREE_DATA_CHANNEL:performAtomic(function()
--     TREE_VERSION_CHANNEL:push(TREE_VERSION_CHANNEL:pop() + 1)
--     TREE_DATA_CHANNEL:clear()
--     TREE_DATA_CHANNEL:push(love.mintmousse._encode(controller.tree))
--   end)
--   end)
-- end

-- -- Programmer note; when calling this function, add your own logging if it returns nil
-- controller.getComponent = function(id)
--   if not id then
--     return nil
--   end
--   return controller.idMap[id]
-- end

-- controller.removeComponent = function(id)
--   local component = controller.getComponent(id)
--   if not component then
--     love.mintmousse.warning("Controller: Could not find component,", id, ", to remove. This could be because the id is invalid, or it has already been removed.")
--     return
--   end
--   controller.idMap[id] = nil

--   local tbl = component.parent.children or component.parent
--   local found = false
--   for index, child in ipairs(tbl) do
--     if child == component then
--       table.remove(tbl, index)
--       found = true
--       break
--     end
--   end
--   if not found then
--     love.mintmousse.error("Controller: Tried to remove component,", component.id, ", but couldn't find it within it's parent")
--     return
--   end

--   local tbl = component.treeRef.parent.children or component.treeRef.parent
--   local found = false
--   for index, child in ipairs(tbl) do
--     if child == component.treeRef then
--       table.remove(tbl, index)
--       found = true
--       break
--     end
--   end
--   if not found then
--     love.mintmousse.error("Controller: Tried to remove component,", component.id, ", but couldn't find it within it's parent. (tree)")
--     return
--   end

--   controller.updateTree()

--   --todo tell component to remove itself from webpage
-- end

return controller