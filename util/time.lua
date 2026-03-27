local PATH = (...):match("^(.-)%.[^%.]+$")
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local mintmousse = require(ROOT .. "conf")

local time = { }

do
  local configFormat = mintmousse.LOG_TIMESTAMP_FORMAT
  -- Check if the format ends with the milliseconds token %f
  -- This is the fast path; so we can avoid using gsub unless necessary
  if configFormat:sub(-2) == "%f" then
    local dateFmt = configFormat:sub(1, -3)
    time.formatTimestamp = function(time)
      local seconds = math.floor(time)
      local milliseconds = math.floor((time - seconds) * 1000)
      return os.date(dateFmt, seconds) .. ("%03d"):format(milliseconds)
    end
  else -- Fallback
    time.formatTimestamp = function(time)
      local seconds = math.floor(time)
      local milliseconds = math.floor((time - seconds) * 1000)
      local dateFmt = configFormat:gsub("%%f", ("%03d"):format(milliseconds))
      return os.date(dateFmt, seconds)
    end
  end
end

return time