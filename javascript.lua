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

local updateFunctionPattern = "function%s+update_(%S+)%("
local updateFunctionPatternStart = "^" .. updateFunctionPattern
local updateFunctionPatternNewLine = "\n" .. updateFunctionPattern

javascript.processJavascriptFunctions = function(script)
  local updateFunctions = {}
  local _, _, variable = script:find(updateFunctionPatternStart)
  if variable then
    updateFunctions[variable] = true
  end
  for variable in script:gmatch(updateFunctionPatternNewLine) do
    updateFunctions[variable] = true
  end
  return #updateFunctions > 0 and updateFunctions or nil
end

javascript.getUpdateFunctions = function(scripts)
  local updateFunctions = {}
  for index, script in pairs(scripts) do
    updateFunctions[index] = javascript.processJavascriptFunctions(script)
  end
  return updateFunctions
end

return javascript
