local logNames = {
  info    = "INFO ",
  warning = "WARN ",
  error   = "ERROR",
  fatal   = "FATAL",
  debug   = "DEBUG",
}

local wrapBrackets = function(inner)
  return "[" .. inner .. "]"
end

local sink = function(level, logger, time, debugInfo, ...)
  if not love.mintmousse.LOG_ENABLE_PRINT then
    return
  end

  local parts = { }

  table.insert(parts, wrapBrackets(logNames[level]))

  if love.mintmousse.LOG_ENABLE_TIMESTAMP then
    local ts = love.mintmousse.formatTimestamp(time)
    table.insert(parts, wrapBrackets(ts))
  end

  if logger then
    local chain = logger:getAncestry()
    if #chain > 0 then
      local prefixParts = { }
      for i = #chain, 1, -1 do
        table.insert(prefixParts, chain[i].name)
      end
      local prefixStr = table.concat(prefixParts, ":")
      table.insert(parts, wrapBrackets(prefixStr))
    end
  end

  if debugInfo and debugInfo ~= "" then
    table.insert(parts, wrapBrackets(debugInfo))
  end

  local logMessage = table.concat({ ... }, " ")
  table.insert(parts, logMessage)

  GLOBAL_print(table.concat(parts, " "))
end

return sink