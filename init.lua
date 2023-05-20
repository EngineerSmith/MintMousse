local PATH = ... .. "."
local dirPATH = PATH:gsub("%.", "/")

local controller = require(PATH .. "controller")

local thread = love.thread.newThread(dirPATH .. "thread.lua")

local mintMousse = {}

mintMousse.start = function(settings, website) -- todo add settings validation
  
  if type(settings.pollInterval) ~= "number" then
    settings.pollInterval = 1000
  end

  if type(website.tabs) ~= "table" or #website.tabs < 1 then
    error("Requires at least one tab!")
  end
  local active = false
  for index, tab in ipairs(website.tabs) do
    if tab.active then
      active = true
    end
    tab.id = tab.name .. index
  end
  if not active then
    website.tabs[1].active = true
  end

  website.pollInterval = settings.pollInterval

  thread:start(PATH, dirPATH, settings, website, "foo", "bar") -- todo better events/channel names

  return controller(website)
end

love.handlers["bar"] = function(...)
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
