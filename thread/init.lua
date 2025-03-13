local PATH, dirPATH, settings = ...

require("love.event")
require("love.timer")

require(PATH .. "mintmousse")(PATH, dirPATH)

local server = love.mintmousse.require("thread.server")

while true do
  server.newIncomingConnection()
  server.updateConnections()
  for _ = 0, 50 do
    local message = love.mintmousse.pop()
    if not message then
      break
    end
    if message.func == "quit" then
      return
    end
  end
end