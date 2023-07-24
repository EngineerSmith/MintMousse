local helper = requireMintMousse("helper")
local lustache = requireMintMousse("libs.lustache")
local json = requireMintMousse("libs.json")

local lfs = love.filesystem

local website = {
  components = {},
  template = {},
  render = {},
  idTable = {},
  aspect = {},
  update = {},
  updateIndex = {}
}

website.setWebpageTemplate = function(template)
  website.template.webpage = template
end

website.setWebpage = function(webpage)
  website.index = webpage
  for _, tab in ipairs(website.index.tabs) do
    if type(tab.components) == "table" then
      website.render(tab.components)
      website.generateIDTable(tab.components)
    end
  end

  website.index.javascript = ""
  for type, component in pairs(website.components) do
    if component.javascript then
      website.index.javascript = website.index.javascript .. component.javascript .. "\n\r"
    end
  end
end

website.getIndex = function(currentTime)
  website.index.time = currentTime
  return lustache:render(website.template.webpage, website.index)
end

website.setErrorPageComponents = function(httpServer, code, components)
  local errorPage = {
    title = website.index.title,
    error = code,
    javascript = website.index.javascript,
    time = httpServer.getTime(),
    pollInterval = website.index.pollInterval,
    tabs = {{
      name = "Error " .. code,
      active = true,
      components = components
    }}
  }
  website.render(errorPage.tabs[1].components)
  httpServer.addDefaultResponse(code, lustache:render(website.template.webpage, errorPage), "text/html")
end

website.setIconTemplate = function(template)
  website.template.icon = template
end

website.setIcon = function(icon)
  website.index.icon = lustache:render(website.template.icon, icon)
end

--[[Webpage updates]]

website.addAspect = function(id, time, aspect)
  -- remove old
  for index, aspect in ipairs(website.aspect) do
    if aspect.id == id then
      table.remove(website.aspect, index)
      break
    end
  end
  -- add new
  aspect.id, aspect.timeUpdated = id, time
  table.insert(website.aspect, aspect)
end

website.updateComponent = function(currentTime, updateInformation)
  -- Parameters
  local id, key, value, isChildUpdate = updateInformation[1], updateInformation[2], updateInformation[3],
    updateInformation[4]

  -- update value in website for newly requested site
  local component = website.idTable[id]
  if not component then
    return warning("Website could not find component with id:", id)
  end
  component[key] = value
  local toRender = component
  while true do
    if not toRender._parent then
      break
    end
    toRender = toRender._parent
  end
  website.render(toRender)

  -- add new value to update table

  local updateIndexKey = id .. ":" .. key
  local updateID = website.updateIndex[updateIndexKey]
  if not updateID then
    table.insert(website.update, {
      timeUpdated = currentTime,
      componentID = id,
      func = (isChildUpdate or component.type) .. "_update_" .. (isChildUpdate and "child_" or "") .. key,
      value = component[key] -- render could format value, so we use component's rendered value instead
    })
    website.updateIndex[updateIndexKey] = #website.update
  else
    local updateTable = website.update[updateID]
    updateTable.timeUpdated = currentTime
    updateTable.value = component[key]
  end

end

website.getUpdatePayload = function(lastUpdateTime, currentTime)
  local payload = {
    updateTime = currentTime,
    updates = {}
  }
  -- component updates
  for _, update in ipairs(website.update) do
    if update.timeUpdated > lastUpdateTime then
      table.insert(payload.updates, {update.func, update.componentID, update.value})
    end
  end
  -- add/remove components
  for _, aspect in ipairs(website.aspect) do
    if aspect.timeUpdated > lastUpdateTime then
      table.insert(payload.updates, {aspect.func, aspect.id, aspect.name, aspect.value})
    end
  end
  --
  if #payload.updates == 0 then
    return nil
  end
  return json.encode(payload)
end

--[[components]]

local componentFileHandle = {
  ["html"] = function(path, name)
    website.components[name].template = lfs.read(path)
  end,
  ["js"] = function(path, name)
    website.components[name].javascript = lfs.read(path)
  end,
  ["lua"] = function(path, name)
    website.components[name].format = require(path:sub(1, -5):gsub("[\\/]", "."))
  end
}

website.processComponents = function(directory)
  for _, item in ipairs(lfs.getDirectoryItems(directory)) do
    local path = directory .. "/" .. item
    if lfs.getInfo(path, "file") then
      local name, extension = helper.getFileNameExtension(item)
      if not website.components[name] then
        website.components[name] = {}
      end
      if componentFileHandle[extension] then
        componentFileHandle[extension](path, name)
      else
        log("Website unsupported file within component directory:", extension)
      end
    else
      log("Website found a non-file within component directory:", item)
    end
  end
end

--[[new components]]
website.addNewTab = function(currentTime, tab)
  if type(tab.components) == "table" then
    website.render(tab.components)
    website.generateIDTable(tab.components)
  end
  local renders = {}
  if tab.components then
    if tab.components.render then
      table.insert(renders, tab.components.render)
    else
      for _, component in ipairs(tab.components) do
        if component.render then
          table.insert(renders, component.render);
        end
      end
    end
  end

  table.insert(website.index.tabs, tab)
  website.addAspect(tab.id, currentTime, {
    func = "newTab",
    name = tab.name,
    value = #renders ~= 0 and renders or nil
  })
end


website.addNewComponent = function(currentTime, component)
  warning("Website addNewComponent not implemented yet")
end
--[[remove components]]
website.removeTab = function(currentTime, tabId)
  local index, tab
  for i, t in ipairs(website.index.tabs) do
    if t.id == tabId then
      index, tab = i, t
    end
  end
  if not index then
    return warning("Website could not find tab with id to remove (de-sync between main thread and mintmousse?):", tabId)
  end
  if type(tab.components) then
    website.removeFromIDTable(tab.components)
  end
  table.remove(website.index.tabs, index)
  website.addAspect(tabId, currentTime, {
    func = "removeTab"
  })
end

website.removeComponent = function(currentTime, component)
  warning("Website removeComponent not implemented yet")
end

--[[id]]

-- add

local generateIDTableComponent = function(component, parent)
  if component.id then
    component._parent = parent
    website.idTable[component.id] = component
  end
  if component.children then
    website.generateIDTable(component.children, component)
  end
end

website.generateIDTable = function(components, parent)
  if type(components) ~= "table" then
    return
  end

  if components.type then
    generateIDTableComponent(components, parent)
  else
    for _, component in ipairs(components) do
      if type(component) == "table" then
        generateIDTableComponent(component, parent)
      end
    end
  end
end

-- remove

local removeFromIDTableComponent = function(component)
  if component.id then
    component._parent = nil
    website.idTable[component.id] = nil
  end
  if component.children then
    website.removeFromIDTable(component.children)
  end
end

website.removeFromIDTable = function(components)
  if type(components) ~= "table" then
    return
  end
  if components.type then
    removeFromIDTableComponent(components)
  else
    for _, component in ipairs(components) do
      if type(component) == "table" then
        removeFromIDTableComponent(component)
      end
    end
  end
end

--[[rendering]]

website.render = function(settings)
  if settings.type then
    website.renderComponent(settings)
  else
    for _, component in ipairs(settings) do
      website.renderComponent(component)
    end
  end
end

website.renderComponent = function(component)
  local componentType = website.components[component.type]
  if not componentType then
    return warning("Website has not loaded component:", component.type)
  end

  if componentType.format then
    local children = componentType.format(component, helper)
    if children then
      website.render(children)
    end
  end
  if component.size then
    component.size = helper.limitSize(component.size)
  end
  component.render = lustache:render(componentType.template, component)
end

return website
