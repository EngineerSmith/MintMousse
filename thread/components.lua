local components = {
  componentTypes = { }
}

local lfs = love.filesystem
local controller = love.mintmousse.require("thread.controller")

--[[

I made this over engineered; but even if these variable values are updated.
  They would have to be updated in the controller which reconstructs the function
    names to call these found JS functions. So, it is best not to change them \o/

]]

local functionPattern = "function%s+"
local payloadPattern = "%s*%(%s*payload%s*%)"

-- These are optional variables to help to create the patterns
local updatePrefix = "_update_" 
local childIdentifier = "child_"
--   The childIdentifier is used later to check if the updatePattern has captured a child value
--   if the patterns are truly unique; then this can be undefined. E.g. updatePattern = "_update_"; updateChildPattern = "_updateChild_"

local updatePattern = updatePrefix .. "(%S+)" .. payloadPattern
local updateChildPattern = updatePrefix .. childIdentifier .. "(%S+)" .. payloadPattern

local eventPrefix = "_event_"
local eventPattern = eventPrefix .. "(%S+)" .. "%s*%(%s*event%s*%)"

local newPattern = "_new" .. payloadPattern
local insertPattern = "_insert" .. payloadPattern
local removePattern = "_remove" .. payloadPattern
local removeChildPattern = "_remove_child" .. payloadPattern

local findUpdatePatterns = function(script, componentType, updateTable, updateChildTable)
  local fullUpdatePattern = functionPattern .. componentType .. updatePattern
  local fullUpdateChildPattern = functionPattern .. componentType .. updateChildPattern

  -- Component update values
  local touchedUpdateTable = false
  for variable in script:gmatch(fullUpdatePattern) do
    if type(childIdentifier) ~= "string" or childIdentifier == "" or not variable:find("^" .. childIdentifier) then
      updateTable[variable] = true
      touchedUpdateTable = true
    end
  end

  -- Component children update values
  local touchedUpdateChildTable = false
  for variable in script:gmatch(fullUpdateChildPattern) do
    updateChildTable[variable] = true
    touchedUpdateChildTable = true
  end
  
  return touchedUpdateTable, touchedUpdateChildTable
end

local findNewInsertRemovePattern = function(script, componentType)
  local mainPattern = functionPattern .. componentType
  local newPattern = mainPattern .. newPattern
  local insertPattern = mainPattern .. insertPattern
  local removePattern = mainPattern .. removePattern
  local removeChildPattern = mainPattern .. removeChildPattern

  local foundNewFunction = script:find(newPattern) ~= nil
  local foundInsertFunction = script:find(insertPattern) ~= nil
  local foundRemoveFunction = script:find(removePattern) ~= nil
  local foundRemoveChildFunction = script:find(removeChildPattern) ~= nil

  return foundNewFunction, foundInsertFunction, foundRemoveFunction, foundRemoveChildFunction
end

local findEventPattern = function(script, componentType, eventsTable)
  local fullEventPattern = functionPattern .. componentType .. eventPattern

  for variable in script:gmatch(fullEventPattern) do
    eventsTable[variable] = true
  end
end

components.init = function()
  for _, directory in ipairs(love.mintmousse.COMPONENTS_PATHS) do
    local directoryComponentTypes = components.parseComponentTypes(directory)
    if directoryComponentTypes then
      for _, directoryComponentType in ipairs(directoryComponentTypes) do
        if directoryComponentType.name ~= "unknown" then
          local componentType = components.componentTypes[directoryComponentType.name]
          if not componentType then
            components.componentTypes[directoryComponentType.name] = {
              directories = { directory },
              updates = { },
              childUpdates = { },
              events = { },
              hasMustacheFile = directoryComponentType.hasMustacheFile,
              hasComponentLogic = directoryComponentType.hasComponentLogic,
            }
          else
            table.insert(componentType.directories, directory)
            componentType.hasMustacheFile = componentType.hasMustacheFile or directoryComponentType.hasMustacheFile
            componentType.hasComponentLogic = componentType.hasComponentLogic or directoryComponentType.hasComponentLogic
          end
        else
          love.mintmousse.warning("Components: Found a component type named 'unknown'. This is a protected keyword within MintMousse. Directory:", directory)
        end
      end
    end
  end
  local channel = love.thread.getChannel(love.mintmousse.READONLY_BASIC_TYPES_ID)
  components.componentTypes["unknown"] = true
  channel:push(components.componentTypes) -- All threads await for this push; releases block
  components.componentTypes["unknown"] = nil

  -- ==== --

  components.parseComponentsJavascript(components.componentTypes)

  -- Push final types, and their updated values
  channel:performAtomic(function()
    channel:pop()
    channel:push(components.componentTypes)
  end)

  components.parseComponentsMustache(components.componentTypes)
  components.parseComponentsStyling(components.componentTypes)

  components.logStats(components.componentTypes)

  controller.componentTypes = components.componentTypes
end

components.parseComponentTypes = function(directory)
  local info = lfs.getInfo(directory)
  if not info.type == "directory" and not info.type == "symlink" then
    love.mintmousse.warning("Components: Given directory does not exist:", directory)
    return
  end

  local componentTypes, lookup = { }, { }

  -- Symlink may not be a directory; but lfs.getDirectoryItems doesn't care and will return an empty table
  for _, item in ipairs(lfs.getDirectoryItems(directory)) do
    if lfs.getInfo(directory..item, "file") then -- Must be file, not symlink to a file
      local name, extension = item:match("^(.+)%.(.+)$")
      local nameLower, extension = name:lower(), extension:lower()
      if not lookup[nameLower] then
        table.insert(componentTypes, {
          name = name,
          hasMustacheFile = (extension == "html" or extension == "mustache"),
          hasComponentLogic = (extension == "lua"),
        })
        lookup[nameLower] = #componentTypes
      else
        local componentType = componentTypes[lookup[nameLower]]
        componentType.hasMustacheFile = componentType.hasMustacheFile or (extension == "html" or extension == "mustache")
        componentType.hasComponentLogic = componentType.hasComponentLogic or (extension == "lua")
      end
    end
  end

  return #componentTypes ~= 0 and componentTypes or nil
end

local findPath = function(componentTypeName, componentType, extension)
  local path
  for i = #componentType.directories, 1, -1 do
    path = componentType.directories[i] .. componentTypeName .. extension
    if lfs.getInfo(path, "file") then
      break
    else
      path = nil
    end
  end
  return path
end

components.parseComponentsJavascript = function(components)
  local scripts = { }
  for componentTypeName, componentType in pairs(components) do
    local path = findPath(componentTypeName, componentType, ".js")
    if path then
      local script, errorMessage = lfs.read(path)
      if not script then
        love.mintmousse.warning("Components: Unable to read JS file:", path, ". Reason:", errorMessage)
      else
        table.insert(scripts, script)

        -- Updates
        local touchedUpdateTable, touchedUpdateChildTable = findUpdatePatterns(script, componentTypeName, componentType.updates, componentType.childUpdates)
        if not touchedUpdateTable then
          componentType.updates = nil
        end
        if not touchedUpdateChildTable then
          componentType.childUpdates = nil
        end
        -- New & Remove functions
        componentType.hasNewFunction, componentType.hasInsertFunction,
        componentType.hasRemoveFunction, componentType.hasRemoveChildFunction = findNewInsertRemovePattern(script, componentTypeName)
        -- Events
        findEventPattern(script, componentTypeName, componentType.events)
      end
    end
  end
  if #scripts > 0 then
    controller.addJavascript(table.concat(scripts, "\r\n"))
  end
end

components.parseComponentsMustache = function(components)
  for componentTypeName, componentType in pairs(components) do
    local path = findPath(componentTypeName, componentType, ".html")
    if not path then
      path = findPath(componentTypeName, componentType, ".mustache")
    end
    if path then
      local script, errorMessage = lfs.read(path)
      if not script then
        love.mintmousse.warning("Components: Unable to read HTML/Mustache file:", path, ". Reason:", errorMessage)
      else
        componentType.mustache = script
      end
    end
  end
end

components.parseComponentsStyling = function(components)
  for componentTypeName, componentType in pairs(components) do
    local path = findPath(componentTypeName, componentType, ".css")
    if path then
      local styling, errorMessage = lfs.read(path)
      if not styling then
        love.mintmousse.warning("Components: Unable to read CSS file:", path, ". Reason:", errorMessage)
      else
        controller.addStyling(styling)
      end
    end
  end
end

components.logStats = function(components)
  local count, variable = 0, 0
  for _, componentType in pairs(components) do
    count = count + 1
    if componentType.updates then
      for _ in pairs(componentType.updates) do
        variable = variable + 1
      end
    end
  end
  love.mintmousse.info("Components: Found", count, "component types, with a total of", variable, "values that can be updated live.")
end

return components