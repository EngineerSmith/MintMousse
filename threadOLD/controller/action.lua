local PATH = (...):match("^(.*)action$")
local ROOT = PATH:match("^(.-)thread%.controller%.$")

local mintmousse = require(ROOT .. "conf")
local util = require(ROOT .. "util")

local state = require(PATH .. "state")

local loggerAction = require(PATH .. "logger"):extend("Action")

local action = { }

local MNPLogger = loggerAction:extend("makeNewPackage", "bright_black")
local makeNewPackage = function(component, parentChildIndex)
  if not parentChildIndex then
    for i, child in ipairs(component.parent.children) do
      if child == component then
        parentChildIndex = i
        break
      end
    end
  end

  local componentType = -- todo get type of component (the table, not the string ID of type)

  local package = {
    func     = ("%s_insert"):format(component.parent.type),
    parentID = state.toWebsiteID(component.parent),
    id       = state.toWebsiteID(component),
    newFunc  = componentType.hasNewFunction and ("%s_new"):format(component.type) or nil,
    index    = parentChildIndex,
  }

  if componentType.mustache then
    local id = component.id
    component.id = util.toWebsiteID(component)
    package.render = lustache:render(componentType.mustache, component)
    component.id = id
  end

  if not package.newFunc and not package.render then
    MNPLogger:warning("Tried to call makeNewPackage, but the client would be unsuccessful at creating this componentType.")
    return
  end

  if componentType.hasNewFunction and componentType.updates and not package.render then
    for index in pairs(componentType.updates) do
      if type(component[index]) == "string" then
        package[index] = util.sanitizeText(component[index])
      else
        package[index] = component[index]
      end
    end
  end

  if component.parent then
    local componentParentType = -- todo see above about type of component
    if componentParentType.childUpdates then
      for index in pairs(componentParentType.childUpdates) do
        if not package[index] then
          if type(component[index] == "string") then
            package[index] = util.sanitizeText(component[index])
          else
            package[index] = component[index]
          end
        end
      end
    end
  end

  return package
end

local addPackagesForChildren
addPackagesForChildren = function(component, packages, index)
  if component.type ~= "tab" then
    table.insert(packages, json.encode(makeNewPackage(component, index)))
  end
  for index, child in ipairs(component.children) do
    addPackagesForChildren(child, packages, index)
  end
end

renderer.getInitialPayload = function()
  if #state.tabs == 0 then
    return nil
  end

  local packages = { }
  for index, tab in ipairs(state.tabs) do
    local payload = {
      func = "tab_new",
      id = state.toWebsiteID(tab),
      index = index,
      title = tab.title,
    }
    table.insert(packages, index, json.encode(payload))
    addPackagesForChildren(tab, packages, index)
  end
  return "["..table.concat(packages, ",").."]"
end

local NTLogger = loggerAction:extend("newTab", "bright_black")
action.newTab = function(id, title, index, threadOwner)
  if state.get(id) then
    NTLogger:warning("Tried to create Tab with ID already in use:", id)
    return
  end

  local tab = {
    type = "tab",
    id = id,
    parent = state.tabs,
    children = { },
    creator = threadOwner,
    -- Component specific data
    title = util.sanitizeText(title),
  }

  local childCount = #state.tabs
  if type(index) ~= "number" or index == 0 then
    index = childCount + 1
  end
  index = math.max(-childCount, math.min(index, childCount + 1))
  if index < 0 then
    index = index + childCount + 1
  end

  table.insert(controller.tabs, index, tab)
  state.add(tab)

  -- TODO replace with the equivalent controller.update
  local tabType = -- todo see other component Type comments
  controller.update(json.encode({
    func  = tabType.hasNewFunction and "tab_new" or NTLogger:error("Unreachable code; tab_new is missing from tab.js"),
    id    = state.toWebsiteID(tab),
    index = index,
    title = tab.title,
  }))
end

local ACLogger = loggerAction:extend("addComponent", "bright_black")
action.addComponent = function(component, parentID, index)
  local componentType = -- todo... again see component typing comments
  if not componentType then
    ACLogger:warning("Tried to create component with invalid type:", component.type, ". ID:", component.id)
    return
  end

  if not componentType.hasMustacheFile or not componentType.hasNewFunction then
    ACLogger:warning("Tried to create component with invalid type:", component.type, ". ID:", component.id, ". Reason: It does not have a construction method (JS or HTML)")
    return
  end

  local parent = state.get(parentID)
  local componentParentType = -- todo
  if not componentParentType.hadInsertFunction then
    ACLogger:warning("Tried to add component to parent who can't have children. Perhaps the function `<type>_insert` is missing or mistyped.")
    return
  end

  local childCount = #parent.children
  if type(index) ~= "number" or index == 0 then
    index = childCount + 1
  end
  index = math.max(-childCount, math.min(index, childCount + 1))
  if index < 0 then
    index = index + childCount + 1
  end

  component.parent = parent
  component.children = { }

  table.insert(parent.children, index, component)
  state.add(component)

  local package = makeNewPackage(component, index)
  controller.update(json.encode(package)) --todo replace controller.update
end

local UCLogger = loggerAction:extend("updateComponent", "bright_black")
action.updateComponent = function(id, index, value)
  local component = state.get(id)
  if not component then
    UCLogger:warning("Tried to update component when component does not exist.")
    return
  end

  local typeUpdates = -- todo see type comments; .updates
  if typeUpdates and typeUpdates[index] then
    component[index] = value

    controller.update(json.encode({ -- todo replace controller.update
      func    = ("%s_update_%s"):format(component.type, index),
      id      = state.toWebsiteID(component),
      [index] = type(value) == "string" and util.sanitizeText(value) or value,
    }))
  end
end

local UPCLogger = loggerAction:extend("updateParentComponent", "bright_black")
action.updateParentComponent = function(parentID, childID, index, value)
  local parentComponent = state.get(parentID)
  if not parentComponent then
    UPCLogger:warning("Tried to update parent component when parent component does not exist.")
    return
  end

  local childComponent = state.get(parentID)
  if not childComponent then
    UPCLogger:warning("Tried to update child component when child component does not exist.")
    return
  end

  if childComponent.parent ~= parentComponent then
    UPCLogger:warning("Parent Child mismatch. Given child component gave incorrect parent component.") -- todo better wording
    return
  end

  local typeChildUpdates = -- todo see type comments; .childUpdates
  if typeChildUpdates and typeChildUpdates[index] then
    childComponent[index] = value

    controller.update(json.encode({ -- todo replace controller.update
      func     = ("%s_update_child_%s"):format(parentComponent.type, index),
      parentID = state.toWebsiteID(parentComponent),
      id       = state.toWebsiteID(childComponent),
      [index]  = type(value) == "string" and util.sanitizeText(value) or value,
    }))
  end
end

local removeChildren
removeChildren = function(component)
  for _, child in ipairs(component.children) do
    removeChildren(child)
  end
  state.remove(component.id)
  component.children = nil
end

action.removeChildren = function(id)
  local component = state.get(id)

  -- Component.parent will hold children if it is the root (state.tabs)
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
    id   = state.toWebsiteID(component),
  }

  local componentType = -- todo see type comments
  if componentType.hasRemoveFunction then
    package.func = ("%s_remove"):format(component.type)
  end

  if component.parent and component.parent.type then
    local parentComponentType = -- todo see type comments
    if parentComponentType and parentComponentType.hasRemoveChildFunction then
      package.func = ("%s_remove_child"):format(component.parent.type)
      package.parentID = state.toWebsiteID(component.parent)
    end
  end

  controller.update(json.encode(package)) -- todo controller.update
end

action.notifyToast = function(message)
  local package = {
    func  = "notify",
    type  = "toast",
    title = message.title and util.sanitizeText(message.title) or nil,
    text  = message.text and util.sanitizeText(message.text) or nil,
    hideDelay = type(message.hideDelay) == "number" and message.hideDelay or nil,
  }

  if type(message.animatedFade) == "boolean" then
    package.animatedFade = message.animatedFade
  end

  if type(message.autoHide) == "boolean" then
    package.autoHide = message.autoHide
  end

  controller.update(json.encode(package)) -- todo controller.update
end

return action