local PATH = ...
PATH = PATH:match("^(.*)%.init$") or PATH
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local cleanupTraceback = require(ROOT .. "logging.cleanupTraceback")
love.mintmousse._cleanupTraceback = cleanupTraceback

love.mintmousse.formatTimestamp = function(time)
  local seconds = math.floor(time)
  local milliseconds = math.floor((time - seconds)*1000)
  -- todo optimise; calculate timestamp format once; aim to remove the gsub
  local dateFormat = love.mintmousse.LOG_TIMESTAMP_FORMAT:gsub("%%f", ("%03d"):format(milliseconds))
  return os.date(dateFormat, seconds)
end