local PATH, dirPATH, settings, website, channelInName, channelOutName = ...
local componentPath = dirPATH .. "components"
local httpErrorDirectory = "httpErrorPages"

require("love.event")
require("love.window")
local socket = require("socket")

local lt, le, lfs = love.thread, love.event, love.filesystem

local lustache = require(PATH .. "libs.lustache")
local enum = require(PATH .. "enum")
local httpResponse = require(PATH .. "http")
local helper = require(PATH .. "helper")
local javascript = require(PATH .. "javascript")

local webserver = {
  index = lfs.read(dirPATH .. "index.html"),
  svgIcon = lfs.read(dirPATH .. "icon.svg"),
  connections = {}
}

local httpMethod = {
  ["event"] = function(request)
    if request.method == "POST" and request.parsedBody then
      webserver.out(enum["event"], request.parsedBody["event"], request.parsedBody["variable"])
      return "202"
    end
    if request.method ~= "POST" then
      return "405"
    end
    return "402"
  end,
  ["alive"] = function(request)
    if request.method == "GET" then
      return "202"
    end
    return "405"
  end,
  ["update"] = function(request)
    if request.method == "GET" then
      local json = "{}"
      return "200header", json, "Content-Type: application/json"
    end
    return "405"
  end,
}

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
    local chunk = require((componentPath .. "." .. name):gsub("[\\/]", "."))
    if type(chunk) == "function" then
      components[name].format = chunk
    elseif type(chunk) == "table" then
      components[name].format = chunk.format
    end
  end
}

local components = {}
for _, item in ipairs(lfs.getDirectoryItems(componentPath)) do
  local path = componentPath .. "/" .. item
  if lfs.getInfo(path, "file") then
    local name, extension = getFileNameExtension(item)
    if not components[name] then
      components[name] = {}
    end
    if fileHandle[extension] then
      fileHandle[extension](path, name, components)
    else
      webserver.out(enum["log.warn"], item, "does not have a supported extension", extension)
    end
  else
    webserver.out(enum["log.warn"], item, "is not a file")
  end
end

website.javascript = ""
for _, component in pairs(components) do
  if component.javascript then
    component.updateFunctions = javascript.processJavascriptFunctions(component.javascript)
    website.javascript = website.javascript .. component.javascript .. "\n\r"
  end
end

webserver.channel = lt.getChannel(channelInName)
webserver.out = function(enum, ...)
  le.push(channelOutName, enum, ...)
end

local oldError = error
error = function(...)
  webserver.out(enum["log.error"], ...)
  webserver.cleanup()
  oldError(table.concat({...}))
end

webserver.startServer = function(host, port, backupPort)
  if webserver.server then
    webserver.cleanup()
  end

  local errMsg
  webserver.server, errMsg = socket.bind(host, port or 80)
  if not webserver.server then
    if backupPort then
      webserver.out(enum["log.warn"], "Webserver could not be started. Attempting to start again. Reason:", errMsg)
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
    local fullAdress = "http://" .. address .. ":" .. port
    webserver.out(enum["log.info"], "Started webserver at:", fullAdress)
  elseif port then
    webserver.out(enum["log.info"], "Started webserver on port:", port)
  else
    webserver.out(enum["log.info"], "Started webserver, but was unable to get address.")
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
    parsedBody[helper.unformatText(key)] = helper.unformatText(value)
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
      webserver.out(enum["log.error"], "Error occurred while trying to call for", path, ". Error message:", response)
      response = "500"
      data = nil
    end
    if response then
      return httpResponse[response] .. (headers and headers .. "\r\n\r\n" or "") .. (data or "")
    end
  end
  if path == "index" then
    return httpResponse["200"] .. lustache:render(webserver.index, website)
  end
  return httpResponse["404"]
end

webserver.connection = function(client)
  local request = webserver.parseRequest(client)
  local reply = webserver.handleRequest(request)
  webserver.sendReply(client, reply)
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
    error("Could not find component: " .. tostring(component.type)) --todo add checks to init.lua
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

-- == preprocessing ==

if settings.whitelist then
  for index, allowedAddress in ipairs(settings.whitelist) do
    webserver.addToWhitelist(allowedAddress)
  end
end

if type(website.icon)  == "table" then
  website.icon = lustache:render(webserver.svgIcon , website.icon)
end

-- generate website
for _, tab in ipairs(website.tabs) do
  if type(tab.components) == "table" then
    webserver.render(tab.components)
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
        name = "Error " .. name,
        active = true,
        components = require(PATH .. httpErrorDirectory .. "." .. name)
      }}
    }
    webserver.render(pageTbl.tabs[1].components, 0)
    httpResponse[name] = httpResponse[name] .. lustache:render(webserver.index, pageTbl)
  end
end

-- == Main loop ==

webserver.startServer(settings.host, settings.port, settings.backupPort)

local quit = false
while not quit do
  -- webserver handling
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
      webserver.out(enum["log.warn"], "Non-whitelisted connection attempt from:", address)
      client:close()
    end
  elseif errMsg ~= "timeout" then
    webserver.out(enum["log.warn"], "Error occurred while accepting a connection:", errMsg)
  end
  -- Handle connections
  for connection in pairs(webserver.connections) do
    if connection() == nil then
      webserver.connections[connection] = nil
    end
  end
 -- thread handling
  local var = webserver.channel:pop()
  local limit, count = 50, 0
  while var and count < limit do
    -- todo
    var = webserver.channel:pop()
    count = count + 1
  end
end
