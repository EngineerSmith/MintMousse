local components = {
  componentTypes = { }
}

local lfs = love.filesystem
local controller = love.mintmousse.require("thread.controller")

local functionPattern = "function%s+"

local payloadPattern = "%s*%(%s*payload%s*%)"
local updatePattern = "_update_(%S+)" .. payloadPattern

local newPattern = "_new" .. payloadPattern
local insertPattern = "_insert" .. payloadPattern
local removePattern = "_remove" .. payloadPattern

local findUpdatePattern = function(script, componentType, outTable)
  local pattern = functionPattern .. componentType .. updatePattern

  local touched = false
  for variable in script:gmatch(pattern) do
    outTable[variable] = true
    touched = true
  end
  
  return touched
end

local findNewInsertRemovePattern = function(script, componentType)
  local mainPattern = functionPattern .. componentType
  local newPattern = mainPattern .. newPattern
  local insertPattern = mainPattern .. insertPattern
  local removePattern = mainPattern .. removePattern

  local foundNewFunction = script:find(newPattern) ~= nil
  local foundInsertFunction = script:find(insertPattern) ~= nil
  local foundRemoveFunction = script:find(removePattern) ~= nil

  return foundNewFunction, foundInsertFunction, foundRemoveFunction
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
              hasMustacheFile = directoryComponentType.hasMustacheFile,
            }
          else
            table.insert(componentType.directories, directory)
            componentType.hasMustacheFile = componentType.hasMustacheFile or directoryComponentType.hasMustacheFile
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

  -- Push final types, and their update values
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
        table.insert(componentTypes, { name = name, hasMustacheFile = (extension == "html" or extension == "mustache") })
        lookup[nameLower] = #componentTypes
      else
        local componentType = componentTypes[lookup[nameLower]]
        componentType.hasMustacheFile = componentType.hasMustacheFile or (extension == "html" or extension == "mustache")
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
        local touched = findUpdatePattern(script, componentTypeName, componentType.updates)
        if not touched then
          componentType.updates = nil
        end
        -- New & Remove functions
        componentType.hasNewFunction, componentType.hasInsertFunction, componentType.hasRemoveFunction = findNewInsertRemovePattern(script, componentTypeName)
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