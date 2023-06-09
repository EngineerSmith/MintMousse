local lfs = love.filesystem

local javascript = {}

local getFileNameExtension = function(file)
  return file:match("^(.+)%..-$"), file:match("^.+%.(.+)$"):lower()
end

javascript.readScripts = function(path)
  local scripts = {}

  for _, item in ipairs(lfs.getDirectoryItems(path)) do
    local filepath = path .. "/" .. item
    if lfs.getInfo(filepath, "file") then
      local name, extension = getFileNameExtension(item)
      if extension == "js" then
        scripts[name] = lfs.read(filepath)
      end
    end
  end

  return scripts
end

local updateFunctionPattern_11 = "^function%s+" -- string start match
local updateFunctionPattern_12 = "\nfunction%s+" -- new line match
local updateFunctionPattern_21 = "_update_(%S+)%(" -- <type>_update_(variable)
local updateFunctionPattern_22 = "_update_child_(%S+)%(" -- <type>_update_child_(variable)

javascript.processJavascriptFunctions = function(type, script)
  local updateFunctions, touched = { children = { }}, false
  local _, _, variable = script:find(updateFunctionPattern_11 .. type .. updateFunctionPattern_21)
  if variable then
    updateFunctions[variable] = true
    touched = true
  end
  for variable in script:gmatch(updateFunctionPattern_12 .. type .. updateFunctionPattern_21) do
    updateFunctions[variable] = true
    touched = true
  end
  --
  local _, _, variable = script:find(updateFunctionPattern_11 .. type .. updateFunctionPattern_22)
  if variable then
    updateFunctions.children[variable] = true
    touched = true
  end
  for variable in script:gmatch(updateFunctionPattern_12 .. type .. updateFunctionPattern_22) do
    updateFunctions.children[variable] = true
    touched = true
  end
  return touched and updateFunctions or nil
end

javascript.getUpdateFunctions = function(scripts)
  local updateFunctions = {}
  for type, script in pairs(scripts) do
    updateFunctions[type] = javascript.processJavascriptFunctions(type, script)
  end
  return updateFunctions
end

return javascript
