local indexError = function(key)
  errorMintMousse("Cannot add or change this index in this table. Key given: " .. tostring(key))
end

local dirPATH

local buffer
local encode = function(value)
  if buffer then
    return buffer:reset():encode(value):get()
  else
    return value
  end
end

local globalID = 0
local validateComponentSettings -- function, forward declaration

local formatComponent = function(component)
  if component.type then
    local dir = dirPATH .. "components/" .. component.type
    if not love.filesystem.getInfo(dir .. ".html", "file") or not love.filesystem.getInfo(dir .. ".lua", "file") then
      errorMintMousse("Component type: " .. tostring(component.type) .. " does not exist: " .. tostring(dir))
    end
    if not component.id then
      component.id = globalID
      globalID = globalID + 1
    elseif type(component.id) == "string" then
      local failed
      for capture in component.id:gmatch("(%W)") do -- For each non-alphanumeric character
        if not capture:find("[%._,;:@]") then -- if not found; fail
          failed = capture
          break
        end
      end
      if failed then
        errorMintMousse("You can only use alphanumeric and . _ , : ; @ characters for the id. Failed value: " .. tostring(failed))
      end
    end
  end
  if component.children then
    validateComponentSettings(component.children)
  end
end

validateComponentSettings = function(settings)
  if settings.type then
    formatComponent(settings)
  else
    for _, component in ipairs(settings) do
      formatComponent(component)
    end
  end
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

local processComponents -- function, forward declaration

local processComponent = function(component, parent, idTable, jsUpdateFunctions, channelIn)
  if type(component) ~= "table" then
    return component
  end

  local children, rawChildren
  if component.children then
    children, rawChildren = processComponents(component.children, parent, idTable, jsUpdateFunctions, channelIn)
  end

  local newindex
  if jsUpdateFunctions[component.type] then
    local jsFuncs = jsUpdateFunctions[component.type]
    local jsFuncsParent
    if parent and parent.type then
      jsFuncsParent = jsUpdateFunctions[parent.type]
      jsFuncsParent = jsFuncsParent and jsFuncsParent.children or nil
    end
    newindex = function(_, key, value)
      local isChildUpdate = jsFuncsParent and jsFuncsParent[key]
      if jsFuncs[key] or isChildUpdate then
        local previous = rawget(component, key)
        if (previous ~= value) then
          rawset(component, key, value)
          channelIn:push(encode({
            func = "updateComponent",
            component.id,
            key,
            value,
            isChildUpdate and parent.type or nil
          }))
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

  local insertComponent = function(newComponent)
    validateComponentSettings(newComponent)
    local com, raw = processComponents(newComponent, component, idTable, jsUpdateFunctions, channelIn)
    if raw then -- multiple components
      if rawChildren then
        for _, c in ipairs(raw) do
          table.insert(rawChildren, c)
        end
      else
        rawChildren = raw
      end
    else -- flat component
      if not children then
        children = {}
        component.children = children
      end
      table.insert(children, com)
      if not rawChildren then
        rawChildren = {}
      end
      table.insert(rawChildren, com)
    end
    channelIn:push(encode({
      func = "addNewComponent",
      newComponent
    }))
    return newComponent.id
  end

  local removeComponent = function(id)
    errorMintMousse("todo") -- todo
  end

  return setmetatable({}, {
    __newindex = newindex,
    __index = function(_, key)
      if key == "children" then
        return children
      elseif key == "style" then
        return indexError("style")
      elseif key == "insert" then
        return insertComponent
      elseif key == "remove" then
        return removeComponent
      end
      return rawget(component, key)
    end
  })
end

processComponents = function(components, parent, idTable, ...)
  -- flat component
  if components.type then
    idTable[components.id] = processComponent(components, parent, idTable, ...)
    return idTable[components.id]
  end
  -- multiple components
  local newComponents = {}
  for index, component in ipairs(components) do
    local component = processComponent(component, parent, idTable, ...)
    newComponents[index] = component
    if type(component) == "table" and component.id then
      idTable[component.id] = component
    end
  end

  return setmetatable({}, {
    __newindex = function(_, key)
      indexError(key)
    end,
    __index = function(_, key)
      return rawget(newComponents, key)
    end
  }), newComponents
end

local processTab = function(tab, idTable, jsUpdateFunctions, channelIn)

  if type(tab.name) ~= "string" then
    errorMintMousse("Name must be type string")
  end

  local tabController = {
    notify = function()
      errorMintMousse()
    end -- todo check index.html
  }

  local components, rawComponents
  if type(tab.components) == "table" then
    if tab.components.type then -- flat component needs to be put within a table
      tab.components = { tab.components }
    end
    validateComponentSettings(tab.components)
    components, rawComponents = processComponents(tab.components, nil, idTable, jsUpdateFunctions, channelIn)
  end

  tabController.addComponent = function(component)
    validateComponentSettings(component)
    local com, raw = processComponents(component, nil, idTable, jsUpdateFunctions, channelIn)
    if raw then -- multiple components
      if rawComponents then
        for _, c in ipairs(raw) do
          table.insert(rawComponents, c)
        end
      else
        rawComponents = raw
      end
    else -- flat component
      if not tab.components then
        tab.components = {}
      end
      table.insert(tab.components, component)
      if not rawComponents then
        rawComponents = {}
      end
      table.insert(rawComponents, com)
    end

    channelIn:push(encode({
      func = "addNewComponent",
      component,
      tab.id
    }))
    return component.id
  end

  tabController.removeComponent = function(componentId)
    -- todo
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
  }), newTabs
end

return function(path, website, channelDictionary, jsUpdateFunctions, channelIn)
  dirPATH = path

  -- build buffer
  local dictionary = channelDictionary:peek()
  if dictionary then
    dictionary = {
      dict = dictionary
    }
  end
  buffer = require("string.buffer").new(dictionary) -- love 11.4 +

  local controller = {
    idTable = {}
  }

  -- processing 
  if type(website.icon) == "table" then
    controller.icon = basicLockTable(website.icon)
  end

  local tabs, rawTabs
  if type(website.tabs) == "table" then
    tabs, rawTabs = processTabs(website.tabs, controller.idTable, jsUpdateFunctions, channelIn)
  end

  -- build controller
  controller.getById = function(id)
    return controller.idTable[id]
  end

  controller.update = function(id, key, value)
    local component = controller.getById(id)
    assert(component, "Invalid id given: " .. tostring(id))
    component[key] = value
  end

  controller.addTab = function(tab)
    table.insert(rawTabs, processTab(tab, controller.idTable, jsUpdateFunctions, channelIn))
    tab.id = tab.name:gsub("%s", "_") .. #rawTabs
    channelIn:push(encode({
      func = "addNewTab",
      tab
    }))
    return tab.id, rawTabs[#rawTabs]
  end

  controller.removeTab = function(tabId)
    if type(tabId) == "table" then -- tab table
      tabId = tabId.id
    end
    assert(type(tabId) == "string", "Must give tab id to remove the tab")
    channelIn:push(encode({
      func = "removeTab",
      tabId
    }))

    for index, tab in ipairs(rawTabs) do
      if tab.id == tabId then
        table.remove(rawTabs, index)
        tabId = nil
      end
    end
    assert(tab == nil, "Could not find tab with that id!")
  end

  --
  return setmetatable(controller, {
    __newindex = function(_, key)
      indexError(key)
    end,
    __index = function(_, key)
      if key == "tabs" then
        return tabs
      end
      return rawget(controller, key) or rawget(website, key)
    end
  })
end
--[[
 TODO list

 2) Controller functions
x2.1) Make it easy to update a field without going down a long list of tables
x2.1.1) e.g. website.tabs[1].components[1].children[2].progress = 5  NO (but keep support for it)
x2.1.2) controller.updateVariable(id, variableName, newValue) YES
 2.1.3) What about, controller[id].variableName = newValue ? using metafunctions
 2.2) Add functions to add or remove
 2.2.1) Insert new components between old ones, at the start or end.
 2.2.2) Remove components from any part of the list
 2.2.3) Update webpage with these changes
]]
