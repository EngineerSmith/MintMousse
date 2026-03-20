local PATH = (...):match("^(.*)state$")
local ROOT = PATH:match("^(.-)thread%.controller%.$")

local mintmousse = require(ROOT .. "conf")

local loggerState = require(PATH .. "logger"):extend("State")

local state = {
  idMap = { },
  tabs = { },
  isDirty = true,
  --
  title = "MintMousse",
}

state.setTitle = function(title)
  if state.title == title then
    return
  end

  if type(title) == "string" then
    state.title = title
    state.isDirty = true
  end
end

state.get = function(id)
  return state.idMap[id]
end

state.add = function(component)
  state.idMap[component.id] = component
end

state.remove = function(id)
  state.idMap[id] = nil
end

state.toWebsiteID = function(component)
  if type(component) == "string" then
    component = state.get(component)
  end
  return component.type .. "-" .. component.id
end

state.fromWebsiteID = function(websiteID)
  local sepPos = string.find(websiteID, "-")
  if not sepPos then
    return nil
  end

  local typePart = websiteID:sub(1, sepPos - 1)
  local idPart = websiteID:sub(sepPos + 1)
  
  local component = state.get(idPart)
  if not component or component.type ~= typePart then
    return nil
  end

  return component
end

return state