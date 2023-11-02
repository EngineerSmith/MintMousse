local PATH = ... .. "."
local dirPATH = PATH:gsub("%.", "/")

require(PATH .. "global")(PATH)

local channelInOut = "MintMousse"
local channelDictionary = "MintMousseDictionary"

local controller = requireMintMousse("controller")
local getJavascriptFunctions = requireMintMousse("javascript")
local validateIcon = requireMintMousse("icon")
local builder = requireMintMousse("builder")

local thread = love.thread.newThread(dirPATH .. "thread/init.lua")

-- dictionary --
  local dictionary, lookup = {"func", "addNewTab", "removeTab", "addNewComponent", "removeComponent"}, {}
  for _, word in ipairs(dictionary) do
    lookup[word] = true
  end

  local jsUpdateFunctions = getJavascriptFunctions(dirPATH .. "components")

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
    for childVariable in pairs(variables.children) do
      if not lookup[childVariable] then
        table.insert(dictionary, childVariable)
        lookup[childVariable] = true
      end
    end
  end

  local dictionaryChannel = love.thread.getChannel(channelDictionary)
  dictionaryChannel:push(dictionary)
  dictionary, lookup = nil, nil
--

local settings_hostAllowed_Str = "*, 0.0.0.0, localhost, or 127.0.0.1"
local settings_hostAllowed = {
  ["*"] = true,
  ["0.0.0.0"] = true,
  ["localhost"] = true,
  ["127.0.0.1"] = true
}

local validateSettings = function(settings)
  local assert = function(bool, errorMessage)
    if not bool then
      errorMintMousse("Setting Validation: " .. tostring(errorMessage))
    end
  end

  -- host
  if type(settings.host) ~= "string" then
    settings.host = "127.0.0.1"
  end
  assert(settings_hostAllowed[settings.host], "Host must be: " .. settings_hostAllowed_Str)

  -- port
  assert(type(settings.port) == "number", "Port must be type number")
  assert(settings.port >= 0 and settings.port <= 65535, "Port must be in the range of 0-65535")
  if settings.backupPort then
    assert(type(settings.backupPort) == "number", "Backup port must be type number")
    assert(settings.backupPort >= 0 and settings.backupPort <= 65535, "Backup port must be in the range of 0-65535")
    assert(settings.backupPort ~= settings.port, "Backup port must be a different value to port")
  end

  -- poll interval
  if type(settings.pollInterval) ~= "number" then
    settings.pollInterval = 250
  end
  assert(settings.pollInterval >= 75,
    "Poll Interval must be greater than or equal to 75ms. 200ms is a value I recommended; which will give at least 4 updates a second to each connected client")
end

local mintMousse = {
  newBuilder = builder.new
}

mintMousse.start = function(settings, webpage)

  validateSettings(settings)

  -- build webpage if created using the builder
  if getmetatable(webpage) == builder then
    webpage = webpage:_build()
  end

  -- icon
  if webpage.icon then
    webpage.icon = validateIcon(PATH, webpage.icon)
  end
  -- tabs

  if type(webpage.tabs) ~= "table" or #webpage.tabs < 1 then
    errorMintMousse("Webpage Validation: Requires at least one tab!")
  end

  local active = false
  for index, tab in ipairs(webpage.tabs) do
    if tab.active then
      if active then
        tab.active = false -- only allow 1 active tab; picks first tab that has the active flag
      end
      active = true
    end
    tab.id = tab.name:gsub("%s", "_") .. index
  end
  if not active then
    webpage.tabs[1].active = true
  end

  -- update polling
  webpage.pollInterval = settings.pollInterval

  -- Lets go
  local controller = controller(dirPATH, webpage, dictionaryChannel, jsUpdateFunctions,
    love.thread.getChannel(channelInOut))

  thread:start(PATH, dirPATH, settings, webpage, channelInOut, channelInOut, channelDictionary)

  return controller
end

love.handlers[channelInOut] = function(enum, ...)
  if enum == "event" then
    local event, variable = ...
    if love[event] then
      love[event](variable)
    end
  elseif enum == "print" then
    local str = select(1, ...)
    print(str)
  else
    print(enum, ...) -- debug
  end
end

--[[
 TODO list
 
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
 6.3.2) support patterns for custom text
 7) Session id
 7.1) If session id is different within webpage: force reload
 7.1.1) This is to correct the page if the webserver is restarted "too quickly"
 8) Complete all todo comments
 9) Add custom httpErrorPages without having to edit repo
]]

return mintMousse
