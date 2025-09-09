local capture = ...
--[[

Calling this file from within conf.lua saves main thread start up time by 2.5ms on my machine.
  This script allows a later blocking call to complete faster.

]]

require("love.thread") -- required if called from conf.lua

-- todo: Why is this a function? Why not *just* run the code?
--     It's probably a function so it can be called in mm.lua
--     Could we just load this file as a chunk instead of forcing it to return a function then?
return function()
  local path, directoryPath
  if type(love.mintmousse) == "table" then
    path = love.mintmousse.path
    directoryPath = love.mintmousse.directoryPath
  else
    path = capture:match("^(.+)%.prepare$") .. "."
    directoryPath = path:gsub("%.", "/")
  end

  -- Load our channel IDs
  local mintmousse = love.mintmousse or require(path..".conf")(path, directoryPath)

  local channel = love.thread.getChannel(mintmousse.READONLY_THREAD_LOCATION)
  local thread = channel:peek()
  if type(thread) == "userdata" and thread:typeOf("Thread") then
    if not thread:isRunning() then
      thread:start(path, directoryPath)
    end
    return
  end

  local thread = love.thread.newThread(directoryPath .. "thread/init.lua")
  thread:start(path, directoryPath)
  channel:performAtomic(function()
    channel:clear()
    channel:push(thread)
  end)

end