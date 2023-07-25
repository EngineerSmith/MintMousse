local lfs = love.filesystem

local helper = requireMintMousse("helper")

local updateFunctionPattern_11 = "^function%s+" -- start of string
local updateFunctionPattern_12 = "\nfunction%s+" -- new line
local updateFunctionPattern_21 = "_update_(%S+)%(" -- <type>_update_(variable)
local updateFunctionPattern_22 = "_update_child_(%S+)%(" -- <type>_update_child_(variable)

-- This scrapes javascript files to find out what variables can be updated
-- Takes function names in the following styles
--  1 <type>_update_<variable> : e.g. card_update_imgTop -> card.imgTop value changes will be reflected on the webpage
--  2 <type>_update_child_<variable> : e.g. buttonGroup_update_child_text -> buttonGroup.components[1].text value will be reflected on the webpage

return function(path)
  local functions = {}

  for _, item in ipairs(lfs.getDirectoryItems(path)) do
    local itemPath = path .. "/" .. item
    if lfs.getInfo(itemPath, "file") then
      local type, extension = helper.getFileNameExtension(item)
      if extension == "js" then
        local updateFunctions, touched = {
          children = {}
        }, false

        local script = lfs.read(itemPath)

        -- parent update functions
        local _, _, variable = script:find(updateFunctionPattern_11 .. type .. updateFunctionPattern_21)
        if variable then
          updateFunctions[variable] = true
          touched = true
        end
        for variable in script:gmatch(updateFunctionPattern_12 .. type .. updateFunctionPattern_21) do
          updateFunctions[variable] = true
          touched = true
        end
        -- child update functions
        local _, _, variable = script:find(updateFunctionPattern_11 .. type .. updateFunctionPattern_22)
        if variable then
          updateFunctions.children[variable] = true
          touched = true
        end
        for variable in script:gmatch(updateFunctionPattern_12 .. type .. updateFunctionPattern_22) do
          updateFunctions.children[variable] = true
          touched = true
        end
        --
        if touched then
          functions[type] = updateFunctions
        end
      end
    end
  end

  return functions
end
