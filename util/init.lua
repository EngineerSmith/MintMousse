local PATH = ...
PATH = PATH:match("^(.*)[^%.]+$") or PATH
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local util = { }

local cleanupTraceback = require(ROOT .. "logging.cleanupTraceback")
util.cleanupTraceback = cleanupTraceback

util.sanitizeText = function(text)
  local lustache = require(ROOT .. "libs.lustache")
  return lustache:render("{{text}}", { text = text })
end

return util