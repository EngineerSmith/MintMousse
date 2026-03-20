local PATH = (...):match("^(.-)[^%.]+$")

local love = love

local errMsg = "MintMousse: Library is missing dependency LÖVE's %s module."

if not love.thread then
  assert(pcall(require, "love.thread"), errMsg:format("thread"))
end

if not love.data then
  assert(pcall(require, "love.data"), errMsg:format("data"))
end

if not love.timer then
  assert(pcall(require, "love.timer"), errMsg:format("timer"))
end

if isMintMousseThread then
  assert(pcall(require, "love.event"), errMsg:format("event"))
end

if love.isThread == nil then
  -- Path module is only loaded on main thread. A user is very unlikely to load it before MintMousse, if ever
  love.isThread = love.path == nil
end