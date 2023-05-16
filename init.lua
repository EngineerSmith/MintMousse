local PATH = ... .. "."
local dirPATH = PATH:gsub("%.", "/")

local thread = love.thread.newThread(dirPATH .. "thread.lua")

local mintMousse = { }

mintMousse.start = function(consoleSettings, settings)
  thread:start(PATH, dirPATH, consoleSettings, settings, "foo", "bar")
end

love.handlers["bar"] = function(...)
  print(...)
end

return mintMousse
