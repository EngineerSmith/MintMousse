local PATH, dirPATH, settings, website, channelInName, channelOutName = ...
local componentPath = dirPATH .. "components"

require("love.event")
local socket = require("socket")

local lt, le, lfs = love.thread, love.event, love.filesystem

local lustache = require(PATH .. "libs.lustache")
local enum = require(PATH .. "enum")
local httpResponse = require(PATH .. "http")
local helper = require(PATH .. "helper")

local console = {
  index = lfs.read(dirPATH .. "index.html"),
  connections = {}
}

local httpMethod = {
  ["event"] = function(request)
    if request.method == "POST" and request.parsedBody then
      console.out(enum["event"], request.parsedBody["event"], request.parsedBody["variable"])
      return "200"
    end
  end
}

local getFileNameExtension = function(file)
  return file:match("^(.+)%..-$"), file:match("^.+%.(.+)$"):lower()
end

local fileHandle = {
  ["html"] = function(path, name, components)
    components[name].template = love.filesystem.read(path)
  end,
  ["js"] = function(path, name, components)
    if not components[name].javascript then
      components[name].javascript = love.filesystem.read(path)
    end
  end,
  ["lua"] = function(path, name, components)
    local chunk = require((componentPath .. "." .. name):gsub("[\\/]", "."))
    if type(chunk) == "function" then
      components[name].format = chunk
    elseif type(chunk) == "table" then
      components[name].format = chunk.format
      if type(chunk.javascriptRequirement) == "table" then
        components[name].javascriptRequirement = chunk.javascriptRequirement
      end
    end
  end
}

local components = {}
for _, item in ipairs(love.filesystem.getDirectoryItems(componentPath)) do
  local path = componentPath .. "/" .. item
  if love.filesystem.getInfo(path, "file") then
    local name, extension = getFileNameExtension(item)
    if not components[name] then components[name] = { } end
    if fileHandle[extension] then
      fileHandle[extension](path, name, components)
    else
      console.out(enum["log.warn"], item, "does not have a supported extension", extension)
    end
  else
    console.out(enum["log.warn"], item, "is not a file")
  end
end

console.channel = lt.getChannel(channelInName)
console.out = function(enum, ...)
  le.push(channelOutName, enum, ...)
end

local oldError = error
error = function(...)
  console.out(enum["log.error"], ...)
  console.cleanup()
  oldError(table.concat({...}))
end

console.startServer = function(host, port, backupPort)
  if console.server then
    console.cleanup()
  end

  local errMsg
  console.server, errMsg = socket.bind(host, port or 80)
  if not console.server then
    if backupPort then
      console.out(enum["log.warn"], "Webserver could not be started. Attempting to start again. Reason:", errMsg)
      console.server, errMsg = socket.bind(host, backupPort)
    end
    if not console.server then
      error("Webserver could not be started. Aborting console thread. Reason:", errMsg)
    end
  end

  console.server:settimeout(.2)
  -- local success, errMsg = console.server:listen(10)
  -- if not success then
  --   console.out(enum["log.warn"], "Could not set listen backlog. Reason:", errMsg)
  -- end

  local address, port = console.server:getsockname()
  if address and port then
    address = address == "0.0.0.0" and "127.0.0.1" or address
    local fullAdress = "http://" .. address .. ":" .. port
    console.out(enum["log.info"], "Started webserver at:", fullAdress)
  elseif port then
    console.out(enum["log.info"], "Started webserver on port:", port)
  else
    console.out(enum["log.info"], "Started webserver, but was unable to get address.")
  end
end

console.cleanup = function()
  if console.server then
    console.server:close()
  end
end

local replaceCharactersFn = function(s)
  if s == "." then
    return "%." -- "127.0.0.1" -> "127%.0%.0%.0"
  elseif s == "*" then
    return "%d+" -- > "192.168.*.*" - > "192.168.%d+.%d+"
  end
end

console.addToWhitelist = function(address)
  if not console.whitelist then
    console.whitelist = {}
  end
  table.insert(console.whitelist, "^" .. address:gsub("[%.%*]", replaceCharactersFn) .. "$")
end

console.isWhitelisted = function(address)
  if not console.whitelist then
    return true
  end
  for _, allowedAddress in ipairs(console.whitelist) do
    if address:match(allowedAddress) then
      return true
    end
  end
  return false
end

console.receive = function(client, pattern, prefix)
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
console.parseURL = function(url)
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
console.parseBody = function(body)
  local parsedBody = {}
  for key, value in body:gmatch(bodyPattern) do
    parsedBody[helper.unformatText(key)] = helper.unformatText(value)
  end
  return parsedBody
end

-- https://en.wikipedia.org/wiki/HTTP#HTTP/1.1_request_messages
local requestMethodPattern = "(%S*)%s*(%S*)%s*(%S*)"
local requestHeaderPattern = "(.-):%s*(.*)$"
console.parseRequest = function(client)
  local request = {
    socket = client,
    headers = {}
  }
  local data = console.receive(client, "*l")
  request.method, request.url, request.protocol = data:match(requestMethodPattern) -- GET /images/logo.png HTTP/1.1
  request.parsedURL = console.parseURL(request.url)
  -- headers
  while true do
    local data = console.receive(client, "*l")
    if not data or data == "" then
      break
    end
    local header, value = data:match(requestHeaderPattern) -- Content-Type: text/html
    request.headers[header] = value
  end
  if request.headers["Content-Length"] then
    local length = tonumber(request.headers["Content-Length"])
    if length then
      request.body = console.receive(client, length)
    end
  end
  -- body
  if request.body then
    request.parsedBody = console.parseBody(request.body)
  end
  --
  return request
end

console.handleRequest = function(request)
  local path = request.parsedURL.path
  if httpMethod[path] then
    local response, data = httpMethod[path](request)
    if response then
      return httpResponse[response] .. (data or "")
    end
  end
  if path == "index" then
    console.out("HERE", "200")
    return httpResponse["200"] .. lustache:render(console.index, website)
  end
  console.out("HERE", "404")
  return httpResponse["404"]
end

console.connection = function(client)
  local request = console.parseRequest(client)
  local reply = console.handleRequest(request)
  console.send(client, reply)
  client:close()
end

console.send = function(client, data)
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

console.renderComponent = function(component, id, javascript)
  local componentType = components[component.componentType]
  if not componentType then
    error("Could not find component: " .. tostring(component.componentType))
  end

  component.id = id
  id = id + 1

  if componentType.javascript and not javascript[component.componentType] then
    javascript[component.componentType] = true
    table.insert(javascript, componentType.javascript)
  end
  if componentType.javascriptRequirement then
    for _, requirement in ipairs(componentType.javascriptRequirement) do
      if not javascript[requirement] and components[requirement].javascript then
        javascript[requirement] = true
        table.insert(javascript, components[requirement].javascript)
      end
    end
  end
  
  if componentType.format then
    local children = componentType.format(component, helper)
    if children then
      id = console.render(children, id, javascript)
    end
  end
  if component.size then
    component.size = helper.limitSize(component.size)
  end
  component.render = lustache:render(componentType.template, component)
  return id, javascript
end

console.render = function(settings, id, javascript)
  id = id or 0
  javascript = javascript or {}
  if settings.componentType then
    return console.renderComponent(settings, id, javascript)
  end
  for _, component in ipairs(settings) do
    id = console.renderComponent(component, id, javascript)
  end
  return id, javascript
end

-- preprocessing

if settings.whitelist then
  for index, allowedAddress in ipairs(settings.whitelist) do
    console.addToWhitelist(allowedAddress)
  end
end

-- generate dashboard
local _id, javascript = console.render(website.dashboard) -- todo remember to use id for tags renders

website.javascript = table.concat(javascript, "\r\n")

-- todo automate error page creation
-- Generate 404 page 
local http404PageTbl = {
  title = website.title,
  error = "404",
  dashboard = require(PATH .. "http.404")
}

console.render(http404PageTbl.dashboard)
httpResponse["404"] = httpResponse["404"] .. lustache:render(console.index, http404PageTbl)
http404PageTbl = nil

-- Generate 500 page
local http500PageTbl = {
  title = website.title,
  error = "500",
  dashboard = require(PATH .. "http.500")
}

console.render(http500PageTbl)
httpResponse["500"] = httpResponse["500"] .. lustache:render(console.index, http500PageTbl)
http500PageTbl = nil

-- 

console.startServer(settings.host, settings.port, settings.backupPort)

local quit = false
while not quit do
  -- webserver handling
  local client, errMsg = console.server:accept()
  if client then
    client:settimeout(.1)
    local address = client:getsockname()
    if console.isWhitelisted(address) then
      local connection = coroutine.wrap(function()
        console.connection(client)
      end)
      console.connections[connection] = true
    else
      console.out(enum["log.warn"], "Non-whitelisted connection attempt from:", address)
      client:close()
    end
  elseif errMsg ~= "timeout" then
    console.out(enum["log.warning"], "Error occurred while accepting a connection:", errMsg)
  end
  -- Handle connections
  for connection in pairs(console.connections) do
    if connection() == nil then
      console.connections[connection] = nil
    end
  end
  -- thread handling
  local var = console.channel:pop()
  local limit, count = 50, 0
  while var and count < limit do

  end
end
