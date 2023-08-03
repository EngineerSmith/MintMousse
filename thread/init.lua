local PATH, dirPATH, settings, webpage, channelInName, channelOutName, channelDictionary = ...

local channelIn = love.thread.getChannel(channelInName)
local channelOut = function(enum, ...)
  love.event.push(channelOutName, enum, ...)
end

-- redirect logging
print = function(...)
  channelOut("print", ...)
end

require(PATH .. "global")(PATH, "Thread")

require("love.event")
require("love.window")
require("love.timer")

local helper = requireMintMousse("helper")

-- decode messages from main thread
local decode = function(value)
  return value
end

local dictionary = love.thread.getChannel(channelDictionary):peek()
if dictionary then
  dictionary = {
    dict = dictionary
  }
  local buffer = require("string.buffer").new(dictionary)
  decode = function(value)
    return buffer:set(value):decode()
  end
end

--

local website = requireMintMousse("thread.website")

website.processComponents(dirPATH .. "components")

website.setWebpageTemplate(love.filesystem.read(dirPATH .. "index.html"))
website.setIconTemplate(love.filesystem.read(dirPATH .. "icon.svg"))

website.setWebpage(webpage)
website.setIcon(webpage.icon)

local httpServer = requireMintMousse("thread.httpServer")

for _, item in ipairs(love.filesystem.getDirectoryItems(dirPATH .. "httpErrorPages")) do -- todo allow for user to add own error pages without editing repo
  local name, extension = helper.getFileNameExtension(item)
  if extension == "lua" and tonumber(name) ~= nil then
    website.setErrorPageComponents(httpServer, tonumber(name), requireMintMousse("httpErrorPages." .. name))
  end
end

for _, address in ipairs(settings.whitelist) do
  httpServer.addToWhitelist(address)
end

do

  httpServer.addMethod("GET", "index", function(_)
    local html = website.getIndex(httpServer.getTime())
    return 200, html, "text/html"
  end)

  httpServer.addMethod("GET", "favicon.ico", function()
    if website.index.icon then
      return 200, website.index.icon, "image/svg+xml"
    end
    return 404
  end)

  httpServer.addMethod("GET", "api/alive", 204)

  httpServer.addMethod("GET", "api/update", function(request)
    local lastUpdateTime = tonumber(request.parsedURL.values["updateTime"])
    if not lastUpdateTime then
      return 422
    end
    local payload = website.getUpdatePayload(lastUpdateTime, httpServer.getTime())
    if payload then
      return 200, payload, "application/json"
    end
    return 204 -- no updates
  end)
  
  httpServer.addMethod("POST", "api/event", function(request)
    if request.parsedBody then
      channelOut("event", request.parsedBody["event"], request.parsedBody["variable"]) -- todo add event validation, if event can be fired (to avoid someone sending event attacks)
      return 202
    end
  end)

end

httpServer.start(settings.host, settings.port, settings.backupPort)

while true do
  httpServer.newIncomingConnection()
  httpServer.updateConnections()
  -- Thread communication
  for _ = 0, 50 do
    local message = channelIn:pop()
    if not message then
      break
    end

    message = decode(message)

    if message.func == "quit" then
      return
    end

    if message.func == "updateComponent" then
      website.updateComponent(httpServer.getTime(), message)
    elseif website[message.func] then
      website[message.func](httpServer.getTime(), message[1], message[2])
    end
  end
end
