local ROOT = (...):match("^(.-)[^%.]+%.[^%.]+$") or ""

local ffi = require("ffi")

local ANSI = require(ROOT .. "logging.ANSI")
local mintmousse = require(ROOT .. "conf")
local logging = require(ROOT .. "logging")

local checkIsTTY
if jit.os == "Windows" then
  ffi.cdef[[ int _isatty(int fd); ]]
  checkIsTTY = function(fd)
    return ffi.C._isatty(fd) ~= 0
  end
else
  ffi.cdef[[ int isatty(int fd); ]]
  checkIsTTY = function(fd)
    return ffi.C.isatty(fd) ~= 0
  end
end

local isStdOutTTY = checkIsTTY(1)
local isStdErrTTY = checkIsTTY(2)

local theme = { }
local themePlain = {
  separator = ":",
  wrap = function(text) return "[" .. text .. "]" end,
  colorize = function(_, text) return text end,
}

local themeColored = {
  separator = ANSI.applyANSI("bright_black", ":"),
  grayOpen  = ANSI.applyANSI("bright_black", "["),
  grayClose = ANSI.applyANSI("bright_black", "]"),
}

themeColored.wrap = function(text)
  return themeColored.grayOpen .. text .. themeColored.grayClose
end

local colors =  {
  info    = "green",
  warning = "yellow",
  error   = "red",
  fatal   = { fg = "bright_white", bg = "red" },
  debug   = "cyan",
}

themeColored.colorize = function(key, text)
  local color = colors[key] or key or "white"
  return ANSI.applyANSI(color, text)
end

local globalANSISupport = ANSI.isANSISupported
if jit.os == "Windows" then
  globalANSISupport = ANSI.setupANSIConsole()
end

local stdOutTheme = (globalANSISupport and isStdOutTTY) and themeColored or themePlain
local stdErrTheme = (globalANSISupport and isStdErrTTY) and themeColored or themePlain

local formatTimestamp
do
  local configFormat = mintmousse.LOG_TIMESTAMP_FORMAT
  -- Check if the format ends with the milliseconds token %f
  -- This is the fast path; so we can avoid using gsub unless necessary
  if configFormat:sub(-2) == "%f" then
    local dateFmt = configFormat:sub(1, -3)
    formatTimestamp = function(time)
      local seconds = math.floor(time)
      local milliseconds = math.floor((time - seconds) * 1000)
      return os.date(dateFmt, seconds) .. ("%03d"):format(milliseconds)
    end
  else -- Fallback
    formatTimestamp = function(time)
      local seconds = math.floor(time)
      local milliseconds = math.floor((time - seconds) * 1000)
      local dateFmt = configFormat:gsub("%%f", ("%03d"):format(milliseconds))
      return os.date(dateFmt, seconds)
    end
  end
end

local levelDisplayNames = {
  info    = "INFO ",
  warning = "WARN ",
  error   = "ERROR",
  fatal   = "FATAL",
  debug   = "DEBUG",
}

local errBufferLockChannel = love.thread.getChannel(mintmousse.LOCK_LOG_BUFFER_ERR)
local stderrOut = function(_, message)
  logging.flushLogs() -- flush stdout to keep logs in-order
  io.stderr:write(message)
  io.stderr:flush()
end

-- This sink exclusively writes output using io.stdout and io.stderr
local sink = function(level, logger, time, debugInfo, ...)
  local isErrorStream = level == "error" or level == "warning" or level == "fatal"
  local theme = isErrorStream and stdErrTheme or stdOutTheme

  local parts = { }

  local levelName = levelDisplayNames[level] or level:upper()
  table.insert(parts, theme.wrap(theme.colorize(level, levelName)))

  if mintmousse.LOG_ENABLE_TIMESTAMP then
    local ts = formatTimestamp(time)
    table.insert(parts, theme.wrap(theme.colorize("bright_blue", ts)))
  end

  if logger then
    local chain = logger:getAncestry()
    if #chain > 0 then
      local prefixParts = { }
      for i = #chain, 1, -1 do
        local node = chain[i]
        local name = node.name
        name = theme.colorize(node.colorDef or "white", name)
        table.insert(prefixParts, name)
      end
      local prefixStr = table.concat(prefixParts, theme.separator)
      table.insert(parts, theme.wrap(prefixStr))
    end
  end

  if debugInfo and debugInfo ~= "" then
    table.insert(parts, theme.wrap(theme.colorize("cyan", debugInfo)))
  end

  local argCount = select("#", ...)
  local messageParts = { }
  for i = 1, argCount do
    messageParts[i] = tostring(select(i, ...))
  end
  local logMessage = table.concat(messageParts, " ")
  table.insert(parts, logMessage)

  local finalMessage = table.concat(parts, " ") .. "\n"

  if isErrorStream then
    errBufferLockChannel:performAtomic(stderrOut, finalMessage)
  else
    io.stdout:write(finalMessage)
  end
end

return sink