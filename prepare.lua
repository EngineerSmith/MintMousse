local capture = ...
--[[

Calling this file from within conf.lua saves main thread start up time by 2.5ms my machine.

]]

require("love.thread") -- required if called from conf.lua

local ran = false
return function(shouldWait)
  if ran then
    return
  end

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
  if channel:peek() then
    return
  end
  local thread = love.thread.newThread(directoryPath .. "thread/init.lua")
  thread:start(path, directoryPath)
  channel:push(thread)

  ran = true
end