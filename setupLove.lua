local PATH = (...):match("^(.-)[^%.]+$")

local love = love

if not love.thread then
  assert(pcall(require, "love.thread"), "MintMousse: Library is missing dependency LÖVE's thread module.")
end

if not love.timer then
  assert(pcall(require, "love.timer"), "MintMousse: Library is missing dependency LÖVE's timer module.")
end

if love.isMintMousseThread then
  assert(pcall(require, "love.event"), "MintMousse: Library is missing dependency LÖVE's event module.")
end

if love.isThread == nil then
  -- Path module is only loaded on main thread; a user is unlikely to load it
  love.isThread = love.path == nil
end