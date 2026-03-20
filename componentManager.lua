local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")
local threadCommand = require(PATH .. "threadCommand")
local componentLogic = require(PATH .. "componentLogic")
local proxyTable = require(PATH .. "proxyTable")
local contract = require(PATH .. "contract")
local utilID = require(PATH .. "util.id")

local loggerComponent = mintmousse._logger:extend("Component")

local componentManager = {
  proxyComponents = { },
}

local autocorrectIDIssueMsg = "ID clash detected locally. ID '%s' is already in use. Automatically assigning unique ID: %s. This may cause issues with hard coded mintmousse.get() calls."
-- Checks if an ID is in use locally and returns a unique ID if it clashes.
local autocorrectID = function(preferredID)
  if componentManager.proxyComponents[preferredID] then
    local newID = utilID.generateID()
    loggerComponent:warning(autocorrectIDIssueMsg:format(preferredID, newID))
    return newID
  end

  return preferredID -- ID isn't in known-use
end

componentManager.addComponent = function(component, parentID, index)
  if type(component) == "string" then
    component = {
      type = component,
    }
  end

  loggerComponent:assert(type(component) == "table", "Component must be type String (ComponentType), or Table (Component).")
  loggerComponent:assert(type(parentID) == "string", "ParentID is required to create Component.")
  loggerComponent:assert(type(index) == "nil" or type(index) == "number", "Index must be type Number, or Nil.")

  if not component.id then
    component.id = utilID.generateID()
  end

  component.id = autocorrectID(component.id)

  component.parentID = parentID

  local success, errorMessage = utilID.isValidID(component.id)
  loggerComponent:assert(success, "Gave invalid ID. Reason:", errorMessage)

  local componentTypeIssue = "Gave invalid ComponentType. Reason:"
  loggerComponent:assert(type(component.type) == "string", componentTypeIssue, "Component.type isn't type string")

  local cannotCreateType = "Cannot create a component with type:"
  loggerComponent:assert(component.type ~= "unknown", componentTypeIssue, cannotCreateType, "'unknown'. This is a protected keyword.")
  loggerComponent:assert(component.type ~= "tab", componentTypeIssue, cannotCreateType, "'tab'. Please use mintmousse.newTab().")

  local componentType = contract.componentTypes[component.type]
  loggerComponent:assert(componentType, componentTypeIssue, "This type does not exist:", component.type)
  loggerComponent:assert(componentType.hasCreateFunction, componentTypeIssue, "Cannot create a component with type:", "'"..component.type.."'.", "As it does not have a construction method (Couldn't find a JS function named 'create').")

  componentLogic.run(component)

  threadCommand.call("addComponent", {
    component = component,
    index = index,
  })

  return componentManager._createProxyTable(component)
end

componentManager.newTab = function(title, id, index)
  id = id or utilID.generateID()

  local success, errorMessage = utilID.isValidID(id)
  loggerComponent:assert(success, "Couldn't create tab with given ID:", id, ". Reason:", errorMessage)

  local component = {
    id = id,
    type = "Tab",
    title = title,
    parentID = nil,
  }

  componentLogic.run(component)

  threadCommand.call("newTab", {
    id = id,
    title = title,
    index = index,
  })

  return componentManager._createProxyTable(component)
end

componentManager.get = function(id, componentTypeHint)
  local proxy = componentManager.proxyComponents[id]
  if proxy then
    return proxy
  end
  if type(componentTypeHint) ~= "string" or contract.componentTypes[componentTypeHint] == nil then
    componentTypeHint = nil
  end
  return componentManager._createProxyTable({ id = id, type = componentTypeHint })
end

componentManager._createProxyTable = function(component)
  local proxy = proxyTable.createProxyTable(component)
  componentManager.proxyComponents[component.id] = proxy
  return proxy
end

componentManager.removeComponent = function(id)
  local success, errorMessage = utilID.isValidID(id)
  loggerComponent:assert(success, "Gave invalid ID for removal. Gave:", id, ". Reason:", errorMessage)

  threadCommand.call("removeComponent", {
    id = id,
  })
  componentManager.cleanupProxy(id)
end

componentManager.cleanupProxy  = function(id)
  local proxy = componentManager.proxyComponents[id]
  if not proxy then
    return
  end
  componentManager.proxyComponents[id] = nil
  proxy:_markRemoved()
end

return componentManager