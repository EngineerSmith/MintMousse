local PATH = (...):match("^(.*)renderer$")
local ROOT = PATH:match("^(.-)thread%.controller%.$")

local mintmousse = require(ROOT .. "conf")
local lustache = require(ROOT .. "libs.lustache")

local state = require(PATH .. "state")

local loggerRenderer = require(PATH .. "logger"):extend("Renderer")

local renderer = { }

renderer.load = function()

  local javascript, errorMessage = love.filesystem.read(mintmousse.DEFAULT_INDEX_JS)
  if not javascript then
    loggerRenderer:error("Unable to read JavaScript file:", mintmousse.DEFAULT_INDEX_JS, ". Reason:", errorMessage)
    return
  end
  
  local css, errorMessage = love.filesystem.read(mintmousse.DEFAULT_INDEX_CSS)
  if not css then
    loggerRenderer:error("Unable to read CSS file:", mintmousse.DEFAULT_INDEX_CSS, ". Reason:", errorMessage)
    return
  end

  local index, errorMessage = love.filesystem.read(mintmousse.DEFAULT_INDEX_HTML)
  if not index then
    loggerRenderer:error("Unable to read HTML/Mustache file:", mintmousse.DEFAULT_INDEX_HTML, ". Reason:", errorMessage)
    return
  end

  renderer.javascript = javascript
  renderer.css = css
  renderer.index = index


end

-- This feels very confusing, and mix responsibilities, but not really? State holds variable
-- information, and renderer is just using state to cache and retrieve. Needs looking at again
-- with fresh eyes. Perhaps it's because it feels wrong due to state owning these values, but
-- we're interfacing with them directly.
renderer.getIndex = function()
  if state.isDirty then
    state.isDirty = false
    state.index = lustache:render(renderer.index, state)
  end
  return state.index
end

renderer.addJavascript = function(script)
  renderer.javascript = renderer.javascript .. "\n" .. script
end

renderer.addStyling = function(styling)
  renderer.css = renderer.css .. "\n" .. styling 
end

return renderer