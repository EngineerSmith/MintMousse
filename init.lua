local PATH = ... .. "."
local dirPATH = PATH:gsub("%.", "/")
local componentPath = dirPATH .. "components"

local channelInOut = "MintMousse"

local controller = require(PATH .. "controller")
local javascript = require(PATH .. "javascript")
local svg = require(PATH .. "svg")

local thread = love.thread.newThread(dirPATH .. "thread.lua")

local globalID = 0
local setID -- function set later

local formatComponent = function(component, id)
  if component.type then
    if not component.id then
      component.id = id
      id = id + 1
    elseif type(component.id) == "string" then
      -- todo allow for certain punctuation characters e.g. [ . _ , ; ] (not ' or " )
      assert(not component.id:find("%W"), "You can't use non-alphanumeric characters in an id (This is to avoid html issues)")
    end
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

  thread:start(PATH, dirPATH, settings, website, channelInOut, channelInOut)

  return controller(website, jsUpdateFunctions, love.thread.getChannel(channelInOut))
end

love.handlers[channelInOut] = function(...)
  if love[channelInOut] then
    love[channelInOut](...)
  end
end

--[[
 TODO list

 2) Complete all todo comments
 3) Add component factories to make it easier to make a website than creating a massive table (but keep option for table for more control)
 4) Add futher component concepts
 4.1) 2D graph (line graph, point graph); Status lights (badages + inc. tab update ping); interactive list; crash report; form (text input, etc.); interactive world map;
 4.2) Maybes: toast updates; AppleCake support;
 5) Custom support for message styles using lustache? e.g. how I did logging in mintlilac
 5.1) Reconsider adding css classes instead of intenting styling within elements like in mintlilac
 6) Add time since...
 6.1) Add time since last update on connected hover
 6.2) Add time since last connected on disconnect hover
 6.3) Add option to add timestamp that js updates
 6.3.1) e.g. "X was 5 minutes ago", "X was 10 hours ago", "X was 4 days ago"

 Considerations: Continuous tcp connection? 
  Benefits: Easily push updates to live data (might keep a tcp connect open for certain components + warn users of this drawback + could add support for non-continous tcp connections)
  Drawback: Keeps a port open; which can limit resources for the system if multiple servers are on one machine and each server is serving 10+ mintmousse it adds up quickly
]]

return mintMousse
