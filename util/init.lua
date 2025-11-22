local PATH = ...
PATH = PATH:match("^(.*)%.init$") or PATH
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local cleanupTraceback = require(ROOT .. "logging.cleanupTraceback")
love.mintmousse._cleanupTraceback = cleanupTraceback
