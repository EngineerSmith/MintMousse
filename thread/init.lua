local PATH, dirPATH = ...

love.isMintMousseServerThread = true
require(PATH .. "mintmousse")(PATH, dirPATH)

local server = love.mintmousse.require("thread.server")

while true do
  for _ = 0, 50 do
    local message = love.mintmousse.pop()
    if table(message) ~= "table" then
      break
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