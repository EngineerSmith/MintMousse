local components = {
  componentTypes = { }
}

local lfs = love.filesystem
local controller = love.mintmousse.require("thread.controller")

local functionPattern = "function%s+"

local updatePattern = "_update_(%S+)%s*%(%s*payload%s*%)"

local newPattern = "_new%s*%(%s*payload%s*%)"
local removePattern = "_remove%s*%(%s*payload%s*%)"

local findUpdatePattern = function(script, componentType, outTable)
  local pattern = functionPattern .. componentType .. updatePattern

  local touched = false
  for variable in script:gmatch(pattern) do
    outTable[variable] = true
    touched = true
  end
  
  return touched
end

local findNewRemovePattern = function(script, componentType)
  local mainPattern = functionPattern .. componentType
  local newPattern = mainPattern .. newPattern
  local removePattern = mainPattern .. removePattern

  local foundNewFunction = script:find(newPattern) ~= nil
  local foundRemoveFunction = script:find(removePattern) ~= nil

  return foundNewFunction, foundRemoveFunction
end

components.init = function()
  for _, directory in ipairs(love.mintmousse.COMPONENTS_PATHS) do
    local directoryComponentTypes = components.parseComponentTypes(directory)
    if directoryComponentTypes then
      for _, directoryComponentType in ipairs(directoryComponentTypes) do
        if directoryComponentType ~= "unknown" then
          local componentType = components.componentTypes[directoryComponentType] 
          if not componentType then
            components.componentTypes[directoryComponentType] = {
              directories = { directory },
              updates = { },
            }
          else
            table.insert(componentType.directories, directory)
          end
        else
          love.mintmousse.warning("Components: Found a component type named 'unknown'. This is a protected keyword within MintMousse. Directory:", directory)
        end
      end
    end
  end
  local channel = love.thread.getChannel(love.mintmousse.READONLY_BASIC_TYPES_ID)
  components.componentTypes["unknown"] = true
  channel:push(components.componentTypes) -- All threads await for this push
  components.componentTypes["unknown"] = nil
  --
  components.parseComponentsJavascript(components.componentTypes)

  -- Push final types, and their values
  channel:performAtomic(function()
    channel:pop()
    channel:push(components.componentTypes)
  end)

  components.parseComponentsMustache(components.componentTypes)
  components.parseComponentsStyling(components.componentTypes)

  components.logStats(components.componentTypes)
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
      local name = item:match("^(.+)%..*$")
      local nameLower = name:lower()
      if not lookup[nameLower] then
        lookup[nameLower] = true
        table.insert(componentTypes, name)
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
  for componentTypeName, componentType in pairs(components) do
    local path = findPath(componentTypeName, componentType, ".js")
    if path then
      local script, errorMessage = lfs.read(path)
      if not script then
        love.mintmousse.warning("Components: Unable to read JS file:", path, ". Reason:", errorMessage)
      else
        controller.addJavascript(script)

        -- Updates
        local touched = findUpdatePattern(script, componentTypeName, componentType.updates)
        if not touched then
          componentType.updates = nil
        end
        -- New & Remove functions
        componentType.hasNewFunction, componentType.hasRemoveFunction = findNewRemovePattern(script, componentTypeName)
      end
    end
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
  love.mintmousse.info("Components: Found", count, "component types, with a total of", variable, "values that can be updated")
end

return components