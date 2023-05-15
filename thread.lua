local PATH, dirPATH, settings, channelInName, channelOutName = ...

require("love.event")
local socket = require("socket")

local lt, le, lfs = love.thread, love.event, love.filesystem

local lustache = require(PATH .. "libs.lustache")
local enum = require(PATH .. "enum")

local console = {
  index = lfs.read(dirPATH .. "index.html")
}

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
  local success, errMsg = console.server:listen(10)
  if not success then
    console.out(enum["log.warn"], "Could not set listen backlog. Reason:", errMsg)
  end

  local address, port = console.server:getsockname()
  if address and port then
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

local requestPattern = "(%S-)%s-(%S-)%s-(%S-)" -- Capitalized character is the invert
console.parseRequest = function(client)
  local request = {
    socket = client
  }
  request.method, request.url = ...
end

console.connection = function(client)

end

-- preprocessing

if settings.whitelist then
  for index, allowedAddress in ipairs(settings.whitelist) do
    console.addToWhitelist(allowedAddress)
  end
end

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
      console.connection(client) -- todo coroutine
    else
      console.out(enum["log.warn"], "Non-whitelisted connection attempt from:", address)
      client:close()
    end
  elseif errMsg ~= "timeout" then
    console.out(enum["log.warning"], "Error occurred while accepting a connection:", errMsg)
  end
  -- thread handling
  local var = console.channel:pop()
  local limit, count = 50, 0
  while var and count < limit do

  end
end
