local components = {
  componentTypes = { }
}

local lfs = love.filesystem

local functionPattern = "function%s+"

local updatePattern = "_update_(%S+)%s*%(payload%)"

local newPattern = "_new%s*%(payload%)"
local removePattern = "_remove%s*%(payload%)"

local findUpdatePattern = function(script, componentType, outTable)
  local pattern = functionPattern .. type .. updatePattern

  local touched = false
  for v in script:gmatch(pattern) do
    outTable[variable] = true
    touched = true
  end
  
  return touched
end

local findNewRemovePattern = function(script, componentType)
  local mainPattern = functionPattern .. type
  local newPattern = mainPattern .. newPattern
  local removePattern = mainPattern .. removePattern

  local foundNewFunction = script:find(newPattern)
  local foundRemoveFunction = script:find(removePattern)

  return foundNewFunction, foundRemoveFunction
end

components.init = function()
  for _, directory in ipairs(love.mintmousse.COMPONENTS_PATHS) do
    local directoryComponentTypes = components.parseComponentTypes(directory)
    if directoryComponentTypes then
      for _, directoryComponentType in ipairs(directoryComponentTypes) do
        if directoryComponentType ~= "unknown" then
          local componentType = components.componentTypes[directoryComponentType] 
          if not then
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
  --
  components.parseComponentsJavascript(components.componentTypes)

  -- Push final types, and their values
  components.componentTypes["unknown"] = nil
  channel:performAtomic(function()
    channel:pop()
    channel:push(components.componentTypes)
  end)

  -- todo Mustache & lua
  --   do we still need lua? Focus on Mustache first

  local count = 0
  for _ in pairs(components.componentTypes) do
    count = count + 1
  end
  love.mintmousse.info("Components: Found", count, "component types")
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
    if lfs.getInfo(item, "file") then -- Must be file, not symlink to a file
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

components.parseComponentsJavascript = function(components)
  for componentTypeName, componentType in ipairs(components) do
    -- Javascript
    local path --todo function, arg extension
    for i = #componentType.directories, 1, -1 do
      path = componentType.directories[i] .. componentTypeName .. ".js"
      if lfs.getInfo(path, "file") then
        break
      else
        path = nil
      end
    end
    if path then
      local script, errorMessage = lfs.read(path)
      if not script then
        love.mintmousse.warning("Components: Unable to read JS file:", path, ". Reason:", errorMessage)
      else
        -- Updates
        local touched = findUpdatePattern(script, componentTypeName, componentType.updates)
        if not touched then
          componentType.updates = nil
        end
        -- New & Remove
        componentType.hasNewFunction, componentType.hasRemoveFunction = findNewRemovePattern(script, componentTypeName)
      end
    end
  end
end

return components