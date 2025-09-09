local lustache = love.mintmousse.require("libs.lustache")
local json = love.mintmousse.require("libs.json")

local controller = {
  updateSinks = { },
  tabs = { },
  idMap = { },
  _isDirty = true,
}

local errorMessage
controller.javascript, errorMessage = love.filesystem.read(love.mintmousse.DEFAULT_INDEX_JS)
if not controller.javascript then
  love.mintmousse.error("Controller: Unable to read JavaScript file:", love.mintmousse.DEFAULT_INDEX_JS, ". Reason:", errorMessage)
  return
end
controller.css, errorMessage = love.filesystem.read(love.mintmousse.DEFAULT_INDEX_CSS)
if not controller.css then
  love.mintmousse.error("Controller: Unable to read CSS file:", love.mintmousse.DEFAULT_INDEX_CSS, ". Reason:", errorMessage)
  return
end

local indexMustache, errorMessage = love.filesystem.read(love.mintmousse.DEFAULT_INDEX_HTML)
if not indexMustache then
  love.mintmousse.error("Controller: Unable to read HTML/Mustache file:", love.mintmousse.DEFAULT_INDEX_HTML, ". Reason:", errorMessage)
  return
end
controller.getIndex = function()
  if controller._isDirty then
    controller.index = lustache:render(indexMustache, controller)
    controller._isDirty = false
  end
  return controller.index
end

controller.addJavascript = function(script)
  controller.javascript = controller.javascript .. "\r\n" .. script
end

controller.addStyling = function(styling)
  controller.css = controller.css .. "\r\n" .. styling
end

controller.getSink = function(threadID)
  for index, sink in ipairs(controller.updateSinks) do
    if sink.threadID == threadID then
      return sink, index
    end
  end
  return nil
end

controller.getWebsiteID = function(component)
  return ("%s-%s"):format(component.type, component.id)
end

controller.splitWebsiteID = function(websiteID)
  local sepPos = string.find(websiteID, "-")
  if not sepPos then
    return nil, nil
  end

  local typePart = websiteID:sub(1, sepPos - 1)
  local idPart = websiteID:sub(sepPos + 1)

  local component = controller.get(idPart)
  if not component or component.type ~= typePart then
    return nil, nil
  end

  return component.id, component.type, component
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
controller.syncSink = function(_, sink)
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
      channel = love.thread.getChannel(love.mintmousse.THREAD_COMPONENT_UPDATES_ID:format(threadID)),
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

controller.getType = function(type_)
  return controller.componentTypes[type_]
end

controller.update = function()
  love.mintmousse.warning("Controller: Need to overwrite controller.update callback")
end

local makeNewPackage = function(component)
  local componentType = controller.getType(component.type)

  local package = {
    func = ("%s_insert"):format(component.parent.type),
    parentID = controller.getWebsiteID(component.parent),
    newFunc = componentType.hasNewFunction and ("%s_new"):format(component.type) or nil,
  }

  package.id = controller.getWebsiteID(component)

  if componentType.hasNewFunction and componentType.updates then
    for index in pairs(componentType.updates) do
      if type(component[index]) == "string" then
        package[index] = love.mintmousse.sanitizeText(component[index])
      else
        package[index] = component[index]
      end
    end
  end

  if componentType.mustache then
    local id = component.id
    component.id = controller.getWebsiteID(component)
    package.render = lustache:render(componentType.mustache, component)
    component.id = id
  end

  if component.parent then
    local componentParentType = controller.getType(component.parent.type)
    if componentParentType.childUpdates then
      for index in pairs(componentParentType.childUpdates) do
        if not package[index] then
          if type(component[index] == "string") then
            package[index] = love.mintmousse.sanitizeText(component[index])
          else
            package[index] = component[index]
          end
        end
      end
    end
  end

  if not package.newFunc and not package.render then
    love.mintmousse.error("Controller: Tried to call makeNewPackage; but neither JS or HTML was successful in creating this componentType. Tell a programmer: this should have been caught earlier.")
    return nil
  end

  return package
end

local addPackagesForChildren
addPackagesForChildren = function(component, packages)
  if component.type ~= "tab" then
    table.insert(packages, json.encode(makeNewPackage(component)))
  end
  for _, child in ipairs(component.children) do
    addPackagesForChildren(child, packages)
  end
end

controller.getInitialPayload = function()
  if #controller.tabs == 0 then
    return nil
  end

  local packages = { }
  for index, tab in ipairs(controller.tabs) do
    local payload = {
      func = "tab_new",
      id = controller.getWebsiteID(tab),
      title = tab.title,
    }
    table.insert(packages, index, json.encode(payload))
    addPackagesForChildren(tab, packages)
  end
  return "["..table.concat(packages, ",").."]"
end

controller.get = function(id)
  return controller.idMap[id]
end

controller.newTab = function(id, title, index, threadOwner)
  if not id then
    return love.mintmousse.warning("Controller: newTab: No ID given")
  end
  if type(title) ~= "string" then
    return love.mintmousse.warning("Controller: newTab: Title must be type string")
  end

  if controller.get(id) then
    return love.mintmousse.warning("Controller: newTab: Tried to create Tab with pre-existing ID:", id)
  end

  title = love.mintmousse.sanitizeText(title)

  local tab = {
    type = "tab",
    id = id,
    parent = controller.tabs,
    children = { },
    creator = threadOwner,
    --
    title = title,
  }

  if not index then
    index = #controller.tabs + 1
  end

  controller.idMap[tab.id] = tab
  table.insert(controller.tabs, index, tab) 

  controller.notifySubscribersComponentAdded(tab, index)

  controller.update(json.encode({ -- todo index
    func = controller.getType(tab.type).hasNewFunction and (tab.type.."_new") or love.mintmousse.error("Tell a programmer; tab_new is missing from tab.js"),
    id = controller.getWebsiteID(tab),
    title = tab.title,
    content = nil,
  }))
end

controller.addComponent = function(component, parentID)
  local componentType = controller.getType(component.type)
  if not componentType then
    love.mintmousse.warning("Controller: Tried to create component with invalid type:", component.type)
    return
  end

  if not componentType.hasMustacheFile and not componentType.hasNewFunction then
    love.mintmousse.warning("Controller: Tried to create component with invalid type:", component.type, ". As it does not have a construction method (JS or HTML)")
    return
  end

  local parent = controller.get(parentID)
  if not controller.getType(parent.type).hasInsertFunction then
    love.mintmousse.warning("Controller: Tried to add component to child who can't have children. If you're a developer add the function <type>_insert to your javascript.")
  end

  component.parent = parent
  component.children = { }
  table.insert(parent.children, component)
  controller.idMap[component.id] = component
  controller.notifySubscribersComponentAdded(component, #parent.children)

  local package = makeNewPackage(component)
  controller.update(json.encode(package))
end

controller.updateComponent = function(id, index, value)
  local component = controller.get(id)
  if not component then
    love.mintmousse.warning("Controller: Tried to update component when component does not exist.")
    return
  end
  local typeUpdates = controller.getType(component.type).updates
  if typeUpdates and typeUpdates[index] then
    component[index] = value

    controller.update(json.encode({
      func = ("%s_update_%s"):format(component.type, index),
      id = controller.getWebsiteID(component),
      [index] = type(value) == "string" and love.mintmousse.sanitizeText(value) or value,
    }))
  end
end

controller.updateParentComponent = function(parentID, childID, index, value)
  local parentComponent = controller.get(parentID)
  if not parentComponent then
    love.mintmousse.warning("Controller: Tried to update parent component when parent component does not exist.")
    return
  end
  local childComponent = controller.get(childID)
  if not childComponent then
    love.mintmousse.warning("Controller: Tried to update component when component does not exist.")
    return
  end

  if childComponent.parent ~= parentComponent then
    love.mintmousse.warning("Controller: Parent child mismatch. Given child component gave incorrect parent component.")
    return
  end

  local typeChildUpdates = controller.getType(parentComponent.type).childUpdates
  if typeChildUpdates and typeChildUpdates[index] then
    childComponent[index] = value

    controller.update(json.encode({
      func = ("%s_update_child_%s"):format(parentComponent.type, index),
      parentID = controller.getWebsiteID(parentComponent),
      id = controller.getWebsiteID(childComponent),
      [index] = type(value) == "string" and love.mintmousse.sanitizeText(value) or value,
    }))
  end
end

local removeChildren
removeChildren = function(component)
  for _, child in ipairs(component.children) do
    removeChildren(child)
  end
  controller.idMap[component.id] = nil
  component.children = nil
end

controller.removeComponent = function(id)
  local component = controller.get(id)
  controller.notifySubscribersComponentRemoved(component)

  -- component.parent will hold children if it is the root (controller.tabs)
  local children = component.parent.children or component.parent
  for index, child in ipairs(children) do
    if child == component then
      table.remove(children, index)
      break
    end
  end

  removeChildren(component)

  local package = {
    func = "removeComponent",
    id = controller.getWebsiteID(component),
  }

  local componentType = controller.getType(component.type)
  if componentType.hasRemoveFunction then
    package.func = ("%s_remove"):format(component.type)
  end

  if component.parent and component.parent.type then
    local parentComponentType = controller.getType(component.parent.type)
    if parentComponentType and parentComponentType.hasRemoveChildFunction then
      package.func = ("%s_remove_child"):format(component.parent.type)
      package.parentID = controller.getWebsiteID(component.parent)
    end
  end

  controller.update(json.encode(package))
end

controller.notifyToast = function(message)
  local package = {
    func = "notify",
    type = "toast",
    title = message.title and love.mintmousse.sanitizeText(message.title) or nil,
    text = message.text and love.mintmousse.sanitizeText(message.text) or nil,
    hideDelay = type(message.hideDelay) == "number" and message.hideDelay or nil,
  }

  if type(message.animatedFade) == "boolean" then
    package.animatedFade = message.animatedFade
  end

  if type(message.autoHide) == "boolean" then
    package.autoHide = message.autoHide
  end

  controller.update(json.encode(package))
end

return controller