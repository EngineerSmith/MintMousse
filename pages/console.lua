local ROOT = (...):match("^(.-)[^%.]+%.[^%.]+$") or ""

local socket = require("socket")

local mintmousse = require(ROOT .. "conf")

local log = mintmousse._logger:extend("Pages"):extend("Console")

local console = {
  name = "Console",
}

console.build = function(tab, config)
  if love.isThread then
    log:error("The console page can only be built on the main thread.")
    return nil
  end

  if console.tab then
    log:warning("Can only have a single instance of this page, removing the previous.")
    console.tab:remove()
  end
  console.tab = tab

  console.tab
    :newCard({ title = "Console", size = 5 })
end

return console