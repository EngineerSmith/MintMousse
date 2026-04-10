local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")
local codec = require(PATH .. "codec")
local proxy = require(PATH .. "proxy")

local log = mintmousse._logger:extend("Event")

local eventManager = {
  eventCallbacks = { },
}

eventManager.onEvent = function(callbackID, callbackFunction)
  if callbackFunction == nil then return end

  log:assert(type(callbackID) == "string", "onEvent: callbackID expected to be type string! Received:", type(callbackID))
  log:assert(type(callbackFunction) == "function", "onEvent: callbackFunction expected to be type function! Received:", type(callbackFunction))
  eventManager.eventCallbacks[callbackID] = callbackFunction
end

eventManager.removeEvent = function(callbackID)
  log:assert(type(callbackID) == "string", "removeEvent: callbackID expected to be type string! Received:", type(callbackID))
  eventManager.eventCallbacks[callbackID] = nil
end

eventManager.jsEvent = function(callbackID, componentID, encodedSnapshot, values)
  if type(callbackID) ~= "string" or type(componentID) ~= "string" or type(encodedSnapshot) ~= "string" then
    log:warning("MintMousseJSEvent: expected three string arguments, instead received:", type(componentID), type(callbackID), type(encodedSnapshot))
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

  if type(values) == "table" then
    local raw = rawget(component, "__raw")
    for k, v in pairs(values) do
      raw[k] = v
    end
  end

  callbackFunction(component)
end

return eventManager