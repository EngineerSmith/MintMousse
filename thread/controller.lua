local controller = {
  tabs = { },
  tree = { },
  idLookUp = { },
}

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

-- controller.newTab = function(id, title, index)
--   if not id then
--     return love.mintmousse.warning("Controller: No ID passed to newTab")
--   end
--   if not title then
--     return love.mintmousse.warning("Controller: No Title passed to newTab")
--   end

--   if controller.idLookUp[id] then
--     love.mintmousse.warning("Controller: Tried to create Tab with pre-existing ID:", id)
--     return
--   end

--   if not index then
--     index = #controller.tabs
--   end

--   local treeTab = {
--     id = id,
--     type = "tab",
--     parent = controller.tree,
--     children = { }
--   }

--   local tab = {
--     id = id,
--     parent = controller.tabs,
--     children = { },
--     title = title,
--     treeRef = treeTab,
--   }

--   controller.idLookUp[tab.id] = tab
--   table.insert(controller.tabs, index, tab)
--   table.insert(controller.tree, index, treeTab)
-- end

-- -- Programmer note; when calling this function, add your own logging if it returns nil
-- controller.getComponent = function(id)
--   if not id then
--     return nil
--   end
--   return controller.idLookUp[id]
-- end

-- controller.removeComponent = function(id)
--   local component = controller.getComponent(id)
--   if not component then
--     love.mintmousse.warn("Controller: Could not find component,", id, ", to remove. This could be because the id is invalid, or it has already been removed.")
--     return
--   end
--   controller.idLookUp[id] = nil

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