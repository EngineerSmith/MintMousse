local PATH, dirPATH, settings = ...

-- love.data, love.filesystem, & love.thread is preloaded for threads, other modules must be loaded
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
  love.timer.sleep(0.0001)
end