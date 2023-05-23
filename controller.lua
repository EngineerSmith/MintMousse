local indexError = function(key)
  error("Cannot add or change this index in this table. Key given: " .. tostring(key))
end

local typeError = function(type, givenType)
  error("Given type does not match previous type. Expected type: "..tostring(type)..". Given type: "..tostring(givenType))
end

local basicLockTable = function(tbl)
  return setmetatable({}, {
    __newindex = function(_, key)
      indexError(key)
    end,
    __index = function(_, key)
      return rawget(tbl, key)
    end
  })
end

local processComponents -- function, defined later

local processComponent = function(component, jsUpdateFunctions, channelIn)
  local children
  if component.children then
    children = processComponents(component.children, jsUpdateFunctions, channelIn)
  end

  local newindex
  if jsUpdateFunctions[component.type] then
    local jsFuncs = jsUpdateFunctions[component.type]
    newindex = function(_, key, value)
      if jsFuncs[key] then
        local previous = rawget(component, key)
        if previous ~= value then
          if type(previous) ~= type(value) then
            typeError(type(previous), type(value))
          else
            print("SET", key, "TO", value)
            rawset(component, key, value)
            channelIn:push({component.id, key, value}) -- todo make faster
          end
        end
      else
        indexError(key)
      end
    end
  else
    newindex = function(_, key)
      indexError(key)
    end
  end

  return setmetatable({}, {
    __newindex = newindex,
    __index = function(_, key)
      if key == "children" then
        return children
      end
      return rawget(component, key)
    end
  })
end

processComponents = function(components, ...)
  -- flat component
  if components.type then
    return processComponent(components, ...)
  end
  -- multiple components
  local newComponents = {}
  for index, component in ipairs(components) do
    newComponents[index] = processComponent(component, ...)
  end
  return setmetatable({}, {
    __newindex = function(_, key)
      indexError(key)
    end,
    __index = function(_, key)
      return rawget(newComponents, key)
    end
  })
end

local processTab = function(tab, ...)
  local tabController = {
    notify = function()
      error()
    end -- todo
  }

  local components
  if type(tab.components) == "table" then
    components = processComponents(tab.components, ...)
  end

  return setmetatable(tabController, {
    __newindex = function(_, key)
      indexError(key)
    end,
    __index = function(_, key)
      if key == "components" then
        return components
      end
      return rawget(tab, key)
    end
  })
end

local processTabs = function(tabs, ...)
  local newTabs = {}
  for index, tab in ipairs(tabs) do
    newTabs[index] = processTab(tab, ...)
  end
  return setmetatable({}, {
    __newindex = function(_, key)
      indexError(key)
    end,
    __index = function(_, key)
      return rawget(newTabs, key)
    end
  })
end

return function(website, ...)

  local controller = {
    getById = function(id)
      error()
    end,
    update = function()
      error()
    end,
    insert = function()
      error()
    end, -- todo
    remove = function()
      error()
    end -- todo
  }

  if type(website.icon) == "table" then
    controller.icon = basicLockTable(website.icon)
  end
  local tabs
  if type(website.tabs) == "table" then
    tabs = processTabs(website.tabs, ...)
  end

  local controllerMeta = {
    __newindex = function(_, key)
      indexError(key)
    end,
    __index = function(_, key)
      if key == "tabs" then
        return tabs
      end
      return rawget(website, key)
    end
  }

  return setmetatable(controller, controllerMeta)
end
--[[
 TODO list

 1) metatables
 1.1) Metatable when change should error, or push update to webserver thread to reflect the change
 1.2) Only change variables with an update function
 2) Controller functions
 2.1) Make it easy to update a field without going down a long list of tables
 2.1.1) e.g. website.tabs[1].components[1].children[2].progress = 5  NO (but keep support for it)
 2.1.2) controller.updateVariable(id, variableName, newValue) YES
 2.2) Add functions to add or remove createComponentsMeta
 2.2.1) Insert new components between old ones, at the start or end.
 2.2.2) Remove components from any part of the list

]]
