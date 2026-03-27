local ROOT = (...):match("^(.-)[^%.]+%.[^%.]+$") or ""

local socket = require("socket")

local mintmousse = require(ROOT .. "conf")
local timeUtil = require(ROOT .. "util.time")

local log = mintmousse._logger:extend("Pages"):extend("Console")

local console = {
  name = "Console",
}

mintmousse.addGlobalLogSink(function(level, logger, time, debugInfo, ...)
  if not console.logViewer then
    return
  end

  local log = { level = level }

  if mintmousse.LOG_ENABLE_TIMESTAMP then
    log.time = timeUtil.formatTimestamp(time)
  end

  log.loggerAncestry = logger:getAncestry()

  if debugInfo and debugInfo ~= "" then
    log.debugInfo = debugInfo
  end

  local argCount = select("#", ...)
  local messageParts = { }
  for i = 1, argCount do
    local value = select(i, ...)
    if type(value) == "table" and logger then
      value = logger.inspect(value, "deep")
    end
    messageParts[i] = tostring(value)
  end

  log.message = table.concat(messageParts, " ")

  console.logViewer.log = log
end)

console.build = function(tab, config)
  if love.isThread then
    log:error("The console page can only be built on the main thread.")
    return nil
  end

  if console.tab then
    log:warning("Can only have a single instance of this page, removing the previous. This will clear the current logs.")
    console.tab:remove()
  end
  console.tab = tab

  local card = console.tab:newCard({ size = 5 })
  console.logViewer = card:newCardBody():newLogViewer({ maxLines = 28 })

end

return console