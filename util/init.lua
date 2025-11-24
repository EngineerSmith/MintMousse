local PATH = ...
PATH = PATH:match("^(.*)%.[^%.]+$") or PATH
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local util = { }

local cleanupTraceback = require(ROOT .. "logging.cleanupTraceback")
util.cleanupTraceback = cleanupTraceback

-- Only use this if necessary. All MintMousse components will handle sanitizing for you.
--   If you have non-standard components, it may help to sanitize to avoid XSS attacks
--   unless you know you've programmed them correctly.
util.sanitizeText = function(text)
  local lustache = love.mintmousse.require("libs.lustache")
  return lustache:render("{{text}}", { text = text })
end

return util