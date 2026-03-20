local PATH = (...):match("^(.*)sync$")
local ROOT = PATH:match("^(.-)thread%.controller%.$")

local mintmousse = require(ROOT .. "conf")

local loggerSync = require(PATH .. "logger"):extend("Sync")

local sync = { }



return sync