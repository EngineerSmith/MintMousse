local PATH = (...):match("^(.-)[^%.]+$")

local lfs = love.filesystem

local mintmousse = require(PATH .. "conf")
local contract = require(PATH .. "contract")

local loggerLogic = mintmousse._logger:extend("Component"):extend("Logic")

local componentLogic = { }

componentLogic.loadComponentLogic = function(componentTypeName)
  if componentTypeName == "unknown" then
    return
  end

  local componentType = contract.componentTypes[componentTypeName]

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
    loggerLogic:warning("Failed to discover path for component logic(" .. componentTypeName .. ") which was previous found in one of these directories:", table.concat(componentType.directories, ", "))
    return
  end

  local componentLogicLoadFail = "Failed to load component logic! For: " .. componentTypeName .. ". Reason:"

  local success, chunk, errorMessage = pcall(lfs.load, path)
  loggerLogic:assert(success, componentLogicLoadFail, chunk)
  loggerLogic:assert(chunk, componentLogicLoadFail, errorMessage)

  local success, componentLogic = pcall(chunk, mintmousse)
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

  if type(componentType.componentLogic.onChildCreate) ~= "function" then
    loggerLogic:warning(componentLogicLoadFail, "'onChildCreate' wasn't type function.")
    componentType.componentLogic.onChildCreate = nil
  end

  -- All functions
  if type(componentType.componentLogic.onCreate) == "nil" and
     type(componentType.componentLogic.onChildCreate) == "nil"
   then
    loggerLogic:warning(componentLogicLoadFail, "Returned component logic table didn't contain any functions for:", table.concat({ "onCreate", "onChildCreate" }, ", "))
    componentType.componentLogic, componentType.hasComponentLogic = nil, false -- stop it from trying to reload
  end
  return
end

local protectedKeys = {
  "id", "type", "parentID", "creator",
}

local protectedKeyChangeWrapper = function(components, typeName, callbackName, callback, ...)
  local savedStates = { }
  for i, component in ipairs(components) do
    savedStates[i] = { }
    for _, key in ipairs(protectedKeys) do
      savedStates[i][key] = component[key]
    end
  end

  callback(...)

  local componentChangedMsg = "Tried to change component '%s' within '" .. callbackName .. "', type: " .. componentTYPE .. ". This is a protected value at this stage of creation."
  for i, component in ipairs(components) do
    local savedState = savedStates[i]
    for _, key in ipairs(protectedKeys) do
      if component[key] ~= savedState[key] then
        loggerLogic:error(componentChangedMsg:format(key))
      end
    end
  end
end

componentLogic.runOnCreate = function(component, componentType)
  local typeName = component.type
  local callback = componentType.componentLogic.onCreate

  protectedKeyChangeWrapper({ component }, typeName, "onCreate", component)
end

componentLogic.runOnChildCreate = function(childComponent, parentComponent, parentComponentType)
  local typeName = parentComponent.type
  local callback = componentType.componentLogic.onChildCreate

  protectedKeyChangeWrapper({ parentComponent, childComponent }, typeName, "onChildCreate", parentComponent, childComponent)
end

componentLogic.run = function(component, parentComponent)
  componentLogic.loadComponentLogic(component.type)
  if parentComponent then
    componentLogic.loadComponentLogic(parentComponent.type)
  end

  local componentType = contract.componentTypes[component.type]
  if not componentType.componentLogic then
    return
  end

  if componentType.componentLogic.onCreate then
    componentLogic.runOnCreate(component, componentType)
  end

  -- Parent
  if parentComponent.type == "unknown" then
    return
  end
  local parentComponentType = contract.componentTypes[parentComponent.type]
  if not parentComponentType.componentLogic then
    return
  end

  if parentComponentType.componentLogic.onChildCreate then
    componentLogic.runOnChildCreate(component, parentComponent, parentComponentType)
  end
end

return componentLogic