local PATH = ...
PATH = PATH:match("^(.*)%.init$") or PATH
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local logging = require(ROOT .. "logging")

logging.addLogSink(require(PATH .. "console"))