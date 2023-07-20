local PATH = ... .. "."
local dirPATH = PATH:gsub("%.", "/")

local channelInOut = "MintMousse"
local channelDictionary = "MintMousseDictionary"

local controller = require(PATH .. "controller")
local javascript = require(PATH .. "javascript")
local svg = require(PATH .. "svg")

local thread = love.thread.newThread(dirPATH .. "thread.lua")

local jsUpdateFunctions = javascript.getUpdateFunctions(javascript.readScripts(dirPATH .. "components"))

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
      "It is determined that you haven't given an emoji, raise an issue if you see this on github")
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
    assert(svg.color[icon.color] or count ~= 0, icon.color .. " is not a valid color")
  else
    icon.color = nil
  end
  -- inside
  if type(icon.insideColor) == "string" then
    icon.insideColor, count = icon.insideColor:gsub("^#", "%%23")
    assert(svg.color[icon.insideColor] or count ~= 0, icon.insideColor .. " is not a valid color")
  else
    icon.insideColor = icon.color
  end
  -- outside
  if type(icon.outsideColor) == "string" then
    icon.outsideColor, count = icon.outsideColor:gsub("^#", "%%23")
    assert(svg.color[icon.outsideColor] or count ~= 0, icon.outsideColor .. " is not a valid color")
  else
    icon.outsideColor = icon.color
  end

  return icon
end

local settings_host_allowedStr = "*, 0.0.0.0, localhost, or 127.0.0.1"
local settings_hostAllowed = {
  ["*"] = true,
  ["0.0.0.0"] = true,
  ["localhost"] = true,
  ["127.0.0.1"] = true
}

local validateSettings = function(settings)
  local error = function(errMsg)
    error("MintMousse settings: " .. errMsg or error("MintMousse settings: Tell a programmer you reached here."))
  end

  -- host
  if type(settings.host) ~= "string" then
    settings.host = "127.0.0.1"
  end
  if not settings_hostAllowed[settings.host] then
    error("Host must be " .. settings_host_allowedStr)
  end

  -- port
  if type(settings.port) ~= "number" then
    error("Port must be type number")
  end
  if settings.port < 0 or settings.port > 65535 then
    error("Port must be in the range of 0-65535")
  end
  if settings.backupPort then
    if type(settings.backupPort) ~= "number" then
      error("Backup Port must be type number")
    end
    if settings.backupPort < 0 or settings.backupPort > 65535 then
      error("Backup Port must be in the range of 0-65535")
    end
    if settings.backupPort == settings.port then
      error("Backup Port must be a different value to Port")
    end
  end

  -- poll interval
  if type(settings.pollInterval) ~= "number" then
    settings.pollInterval = 1000
  end
  if settings.pollInterval < 100 then
    error("Poll Interval must be greater than or equal to 100ms (500ms is recommended lowest value)")
  end
end

local mintMousse = {}

mintMousse.start = function(settings, website)

  validateSettings(settings)

  -- preprocessing
  local dictionaryChannel = love.thread.getChannel(channelDictionary)

  local dictionary, lookup = {}, {}
  for type, variables in pairs(jsUpdateFunctions) do
    if not lookup[type] then
      table.insert(dictionary, type)
      lookup[type] = true
    end
    for variable in pairs(variables) do
      if not lookup[variable] then
        table.insert(dictionary, variable)
        lookup[variable] = true
      end
    end
  end
  table.insert(dictionary, "new")
  table.insert(dictionary, "remove")

  table.insert(dictionary, "tab")
  table.insert(dictionary, "component")

  dictionaryChannel:push(dictionary)
  dictionary, lookup = nil, nil
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
    tab.id = tab.name:gsub("%s", "_") .. index
  end
  if not active then
    website.tabs[1].active = true
  end

  website.pollInterval = settings.pollInterval

  local controller = controller(dirPATH, website, dictionaryChannel, jsUpdateFunctions, love.thread.getChannel(channelInOut))

  thread:start(PATH, dirPATH, settings, website, channelInOut, channelInOut, channelDictionary)

  return controller
end

love.handlers[channelInOut] = function(enum, ...)
  if enum == "event" then
    local event, variable = ...
    if love[event] then
      love[event](variable)
    end
  else
    print(enum, ...)
  end
end

--[[
 TODO list
 
 3) Add component factories to make it easier to make a website than creating a massive table (but keep option for table for more control)
 4) Add further component concepts
 4.1) 2D graph (line graph, point graph); Status lights (badges + inc. tab update ping); interactive list; crash report; form (text input, etc.); interactive world map;
 4.2) Maybes: toast updates; AppleCake support;
 5) Custom support for message styles using lustache? e.g. how I did logging in mintlilac
 5.1) Reconsider adding css classes instead of indenting styling within elements like in mintlilac
 6) Add time since...
 6.1) Add time since last update on connected hover
 6.2) Add time since last connected on disconnect hover
 6.3) Add option to add timestamp that js updates
 6.3.1) e.g. "X was 5 minutes ago", "X was 10 hours ago", "X was 4 days ago"
 7) Session id
 7.1) If session id is different within webpage: force reload
 7.1.1) This is to correct the page if the webserver is restarted "too quickly"
 8) Complete all todo comments

 Considerations: Continuous tcp connection? 
  Benefits: Easily push updates to live data (might keep a tcp connect open for certain components + warn users of this drawback + could add support for non-continuous tcp connections)
  Drawback: Keeps a port open; which can limit resources for the system if multiple servers are on one machine and each server is serving 10+ mintmousse it adds up quickly
]]

return mintMousse
