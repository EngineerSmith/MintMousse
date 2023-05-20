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


return function(website)
  

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
