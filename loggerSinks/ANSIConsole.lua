local ROOT = (...):match("^(.-)[^%.]+%.[^%.]+$") or ""

local ANSI = require(ROOT .. "logging.ANSI")

local levelColorMap = {
  info    = "green",
  warning = "yellow",
  error   = "red",
  fatal   = { fg = "bright_white", bg = "red" },
  debug   = "cyan",
}

local logNames = {
  info    = "INFO ",
  warning = "WARN ",
  error   = "ERROR",
  fatal   = "FATAL",
  debug   = "DEBUG",
}

local logDelimiters = {
  left  = ANSI.applyANSI("bright_black", "["),
  right = ANSI.applyANSI("bright_black", "]"),
  colon = ANSI.applyANSI("bright_black", ":"),
}

local wrapBrackets = function(inner)
  return logDelimiters.left .. inner .. logDelimiters.right
end

local sink = function(level, logger, time, debugInfo, ...)
  if not love.mintmousse.LOG_ENABLE_PRINT then
    return
  end

  local parts = { }

  local levelColorDef = levelColorMap[level] or "reset"
  local levelText = logNames[level]
  table.insert(parts, wrapBrackets(ANSI.applyANSI(levelColorDef, levelText)))

  if love.mintmousse.LOG_ENABLE_TIMESTAMP then
    local ts = love.mintmousse.formatTimestamp(time)
    table.insert(parts, wrapBrackets(ANSI.applyANSI("bright_blue", ts)))
  end

  if logger then
    local chain = logger:getAncestry()
    if #chain > 0 then
      local prefixParts = { }
      for i = #chain, 1, -1 do
        local node = chain[i]
        local colorDef = node.colorDef or "white"
        table.insert(prefixParts, ANSI.applyANSI(colorDef, node.name))
      end
      local prefixStr = table.concat(prefixParts, logDelimiters.colon)
      table.insert(parts, wrapBrackets(prefixStr))
    end
  end

  if debugInfo and debugInfo ~= "" then
    table.insert(parts, wrapBrackets(ANSI.applyANSI("cyan", debugInfo)))
  end

  local logMessage = table.concat({ ... }, " ")
  table.insert(parts, logMessage)

  GLOBAL_print(table.concat(parts, " "))
end

return sink