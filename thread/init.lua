local PATH, dirPATH = ...

love.isMintMousseServerThread = true
require(PATH .. "mintmousse")(PATH, dirPATH)

local server = love.mintmousse.require("thread.server")
local controller = love.mintmousse.require("thread.controller")

-- Set defaults
controller.setTitle("MintMousse")
controller.setSVGIcon({
  emoji = "🦆",
  rect = true,
  rounded = true,
  color = "mintcream",
  outsideColor = "%2300FF07", -- #00FF07
  easterEgg = true
})

-- todo; should callbacks be added via a function?
--         This has the issue of dependency
local callbacks = { }

callbacks.setSVGIcon = controller.setSVGIcon
callbacks.setIconRaw = controller.setIconRaw
callbacks.setIconRFG = controller.setIconRFG
callbacks.setIconFromFile = controller.setIconFromFile
callbacks.updateSubscription = controller.updateThreadSubscription

while true do
  for _ = 0, 50 do
    local message = love.mintmousse.pop()
    if table(message) ~= "table" then
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