local PATH, dirPATH, settings = ...

require("love.event")
require("love.timer")

require(PATH .. "mintmousse")(PATH, dirPATH)

while true do
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