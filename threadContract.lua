local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")
local threadCommunication = require(PATH .. "threadCommunication")
local createProxyTable = require(PATH .. "proxyTable")
local utilID = require(PATH .. "util.id")

local lfs = love.filesystem

local loggerComponent = mintmousse._logger:extend("Component")
local loggerLogic = loggerComponent:extend("Logic")

local threadContract = {
  componentTypes = nil, -- Set with threadContract.blockUntilComplete
}

local componentTypesChannel = love.thread.getChannel(mintmousse.READONLY_BASIC_TYPES_ID)
local timeoutValue = mintmousse.COMPONENT_PARSE_TIMEOUT
threadContract.blockUntilComplete = function()
  threadContract.componentTypes = componentTypesChannel:peek()
  if threadContract.componentTypes ~= nil then
    -- Components are already loaded and ready to go
    if not love.isThread then -- is Main thread
      mintmousse._logger:info("MintMousse components successfully loaded")
    end
    return
  end

  local thread = love.thread.getChannel(mintmousse.READONLY_THREAD_LOCATION):peek()
  mintmousse._logger:assert(thread, "MintMousse Thread object is unexpectedly missing.")

  mintmousse._logger:info("Blocking thread to load MintMousse components.")
  local success, timeout = false, false

  local start = love.timer.getTime()
  while not success and not timeout and thread:isRunning() do
    love.timer.sleep(1e-3)

    threadContract.componentTypes = componentTypesChannel:peek()

    success = threadContract.componentTypes ~= nil
    timeout = love.timer.getTime() - start >= timeoutValue
  end
  local timeElapsed = love.timer.getTime() - start

  if success then
    mintmousse._logger:info("MintMousse components successfully loaded",
      ("(took %.2fms)."):format(timeElapsed*1000))
    return
  end

  if timeout then
    mintmousse._logger:warning("Timeout reached ("..timeoutValue.."s) while waiting for MintMousse Thread to load components.",
      "Consider increasing the timeout ("..timeoutValue.."s).")
  end

  if not thread:isRunning() then
    mintmousse._logger:warning("Thread isn't running while waiting for componentTypes. Checking for errors.")
    local errorMessage = thread:getError()
    if errorMessage then
      if type(love.handlers) == "table" and love.handlers["threaderror"] then
        pcall(love.handlers["threaderror"], thread, errorMessage)
      elseif love.event then
        love.event.push("threaderrror", thread, errorMessage)
      end
      mintmousse._logger:error("MintMousse's thread encountered an error:", errorMessage)
    else
      mintmousse._logger:warning("The thread object reported no error.",
        "This suggests the MintMousse Thread is stuck or overloaded.",
        "Consider increasing the timeout ("..timeoutValue.."s).")
    end
  end
end

threadContract.addLocalType = function(id, componentType)
  local success, errorMessage = utilID.isValidID(id)
  if not success then
    loggerComponent:error("Gave invalid ID. Gave:", id, ". Reason:", errorMessage)
    return
  end

  if not threadContract.componentTypes[componentType] then
    loggerComponent:warning("Gave invalid componentType. This type does not exist:",
      componentType, ". Tried to assign to:", id)
    return
  end

  local component = mintmousse.get(id)
  local self = rawget(component, "__raw")
  local currentType = rawget(self, "type")

  if currentType == nil then
    rawset(self, "type", componentType)
  elseif currentType ~= componentType then
    loggerComponent:warning("Tried to set componentType of component that already has a type ("..currentType.."). ID:",
      id, ". Requested type:", componentType)
  end
  -- if currentType == componentType; silent pass

  return component
end

local loadComponentLogic = function(componentTypeName, componentType)
  if not componentType.hasComponentLogic then
    return -- Nothing to load
  end

  if componentType.componentLogic then
    return -- Already loaded
  end

  local path
  for i = #componentType.directories, 1, -1 do
    path = componentType.directories[i] .. componentTypeName .. ".lua"
    if lfs.getInfo(path, "file") then
      break
    end
    path = nil
  end
  if not path then
    loggerLogic:warning("Failed to discover path for component logic("..componentTypeName..") which was previous found in one of these directories:", table.concat(componentType.directories, ", "))
    return nil
  end

  local componentLogicLoadFail = "Failed to load component logic! For: "..componentTypeName..". Reason:"

  local success, chunk, errorMessage = pcall(lfs.load, path)
  loggerLogic:assert(success, componentLogicLoadFail, chunk)
  loggerLogic:assert(chunk, componentLogicLoadFail, errorMessage)

  local success, componentLogic = pcall(chunk)
  loggerLogic:assert(success, "Failed to run component logic! For:", componentTypeName, ". Reason:", componentLogic)

  componentType.componentLogic = componentLogic

  if type(componentType.componentLogic) ~= "table" then
    loggerLogic:warning(componentLogicLoadFail, "Didn't return a table type as expected.")
    componentType.componentLogic, componentType.hasComponentLogic = nil, false -- stop it from trying to reload
    return
  end

  -- Per function
  if type(componentType.componentLogic.onCreate) ~= "function" then
    loggerLogic:warning(componentLogicLoadFail, "'onCreate' wasn't type function.")
    componentType.componentLogic.onCreate = nil
  end

  -- All functions; currently only 'onCreate'
  if type(componentType.componentLogic.onCreate) == "nil" then
    loggerLogic:warning(componentLogicLoadFail, "Returned component logic table didn't contain any functions for:", "onCreate")
    componentType.componentLogic, componentType.hasComponentLogic = nil, false -- stop it from trying to reload
    return
  end
end

local autocorrectIDIssueMsg = "ID clash detected locally. ID '%s' is already in use. Automatically assigning unique ID: %s. This may cause issues with hard coded mintmousse.get() calls."
-- Checks if an ID is in use locally and returns a unique ID if it clashes.
local autocorrectID = function(preferredID)
  if mintmousse._proxyComponents[preferredID] then
    local newID = utilID.generateID()
    loggerComponent:warning(autocorrectIDIssueMsg:format(preferredID, newID))
    return newID
  end

  return preferredID -- ID isn't in known-use
end

threadContract.addComponent = function(component, parentID)
  if type(component) == "string" then
    component = {
      type = component,
    }
  end

  loggerComponent:assert(type(component) == "table", "Component must be ComponentType(string) or a Component(table).")
  loggerComponent:assert(type(parentID) == "string", "ParentID is required to create Component.")

  if not component.id then
    component.id = utilID.generateID()
  end

  component.id = autocorrectID(component.id)

  component.parentID = parentID
  component.creator = mintmousse._threadID

  local success, errorMessage = utilID.isValidID(component.id)
  loggerComponent:assert(success, "Gave invalid ID. Reason:", errorMessage)

  local componentTypeIssue = "Gave invalid ComponentType. Reason:"
  loggerComponent:assert(type(component.type) == "string", componentTypeIssue, "Component.type isn't type string")

  local cannotCreateType = "Cannot create a component with type:"
  loggerComponent:assert(component.type == "unknown", componentTypeIssue, cannotCreateType, "'unknown'. This is a protected keyword.")
  loggerComponent:assert(component.type == "tab", componentTypeIssue, cannotCreateType, "'tab'. Please use mintmousse.newTab().")

  local componentType = threadContract.componentTypes[component.type]
  loggerComponent:assert(componentType, componentTypeIssue, "This type does not exist:", component.type)
  loggerComponent:assert(componentType.hasMustacheFile or componentType.hasNewFunction, componentTypeIssue, "Cannot create a component with type:", "'"..component.type.."'.", "As it does not have a construction method (JS or HTML).")

  loadComponentLogic(component.type, componentType)
  if componentType.componentLogic and componentType.componentLogic.onCreate then
    local componentID, componentTYPE, componentCREATOR = component.id, component.type, component.creator

    componentType.componentLogic.onCreate(component) -- not pcall as the function should handle the error methods

    local componentChanged = "Tried to change component '%s' within 'onCreate', type: "..componentTypeName..". This is a protected value at this stage of creation."

    loggerLogic:assert(component.id == componentID, componentChanged:format('id'))
    loggerLogic:assert(component.type == componentTYPE, componentChanged:format('type'))
    loggerLogic:assert(component.parentID == parentID, componentChanged:format('parentID'))
    loggerLogic:assert(component.creator == componentCREATOR, componentChanged:format('creator'))
  end

  component.parentID = nil
  threadCommunication.push({
      func = "addComponent",
      component, parentID, mintmousse._threadID,
    })
  component.parentID = parentID

  return createProxyTable(component)
end

threadContract.newTab = function(title, id, index)
  id = id or utilID.generateID()

  local success, errorMessage = utilID.isValidID(id)
  loggerComponent:assert(success, "Couldn't create tab with given ID. Reason:", errorMessage)

  threadContract.addToLocalHinting(id, "tab")

  threadCommunication.push({
      func = "newTab",
      id, title, index, mintmousse._threadID,
    })

  return createProxyTable({
      id = id,
      title = title,
      parentID = nil,
      creator = mintmousse._threadID,
    })
end

threadContract.removeComponent = function(id)
  local success, errorMessage = utilID.isValidID(id)
  loggerComponent:assert(success, "Gave invalid ID for removal. Gave:", id, ". Reason:", errorMessage)

  threadCommunication.push({
    func = "removeComponent",
    id,
  })
end

return threadContract