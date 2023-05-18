return function(website)
  local controllerMeta = {
    __newindex = function(_, k, v) 
      print("hit", k, v)
      rawset(website, k, v)
    end,
    __index = function(k ,v)
      return rawget(website, v)
    end
  }

  local controller = {
    insert = function() error() end, -- todo
    remove = function() error() end, -- todo
  }

  return setmetatable(controller, controllerMeta)
end
