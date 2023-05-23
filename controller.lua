local createComponentMeta = function(component)
  local componentMeta = {
    __newindex = function(_, k, v)
      
    end,
    __index = function(k, v)
      
    end
  }

  local componentController = {

  }

  return setmetatable(componentController, componentMeta)
end

local createComponentsMeta = function(components)
  local componentsMeta = {
    __newindex = function(_, k, v)
      
    end,
    __index = function(k, v)
      
    end
  }

  local componentsController = {
    insert = function()
      error()
    end, -- todo
    remove = function()
      error()
    end, -- todo
  }

  return setmetatable(componentsController, componentsMeta)
end

local createTabMeta = function(tab)
  local tabMeta = {
    __newindex = function(_, k, v)
      
    end,
    __index = function(k, v)
      
    end
  }

  local tabController = {
    notify = function()
      error()
    end --todo
  }

  return setmetatable(tabController, tabMeta)
end


return function(website, jsUpdateFunctions)
  
  local controllerMeta = {
    __newindex = function(_, k, v)
      print("hit", k, v)
      rawset(website, k, v)
    end,
    __index = function(k, v)
      return rawget(website, v)
    end
  }

  local controller = {
    insert = function()
      error()
    end, -- todo
    remove = function()
      error()
    end, -- todo
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
