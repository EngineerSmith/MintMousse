PATH = ...

isMintMousseThread = true
love.mintmousse = require(PATH:sub(1, -2))

local components = require(PATH .. "thread.components")
components.init() -- IMPORTANT! This function works to unblock any thread waiting on MM

require(PATH .. "thread.controller")
require(PATH .. "thread.routes")

local signal = require(PATH .. "thread.signal")
local server = require(PATH .. "thread.server")

local shouldQuit = false
signal.on("quit", function(_)
  shouldQuit = true
  if server.isRunning() then
    server.cleanUp()
  end
end)

signal.emit("init")
while not shouldQuit do
  -- Process incoming thread messages
  for _ = 1, love.mintmousse.MAX_THREAD_MESSAGES do
    local message = love.mintmousse.pop()
    if type(message) ~= "table" then
      break
    end

    signal.emit(message.func, message.args)

    if shouldQuit then
      return
    end
  end

  -- Process network
  server.update()

  love.timer.sleep(love.mintmousse.THREAD_SLEEP) -- Should this be subtractive? E.g. measure time taken by the loop itself?
end