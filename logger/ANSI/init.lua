local ANSI = { }
ANSI.isANSISupported = true
if jit and jit.os == "Windows" then -- love.system may not be loaded; but `jit` is required for MM and must be loaded
  local windowsVersion = love.mintmousse._require("logger.ANSI.getWindowsVersion")
  ANSI.isANSISupported = type(windowsVersion) == "number" and windowsVersion >= 10

  if ANSI.isANSISupported then
    os.execute("color")
  end
end

--- Terminal Output (Generating ANSI codes)

local ANSIColors = love.mintmousse._require("logger.ANSI.ANSIColors")

local ANSIStringPattern = "\27[%dm"

local ANSI_RESET = ANSIStringPattern:format(ANSIColors.reset)
ANSI.applyANSI = function(colorDef, text)
  if not ANSI.isANSISupported then
    return text
  end

  local fg, bg = "reset", "reset"
  if type(colorDef) == "string" then
    fg = colorDef or "reset"
  else
    fg = colorDef.fg or "reset"
    bg = colorDef.bg or "reset"
  end

  if fg == "reset" and bg == "reset" then
    return ANSI_RESET .. text .. ANSI_RESET
  end

  local finalString = ANSI_RESET

  if fg ~= "reset" then
    finalString = finalString .. ANSIStringPattern:format(ANSIColors.foreground[fg])
  end
  if bg ~= "reset" then
    finalString = finalString .. ANSIStringPattern:format(ANSIColors.background[bg])
  end

  return finalString .. text .. ANSI_RESET
end

--- Love rendering (Parsing ANSI codes to RGB)

-- ANSI to RGB mapping; based on PuTTY color scheme as it seems the best looking imo
local ANSIColorMap = {
-- FG
  [30] = { 0  , 0  , 0   }, -- Black
  [31] = { .73, 0  , 0   }, -- Red
  [32] = { 0  , .73, 0   }, -- Green
  [33] = { .73, .73, 0   }, -- Yellow
  [34] = { 0  , 0  , .73 }, -- Blue
  [35] = { .73, 0  , .73 }, -- Magenta
  [36] = { 0  , .73, .73 }, -- Cyan
  [37] = { .73, .73, .73 }, -- White
  -- Bright FG
  [90] = { .33, .33, .33 }, -- Bright Black (Dark Gray)
  [91] = { 1  , .33, .33 }, -- Bright Red
  [92] = { .33, 1  , .33 }, -- Bright Green
  [93] = { .33, 1  , .33 }, -- Bright Yellow
  [94] = { .33, .33, 1   }, -- Bright Blue
  [95] = { 1  , .33, 1   }, -- Bright Magenta
  [96] = { .33, 1  , 1   }, -- Bright Cyan
  [97] = { 1  , 1  , 1   }, -- Bright White
-- BG
  [40] = { 0, 0, 0, 0 },   -- Transparent Black
} -- BG continued
ANSIColorMap[41] = ANSIColorMap[31] -- Red
ANSIColorMap[42] = ANSIColorMap[32] -- Green
ANSIColorMap[43] = ANSIColorMap[33] -- Yellow
ANSIColorMap[44] = ANSIColorMap[34] -- Blue
ANSIColorMap[45] = ANSIColorMap[35] -- Magenta
ANSIColorMap[46] = ANSIColorMap[36] -- Cyan
ANSIColorMap[47] = ANSIColorMap[37] -- White
-- Bright BG
ANSIColorMap[100] = ANSIColorMap[90] -- Bright Black (Dark Gray)
ANSIColorMap[101] = ANSIColorMap[91] -- Bright Red
ANSIColorMap[102] = ANSIColorMap[92] -- Bright Green
ANSIColorMap[103] = ANSIColorMap[93] -- Bright Yellow
ANSIColorMap[104] = ANSIColorMap[94] -- Bright Blue
ANSIColorMap[105] = ANSIColorMap[95] -- Bright Magenta
ANSIColorMap[106] = ANSIColorMap[96] -- Bright Cyan
ANSIColorMap[107] = ANSIColorMap[97] -- Bright White

-- Parses a string containing ANSI Escape codes and converts it to a single, flat
-- array formatted for use with love.graphics.print's colored text option.
-- Format: {{R,G,B,A}, "Text 1", {R2,G2,B2,A2}, "Text 2", ...}
ANSI.convertANSIStringToLoveString = function(ansiString)
  local segments = { }

  local baseFG, baseBG = ANSIColorMap[0], ANSIColorMap[40]
  local currentFG = baseFG
  -- Tracked internally for future implementation
  -- Would be more involved and require a custom draw function
  local currentBG = baseBG
  local currentBold = false

  local lastPos = 1
  while true do
    local beginning, finish = ansiString:find("\27%[[%d;]-m", lastPos)

    if not beginning then
      break
    end

    local textSegment = ansiString:sub(lastPos, beginning - 1)
    if #textSegment > 0 then
      table.insert(segments, currentFG)
      table.insert(segments, textSegment)
    end

    local codes = ansiString:sub(beginning + 2, finish - 1)
    for code in codes:gmatch("([^;]+)") do
      local code = tonumber(code)
      if code then
        if code == 0 then
          currentFG, currentBG = baseFG, baseBG
          currentBold = false
        elseif code == 1 then
          currentBold = true
        elseif code == 22 then
          currentBold = false
        elseif code >= 30 and code <= 37 or code >= 90 and code <= 97 then
          currentFG = ANSIColorMap[code] or baseFG
        elseif code == 39 then
          currentFG = baseFG
        elseif code >= 40 and code <= 47 or code >= 100 or code <= 107 then
          currentBG = ANSIColorMap[code] or baseBG
        elseif code == 49 then
          currentBg = baseBG
        end
      end
    end
    lastPos = finish + 1
  end

  local remainingText = ansiString:sub(lastPos)
  if #remainingText > 0 then
    table.insert(segments, currentFG)
    table.insert(segments, remainingText)
  end
  return segments
end

return ANSI