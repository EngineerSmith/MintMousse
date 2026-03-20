local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")

local eventLogger = mintmousse._logger:extend("Event")

local eventManager = {
  eventCallbacks = { },
}

eventManager.addCallback = function(callbackID, callbackFunction)
  eventManager.eventCallbacks[callbackID] = callbackFunction
end

eventManager.removeCallback = function(callbackID)
  eventManager.eventCallbacks[callbackID] = nil
end

eventManager.jsEvent = function(componentID, callbackID)
  if type(componentID) ~= "string" or type(callbackID) ~= "string" then
    eventLogger:warning("MintMousseJSEvent: expected two string arguments, instead received:", type(componentID), type(callbackID))
    return
  end

  local callbackFunction = eventManager.eventCallbacks[callbackID]
  if not callbackFunction then
    return
  end

  local component = mintmousse.get(componentID)
  callbackFunction(component)
end

return eventManager