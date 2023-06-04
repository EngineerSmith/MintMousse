local PATH, dirPATH, settings, website, channelInName, channelOutName, channelDictionary = ...
local httpErrorDirectory = "httpErrorPages"

require("love.event")
require("love.window")
require("love.timer")
local socket = require("socket")

local lt, le, lfs = love.thread, love.event, love.filesystem

local lustache = require(PATH .. "libs.lustache")
local json = require(PATH .. "libs.json")

local httpResponse = require(PATH .. "http")
local helper = require(PATH .. "helper")
local javascript = require(PATH .. "javascript")

local webserver = {
  index = lfs.read(dirPATH .. "index.html"),
  svgIcon = lfs.read(dirPATH .. "icon.svg"),
  connections = {},
  updates = {},
  updateIndexes = {},
  newAspect = {},
  idTable = {}
}

local httpMethod = {
  ["api/event"] = function(request)
    if request.method ~= "POST" then
      return "405"
    end
    if request.parsedBody then
      webserver.out("event", request.parsedBody["event"], request.parsedBody["variable"])
      return "202"
    end
    return "402"
  end,
  ["api/alive"] = function(request)
    if request.method == "GET" then
      return "202"
    end
    return "405"
  end,
  ["api/update"] = function(request)
    if request.method ~= "GET" then
      return "405"
    end
    local lastUpdateTime = tonumber(request.parsedURL.values["updateTime"])
    if not lastUpdateTime then
      return "422"
    end
    local json = webserver.getUpdatePayload("json", lastUpdateTime)
    if json then
      return "200header", json, "Content-Type: application/json"
    end
    return "204" -- processed successfully, but no update
  end
}

local getTime = function()
  return love.timer.getTime()
end

local getFileNameExtension = function(file)
  return file:match("^(.+)%..-$"), file:match("^.+%.(.+)$"):lower()
end

local fileHandle = {
  ["html"] = function(path, name, components)
    components[name].template = lfs.read(path)
  end,
  ["js"] = function(path, name, components)
    components[name].javascript = lfs.read(path)
  end,
  ["lua"] = function(path, name, components)
    local chunk = require((dirPATH .. "components." .. name):gsub("[\\/]", "."))
    if type(chunk) == "function" then
      components[name].format = chunk
    elseif type(chunk) == "table" then
      components[name].format = chunk.format
    end
  end
}

local components = {}
for _, item in ipairs(lfs.getDirectoryItems(dirPATH .. "components")) do
  local path = dirPATH .. "components/" .. item
  if lfs.getInfo(path, "file") then
    local name, extension = getFileNameExtension(item)
    if not components[name] then
      components[name] = {}
    end
    if fileHandle[extension] then
      fileHandle[extension](path, name, components)
    else
      webserver.out("warning", item, "does not have a supported extension", extension)
    end
  else
    webserver.out("warning", item, "is not a file")
  end
end

website.javascript = ""
for type, component in pairs(components) do
  if component.javascript then
    -- component.updateFunctions = javascript.processJavascriptFunctions(type, component.javascript)
    website.javascript = website.javascript .. component.javascript .. "\n\r"
  end
end

do
  local dictionary = lt.getChannel(channelDictionary):peek()
  if dictionary then
    dictionary = {
      dict = dictionary
    }

    local buffer = require("string.buffer").new(dictionary)

    webserver.decode = function(value)
      return buffer:set(value):decode()
    end
  else
    webserver.decode = function(value)
      return value
    end
  end
end

webserver.channel = lt.getChannel(channelInName)
webserver.out = function(enum, ...)
  le.push(channelOutName, enum, ...)
end

local _concat
_concat = function(a, b, ...)
  if b then
    return _concat(b, ...)
  end
  return a
end

local oldError = error
error = function(...)
  local info, name = debug.getinfo(2, "fnS")
  if info then
    if info.name then
      name = info.name
    elseif info.func then -- Attempt to create a name from memory address
      name = tostring(info.func):sub(10)
    end
  end
  webserver.out("error", name, ...)
  webserver.cleanup()
  oldError(_concat(name, ...))
end

webserver.startServer = function(host, port, backupPort)
  if webserver.server then
    webserver.cleanup()
  end

  local errMsg
  webserver.server, errMsg = socket.bind(host, port or 80)
  if not webserver.server then
    if backupPort then
      webserver.out("warning", "Webserver could not be started. Attempting to start again. Reason:", errMsg)
      webserver.server, errMsg = socket.bind(host, backupPort)
    end
    if not webserver.server then
      error("Webserver could not be started. Aborting webserver thread. Reason:", errMsg)
    end
  end

  webserver.server:settimeout(0)

  local address, port = webserver.server:getsockname()
  if address and port then
    address = address == "0.0.0.0" and "127.0.0.1" or address
    local fullAddress = "http://" .. address .. ":" .. port
    webserver.out("info", "Started webserver at:", fullAddress)
  elseif port then
    webserver.out("info", "Started webserver on port:", port)
  else
    webserver.out("info", "Started webserver, but was unable to get address.")
  end
end

webserver.cleanup = function()
  if webserver.server then
    webserver.server:close()
  end
end

local replaceCharactersFn = function(s)
  if s == "." then
    return "%." -- "127.0.0.1" -> "127%.0%.0%.0"
  elseif s == "*" then
    return "%d+" -- > "192.168.*.*" - > "192.168.%d+.%d+"
  end
end

webserver.addToWhitelist = function(address)
  if not webserver.whitelist then
    webserver.whitelist = {}
  end
  table.insert(webserver.whitelist, "^" .. address:gsub("[%.%*]", replaceCharactersFn) .. "$")
end

webserver.isWhitelisted = function(address)
  if not webserver.whitelist then
    return true
  end
  for _, allowedAddress in ipairs(webserver.whitelist) do
    if address:match(allowedAddress) then
      return true
    end
  end
  return false
end

webserver.receive = function(client, pattern, prefix)
  while true do
    local data, errMsg = client:receive(pattern, prefix)
    if not data then
      coroutine.yield(errMsg == "timeout") -- if timeout; wait
    else
      return data
    end
  end
end

local pathPattern = "/([^%?]*)%??(.*)"
local variablePattern = "([^?^&]-)=([^&^#]*)"
webserver.parseURL = function(url)
  local parsedURL = {
    values = {}
  }
  local postfix
  parsedURL.path, postfix = url:match(pathPattern)
  parsedURL.path = parsedURL.path == "" and "index" or parsedURL.path
  for variable, value in postfix:gmatch(variablePattern) do
    parsedURL.values[variable] = value
  end
  return parsedURL
end

local bodyPattern = "([^&]-)=([^&^#]*)"
webserver.parseBody = function(body)
  local parsedBody = {}
  for key, value in body:gmatch(bodyPattern) do
    parsedBody[helper.restoreText(key)] = helper.restoreText(value)
  end
  return parsedBody
end

-- https://en.wikipedia.org/wiki/HTTP#HTTP/1.1_request_messages
local requestMethodPattern = "(%S*)%s*(%S*)%s*(%S*)"
local requestHeaderPattern = "(.-):%s*(.*)$"
webserver.parseRequest = function(client)
  local request = {
    socket = client,
    headers = {}
  }
  local data = webserver.receive(client, "*l")
  request.method, request.url, request.protocol = data:match(requestMethodPattern) -- GET /images/logo.png HTTP/1.1
  request.parsedURL = webserver.parseURL(request.url)
  -- headers
  while true do
    local data = webserver.receive(client, "*l")
    if not data or data == "" then
      break
    end
    local header, value = data:match(requestHeaderPattern) -- Content-Type: text/html
    request.headers[header] = value
  end
  if request.headers["Content-Length"] then
    local length = tonumber(request.headers["Content-Length"])
    if length then
      request.body = webserver.receive(client, length)
    end
  end
  -- body
  if request.body then
    request.parsedBody = webserver.parseBody(request.body)
  end
  --
  return request
end

webserver.handleRequest = function(request)
  local path = request.parsedURL.path
  if httpMethod[path] then
    local status, response, data, headers = pcall(httpMethod[path], request)
    if not status then
      webserver.out("error", "Error occurred while trying to call for", path, ". Error message:", response)
      response = "500"
      data = nil
    end
    if response then
      return httpResponse[response] .. (headers and headers .. "\r\n\r\n" or "") .. (data or "")
    end
  end
  if path == "index" then
    website.time = getTime()
    return httpResponse["200header"] .. "Content-Type: text/html\r\n\r\n" .. lustache:render(webserver.index, website)
  end
  return httpResponse["404"]
end

webserver.connection = function(client)
  local request = webserver.parseRequest(client)
  if request.protocol == "HTTP/1.1" or request.protocol == "HTTP/1.0" then
    local reply = webserver.handleRequest(request)
    webserver.sendReply(client, reply)
  elseif request.protocol and request.protocol:find("HTTP") then
    webserver.sendReply(client, httpResponse["505"])
  end
  client:close()
end

webserver.sendReply = function(client, data)
  local i, size = 1, #data
  while i < size do
    local j, errMsg, k = client:send(data, i) -- bad variable names, but the docs are hell
    if not j then --                             https://w3.impa.br/~diego/software/luasocket/tcp.html#send
      if errMsg == "closed" then
        coroutine.yield(nil)
        return
      end
      i = k + 1
    else
      i = i + j
    end
    coroutine.yield(true)
  end
end

webserver.renderComponent = function(component)
  local componentType = components[component.type]
  if not componentType then
    error("Could not find component: " .. tostring(component.type))
  end

  if componentType.format then
    local children = componentType.format(component, helper)
    if children then
      webserver.render(children)
    end
  end
  if component.size then
    component.size = helper.limitSize(component.size)
  end
  component.render = lustache:render(componentType.template, component)
end

webserver.render = function(settings)
  if settings.type then
    webserver.renderComponent(settings)
  else
    for _, component in ipairs(settings) do
      webserver.renderComponent(component)
    end
  end
end

local generateIDTable_processComponent = function(component, idTable, parent)
  if component.id then
    component._parent = parent
    idTable[component.id] = component
  end
  if component.children then
    webserver.generateIDTable(component.children, idTable, component)
  end
end

webserver.generateIDTable = function(components, idTable, parent)
  if type(components) ~= "table" then
    return
  end

  if components.type then
    generateIDTable_processComponent(components, idTable, parent)
  else
    for _, component in ipairs(components) do
      if type(component) == "table" then
        generateIDTable_processComponent(component, idTable, parent)
      end
    end
  end
end

local removeIDsTable_processComponent = function(component, idTable)
  if component.id then
    component._parent = nil
    idTable[component.id] = nil
  end
  if component.children then
    webserver.removeIDsTable(component.children, idTable)
  end
end

webserver.removeIDsTable = function(components, idTable)
  if type(components ~= "table") then
    return
  end

  if components.type then
    removeIDsTable_processComponent(components, idTable)
  else
    for _, component in ipairs(components) do
      if type(component) == "table" then
        removeIDsTable_processComponent(component, idTable)
      end
    end
  end
end

webserver.addAspect = function(id, time, aspect)
  webserver.removeAspect(id)
  aspect.id, aspect.timeUpdated = id, time
  table.insert(webserver.newAspect, aspect)
end

webserver.removeAspect = function(id)
  for index, aspect in ipairs(webserver.newAspect) do
    if aspect.id == id then
      table.remove(webserver.newAspect, index)
      return
    end
  end
end

webserver.processUpdate = function(updateInformation, time)
  -- Parameters
  local id, key, value, isChildUpdate = updateInformation[1], updateInformation[2], updateInformation[3],
    updateInformation[4]
  local component = webserver.idTable[id]

  -- update value in website for newly requested site
  if not component then
    webserver.out("warning", "ID does not exist within own idTable: " .. tostring(id))
    return
  end
  component[key] = value

  local toRender = component
  while true do
    if not toRender._parent then
      break
    end
    toRender = toRender._parent
  end
  webserver.render(toRender)

  -- add new value to update table
  local updateIndexKey = id .. ":" .. key
  local updateID = webserver.updateIndexes[updateIndexKey]
  if not updateID then
    table.insert(webserver.updates, {
      timeUpdated = time,
      componentID = id,
      func = (isChildUpdate or component.type) .. "_update_" .. (isChildUpdate and "child_" or "") .. key,
      value = component[key] -- render could format value, so we use component value instead
    })
    webserver.updateIndexes[updateIndexKey] = #webserver.updates
  else
    local updateTable = webserver.updates[updateID]
    updateTable.timeUpdated = time
    updateTable.value = value
  end
end

webserver.getUpdatePayload = function(type, lastUpdateTime)
  if not (type == "json") then
    return error("Cannot return type " .. tostring(type) .. " update payload")
  end

  local updatesToSend = {}
  for _, update in ipairs(webserver.updates) do
    if update.timeUpdated > lastUpdateTime then
      table.insert(updatesToSend, {update.func, update.componentID, update.value})
    end
  end

  for _, aspect in ipairs(webserver.newAspect) do
    if aspect.timeUpdated > lastUpdateTime then
      table.insert(updatesToSend, {aspect.func, aspect.id, aspect.name, aspect.value})
    end
  end

  if #updatesToSend == 0 then
    return nil
  end
  updatesToSend = {
    updateTime = getTime(),
    updates = updatesToSend
  }

  if type == "json" then
    return json.encode(updatesToSend)
  end
  error("CANNOT HIT; TELL A PROGRAMMER TO UPDATE FIRST LINE OF FUNCTION")
end

webserver.addNewTab = function(tab, time)
  if type(tab.components) == "table" then
    webserver.render(tab.components)
    webserver.generateIDTable(tab.components, webserver.idTable)
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

  table.insert(website.tabs, tab)
  webserver.addAspect(tab.id, time, {
    func = "newTab",
    name = tab.name,
    value = #renders ~= 0 and renders or nil
  })
end

webserver.removeTab = function(tabId, time)
  local index, tab
  for i, t in ipairs(website.tabs) do
    if t.id == tabId then
      index, tab = i, t
    end
  end
  if not index then
    webserver.out("warning", "Could not find tab with id to remove (de-sync between main thread and mintmousse?): "..tostring(tabId))
    return
  end
  if type(tab.components) then
    webserver.removeIDsTable(tab.components, webserver.idTable)
  end
  table.remove(website.tabs, index)
  webserver.addAspect(tabId, time, {
    func = "removeTab",
    
  })
end

-- == preprocessing ==

if settings.whitelist then
  for index, allowedAddress in ipairs(settings.whitelist) do
    webserver.addToWhitelist(allowedAddress)
  end
end

if type(website.icon) == "table" then
  website.icon = lustache:render(webserver.svgIcon, website.icon)
end

for _, tab in ipairs(website.tabs) do
  if type(tab.components) == "table" then
    -- generate website tab
    webserver.render(tab.components)
    -- generate id table to access tables
    webserver.generateIDTable(tab.components, webserver.idTable)
  end
end

-- Generate error pages
local errorPagePath = dirPATH .. httpErrorDirectory
for _, file in ipairs(lfs.getDirectoryItems(errorPagePath)) do
  local name, extension = getFileNameExtension(file)
  if extension == "lua" then
    if not httpResponse[name] then
      error("Make sure to remember to add the errorPage to http.lua")
    end
    local pageTbl = {
      title = website.title,
      error = name,
      javascript = website.javascript,
      tabs = {{
        name = "😱 Error " .. name,
        active = true,
        components = require(PATH .. httpErrorDirectory .. "." .. name)
      }}
    }
    webserver.render(pageTbl.tabs[1].components)
    httpResponse[name] = httpResponse[name] .. lustache:render(webserver.index, pageTbl)
  end
end

-- == Main loop ==

webserver.startServer(settings.host, settings.port, settings.backupPort)

local quit = false
while not quit do
  -- Incoming connection handling
  local client, errMsg = webserver.server:accept()
  if client then
    client:settimeout(0)
    local address = client:getsockname()
    if webserver.isWhitelisted(address) then
      local connection = coroutine.wrap(function()
        webserver.connection(client)
      end)
      webserver.connections[connection] = true
    else
      webserver.out("warning", "Non-whitelisted connection attempt from:", address)
      client:close()
    end
  elseif errMsg ~= "timeout" and errMsg ~= "closed" then
    webserver.out("warning", "Error occurred while accepting a connection:", errMsg)
  end
  -- Handle connections
  for connection in pairs(webserver.connections) do
    if connection() == nil then
      webserver.connections[connection] = nil
    end
  end
  -- thread handling
  for _ = 0, 50 do -- limit to 50 iterations
    local var = webserver.channel:pop()
    if not var then
      break
    end
    var = webserver.decode(var)

    local func = webserver.processUpdate
    -- new
    if var.new == "tab" then
      func = webserver.addNewTab
      var = var[1];
      -- remove
    elseif var.remove == "tab" then
      func = webserver.removeTab
      var = var[1];
    end
    func(var, getTime())
  end
end
