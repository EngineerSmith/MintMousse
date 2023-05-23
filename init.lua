local PATH = ... .. "."
local dirPATH = PATH:gsub("%.", "/")
local componentPath = dirPATH .. "components"

local channelIn = "MintMousse"

local controller = require(PATH .. "controller")
local javascript = require(PATH .. "javascript")
local svg = require(PATH .. "svg")

local thread = love.thread.newThread(dirPATH .. "thread.lua")

local globalID = 0
local setID -- function set later

local formatComponent = function(component, id)
  if component.type then
    component.id = id
    id = id + 1
  end
  if component.children then
    id = setID(component.children, id)
  end
  return id
end

setID = function(settings, id)
  id = id or globalID
  if settings.type then
    return formatComponent(settings, id)
  end
  for _, component in ipairs(settings) do
    id = formatComponent(component, id)
  end
  return id
end

local jsUpdateFunctions = javascript.getUpdateFunctions(javascript.readScripts(componentPath))

local formatIcon = function(icon)
  if type(icon) == "string" then
    if icon:find("%.svg$") then
      return love.filesystem.read(icon)
    end
    icon = {
      emoji = icon
    }
  end
  -- Emoji
  if type(icon.emoji) == "string" then
    local len = #icon.emoji
    assert(len == 2 or len == 4,
      "It is determinded that you haven't given an emoji, raise an issue if you see this on github")
  else
    error("icon.emoji must be type string")
  end
  -- Shape
  assert(icon.shape == "rect" or icon.shape == "circle" or icon.shape == "nil",
    "icon.shape must be 'rect', 'circle', or nil")
  if icon.shape == "rect" then
    icon.rect = true
  end
  if icon.shape == "circle" then
    icon.circle = true
  end
  assert(not (icon.rect and icon.circle), "Cannot display both rect and circle at the same time")
  -- Color
  local count
  if type(icon.color) == "string" then
    icon.color, count = icon.color:gsub("^#", "%%23")
    assert(svg.color[icon.color] or count ~= 0, icon.color.." is not a valid color")
  else
    icon.color = nil
  end
    -- inside
  if type(icon.insideColor) == "string" then
    icon.insideColor, count = icon.insideColor:gsub("^#", "%%23")
    assert(svg.color[icon.insideColor] or count ~= 0, icon.insideColor.." is not a valid color")
  else
    icon.insideColor = icon.color
  end
    -- outside
  if type(icon.outsideColor) == "string" then
    icon.outsideColor, count = icon.outsideColor:gsub("^#", "%%23")
    assert(svg.color[icon.outsideColor] or count ~= 0, icon.outsideColor.." is not a valid color")
  else
    icon.outsideColor = icon.color
  end

  return icon
end

local mintMousse = {}

mintMousse.start = function(settings, website) -- todo add settings validation

  if type(settings.pollInterval) ~= "number" then
    settings.pollInterval = 1000
  end

  -- website
    -- icon
  if website.icon then
    website.icon = formatIcon(website.icon)
  end
    -- tabs

  if type(website.tabs) ~= "table" or #website.tabs < 1 then
    error("Requires at least one tab!")
  end

  local active = false
  for index, tab in ipairs(website.tabs) do
    if tab.active then
      active = true
    end
    tab.id = tab.name .. index
    if tab.components then
      globalID = setID(tab.components)
    end
  end
  if not active then
    website.tabs[1].active = true
  end

  website.pollInterval = settings.pollInterval

  thread:start(PATH, dirPATH, settings, website, channelIn, "mintMousse") -- todo better events/channel names

  return controller(website, jsUpdateFunctions, love.thread.getChannel(channelIn))
end

love.handlers["mintMousse"] = function(...)
  print(...)
end

--[[
 TODO list

 1) Handle update to components
 1.1) Add handling on main thread to update components
 1.1.1) Find a system that works well with metatables
 1.1.2) Push update to the thread
 1.2) Add handling on thread to update components
 1.2.1) accept incoming update from the main thread
 1.2.2) Re-render components so they can be ready for new index request
 1.2.4) Add handling for webpage to request updates (Should they just request the render of the component and replace it?)
 2) Complete all todo comments
 3) Add component factories to make it easier to make a website than creating a massive table (but keep option for table for more control)
 4) Add futher component concepts
 4.1) 2D graph (line graph, point graph); Status lights (badages + inc. tab update ping); interactive list; crash report; form (text input, etc.); interactive world map;
 4.2) Maybes: toast updates; AppleCake support;
 5) Custom support for message styles using lustache? e.g. how I did logging in mintlilac
 5.1) Reconsider adding css classes instead of intenting styling within elements like in mintlilac

 Considerations: Continuous tcp connection? 
  Benefits: Easily push updates to live data (might keep a tcp connect open for certain components + warn users of this drawback + could add support for non-continous tcp connections)
  Drawback: Keeps a port open; which can limit resources for the system if multiple servers are on one machine and each server is serving 10+ mintmousse it adds up quickly
]]

return mintMousse
