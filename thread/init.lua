local PATH, dirPATH = ...

love.isMintMousseServerThread = true
require(PATH .. "mintmousse")(PATH, dirPATH)

local http = love.mintmousse.require("thread.http")
local server = love.mintmousse.require("thread.server")
local controller = love.mintmousse.require("thread.controller")

-- Set defaults
controller.setTitle("MintMousse")
controller.setSVGIcon({
  emoji = "🦆",
  rect = true,
  rounded = true,
  insideColor = "#95d7ab",
  outsideColor = "#00FF07",
  easterEgg = true,
})

-- todo; should callbacks be added via a function?
--         This has the issue of dependency
local callbacks = { }

callbacks.setTitle = controller.setTitle
callbacks.setSVGIcon = controller.setSVGIcon
callbacks.setIconRaw = controller.setIconRaw
callbacks.setIconRFG = controller.setIconRFG
callbacks.setIconFromFile = controller.setIconFromFile
callbacks.updateSubscription = controller.updateThreadSubscription

callbacks.start = function(config)
  if config then
    if type(config.title) == "string" then
      controller.setTitle(config.title)
    end
    if type(config.whitelist) == "table" then
      for _, v in ipairs(config.whitelist) do
        server.addToWhitelist(v)
      end
    elseif type(config.whitelist) == "string" then
      server.addToWhitelist(config.whitelist)
    end
  end
  server.start(config and config.host, config and config.httpPort)
end

http.addMethod("GET", "/index", function(request)
  return 200, {
    ["cache-control"] = love.mintmousse.CACHE_CONTROL_HEADER,
    ["content-type"] = "text/html; charset=utf8",
  }, controller.getIndex()
end)

http.addMethod("GET", "/index.js", function(request)
  return 200, {
    ["cache-control"] = love.mintmousse.CACHE_CONTROL_HEADER,
    ["content-type"] = "text/javascript; charset=utf8",
  }, controller.javascript
end)

http.addMethod("GET", "/index.css", function(request)
  return 200, {
    ["cache-control"] = love.mintmousse.CACHE_CONTROL_HEADER,
    ["content-type"] = "text/css; charset=utf8",
  }, controller.css
end)

http.addMethod("GET", "/api/ping", function(request)
  return 204, {
    ["cache-control"] = "no-store"
  }, nil
end)

while true do
  for _ = 0, 50 do
    local message = love.mintmousse.pop()
    if type(message) ~= "table" then
      break
    end
    if type(message.func) == "string" then
      callbacks[message.func](unpack(message))
    end
    if message.func == "quit" then
      --todo add server close function
      return
    end
  end
  if server.isRunning() then
    server.newIncomingConnection()
    server.updateConnections()
  end
  love.timer.sleep(0.0001)
end