local PATH = (...):match("^(.*)state$")
local ROOT = PATH:match("^(.-)thread%.controller%.$")

local mintmousse = require(ROOT .. "conf")

local loggerController = mintmousse._logger:extend("Controller")

return loggerController