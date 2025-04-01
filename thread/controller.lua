local lustache = love.mintmousse.require("libs.lustache")
local json = love.mintmousse.require("libs.json")

local controller = {
  updateSinks = { },
  tabs = { },
  idMap = { },
  _isDirty = true,
}

controller.javascript = love.mintmousse.read("thread/index.js")
controller.css = love.mintmousse.read("thread/index.css")

local indexMustache = love.mintmousse.read("thread/index.html")
controller.getIndex = function()
  if controller._isDirty then
    controller.index = lustache:render(indexMustache, controller)
    controller._isDirty = false
  end
  return controller.index
end

controller.addJavascript = function(script)
  controller.javascript = controller.javascript .. "/r/n" .. script
end

controller.addStyling = function(styling)
  controller.css = controller.css .. "/r/n" .. styling
end

controller.getSink = function(threadID)
  for index, sink in ipairs(controller.updateSinks) do
    if sink.threadID == threadID then
      return sink, index
    end
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

-- Must be performed Atomic
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

controller.setTitle = function(title)
  local previousTitle = controller.title
  controller.title = type(title) == "string" and title or "MintMousse"
  controller._isDirty = controller._isDirty or controller.title ~= previousTitle
end

controller.renderIcon = function(icon)
  local iconMustache = love.mintmousse.read("thread/icon/icon.mustache")
  controller.icon = lustache:render(iconMustache, icon)
  controller._isDirty = controller._isDirty or true
end

controller.setSVGIcon = function(icon)
  local svgIconMustache = love.mintmousse.read("thread/icon/icon.svg.mustache")
  local render = lustache:render(svgIconMustache, icon)
  controller.setIconRaw(render, "image/svg+xml")
end

controller.setIconFromFile = function(filepath)
  if not love.filesystem.getInfo(filepath, "file") then
    love.mintmousse.warning("Controller: setIconFromFile: Couldn't locate given filepath. Gave:", filepath)
    return
  end
  local rawIcon = love.filesystem.read(filepath)
  local temp = filepath:lower()
  local iconType
  if temp:match(".png$") then
    iconType = "image/png"
  elseif temp:match(".jpeg$") or temp:match(".jpg$") then
    iconType = "image/jpeg"
  elseif temp:match(".svg$") then
    iconType = "image/svg+xml"
  end
  if not iconType then
    love.mintmousse.warning("Controller: setIconFromFile: Couldn't determine MIME type. File:", filepath)
    return
  end
  controller.setIconRaw(rawIcon, iconType)
end

controller.setIconRaw = function(icon, iconType)
  controller.renderIcon({
    icon = "data:"..iconType..";base64,"..love.data.encode("string", "base64", icon),
    iconType = iconType
  })
end

controller.setIconRFG = function(filepath)
  local success = love.filesystem.mount(filepath, love.mintmousse.TEMP_MOUNT_LOCATION, true)
  if not success then
    love.mintmousse.warning("Controller: Could not mount given RFG zip to temporary location. Location:", love.mintmousse.TEMP_MOUNT_LOCATION)
    return
  end

  local icon = { RFG = true }

  local readAndEncode = function(path)
    local file = love.filesystem.read(love.mintmousse.TEMP_MOUNT_LOCATION..path)
    return love.data.encode("string", "base64", file)
  end

  icon.favicon96x96PNG = "data:image/png;base64,"..readAndEncode("favicon-96x96.png")
  icon.faviconSVG = "data:image/svg+xml;base64,"..readAndEncode("favicon.svg")
  icon.faviconICO = "data:image/x-icon;base64,"..readAndEncode("favicon.ico")
  icon.faviconAppleTouch = "data:image/png;base64,"..readAndEncode("apple-touch-icon.png")

  local webmanifestJson = love.filesystem.read(love.mintmousse.TEMP_MOUNT_LOCATION.."site.webmanifest")
  local manifest = json.decode(webmanifestJson)

  for _, icon in ipairs(manifest.icons) do
    local raw = love.filesystem.read(love.mintmousse.TEMP_MOUNT_LOCATION..icon.src:sub(2))
    icon.src = "data:"..icon.type..";base64," .. love.data.encode("string", "base64", raw)
  end

  icon.webmanifest = "data:application/json;base64,"..love.data.encode("string", "base64", json.encode(manifest))

  controller.renderIcon(icon)

  love.filesystem.unmount(filepath)
end

controller.update = function()
  love.mintmousse.warning("Controller: Need to overwrite controller.update callback")
end

controller.getInitialPayload = function()
  if #controller.tabs == 0 then
    return nil
  end

  local jsonTabs = { }
  for index, tab in ipairs(controller.tabs) do
    local payload = {
      func = "tab_new",
      id = "tab-"..tab.id,
      title = tab.title,
      content = nil, --[[todo render children]]
    }
    table.insert(jsonTabs, index, json.encode(payload))
  end
  return "["..table.concat(jsonTabs, ",").."]"
end

controller.newTab = function(id, title, index)
  if not id then
    return love.mintmousse.warning("Controller: newTab: No ID given")
  end
  if type(title) ~= "string" then
    return love.mintmousse.warning("Controller: newTab: Title must be type string")
  end

  if controller.idMap[id] then
    return love.mintmousse.warning("Controller: newTab: Tried to create Tab with pre-existing ID:", id)
  end

  title = love.mintmousse.sanitizeText(title)

  local tab = {
    type = "tab",
    id = id,
    parent = controller.tabs,
    children = { },
    --
    title = title,
  }

  if not index then
    index = #controller.tabs + 1
  end

  controller.idMap[tab.id] = tab
  table.insert(controller.tabs, index, tab) 

  controller.notifySubscribersComponentAdded(tab, index)
  controller.update(json.encode({ --todo index
    func = "tab_new",
    id = "tab-"..tab.id,
    title = tab.title,
    content = nil,
  }))
end

controller.addComponent = function(component, parentID)

end

controller.removeComponent = function(id)
  local component = controller.idMap[id]
  controller.idMap[id] = nil
  controller.notifySubscribersComponentRemoved(component)
  local componentType = component.type
  if componentType == "tab" then --todo replace with javascript parsed code
    for index, tab in ipairs(controller.tabs) do
      if tab == component then
        table.remove(controller.tabs, index)
        break
      end
    end
    controller.update(json.encode({
      func = "tab_remove",
      id = "tab-"..component.id,
    }))
  end
  -- todo remove children
end

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