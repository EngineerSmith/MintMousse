local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")

local log = mintmousse._logger:extend("Pages")

local pages = { }

pages.buildPage = function(requirePath, config, index)
  config = type(config) == "table" and config or { }

  local success, page = pcall(require, requirePath)
  if not success then
    log:error("Couldn't load page module '" .. tostring(requirePath) .. ". Reason:", page)
    return nil
  end
  if type(page) ~= "table" or type(page.build) ~= "function" then
    log:error("Invalid page module '" .. tostring(requirePath) .. "'. Must return table with a .build(tab, config) function")
    return nil
  end

  local tab = mintmousse.newTab(config.tabName or page.name or "Unnamed Page", nil, index)
  page.build(tab, config)

  log:info("Built and added page '" .. tostring(tab.name) .. "'")
  return tab
end

return pages