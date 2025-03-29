local components = {
  componentTypes = { }
}

local lfs = love.filesystem

components.init = function()
  for _, directory in ipairs(love.mintmousse.COMPONENTS_PATHS) do
    local directoryComponentTypes = components.parseComponentTypes(directory)
    if directoryComponentTypes then
      for _, directoryComponentType in ipairs(directoryComponentTypes) do
        if not components.componentTypes[directoryComponentType] then
          components.componentTypes[directoryComponentType]= { }
        end
      end
    end
  end
  local channel = love.thread.getChannel(love.mintmousse.READONLY_BASIC_TYPES_ID)
  channel:push(components.componentTypes)
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
    if lfs.getInfo(item, "file") then
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

components.parseComponentFunctions = function(directory)
  local info = lfs.getInfo(directory)
  if not info.type == "directory" and not info.type == "symlink" then
    love.mintmousse.warning("Components: Given directory does not exist:", directory)
    return
  end

  --local name, extensions = item:match("^(.+)%..-$"), item:match("^.+%.(.+)$"):lower()

end

return components