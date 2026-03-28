local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")
local codec = require(PATH .. "codec")
local proxy = require(PATH .. "proxy")

local eventLogger = mintmousse._logger:extend("Event")

local eventManager = {
  eventCallbacks = { },
}

eventManager.onEvent = function(callbackID, callbackFunction)
  eventManager.eventCallbacks[callbackID] = callbackFunction
end

eventManager.removeEvent = function(callbackID)
  eventManager.eventCallbacks[callbackID] = nil
end

eventManager.jsEvent = function(callbackID, componentID, encodedSnapshot)
  if type(callbackID) ~= "string" or type(componentID) ~= "string" or type(encodedSnapshot) ~= "string" then
    eventLogger:warning("MintMousseJSEvent: expected three string arguments, instead received:", type(componentID), type(callbackID), type(encodedSnapshot))
    return
  end

  local callbackFunction = eventManager.eventCallbacks[callbackID]
  if not callbackFunction then
    return
  end

  local component
  if mintmousse.has(componentID) then
    component = mintmousse.get(componentID)
  else
    local snapshot = codec.decode(encodedSnapshot)
    component = proxy.createTempProxy(snapshot)
    -- Temp components aren't added to the lookup for .has or .get
  end

  callbackFunction(component)
end

return eventManager