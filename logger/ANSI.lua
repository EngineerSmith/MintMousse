love.mintmousse._isANSISupported = true
if jit and jit.os == "Windows" then -- love.system may not be loaded; but `jit` is required for MM and must be loaded
  local windowsVersion = love.mintmousse._require("logger.getWindowsVersion")
  love.mintmousse._isANSISupported = type(windowsVersion) == "number" and windowsVersion >= 10

  if love.mintmousse._isANSISupported then
    os.execute("color")
  end
end

if love.mintmousse._isANSISupported then
  love.mintmousse._applyANSIColor = function(colorKey, text)
    local logStyles = love.mintmousse._logging._logStyles
    return logStyles[colorKey].color .. text .. logStyles["STOP"].color
  end
else
  love.mintmousse._applyANSIColor = function(_, text) -- To support non-colour consoles
    return text
  end
end

love.mintmousse._stripANSIColor = function(text)
  return text:gsub(love.mintmousse._logging._ANSIPattern, "")
end

-- ANSI to RGB mapping; based on PuTTY color scheme as it seems the best looking imo
local ANSIColorMap
ANSIColorMap = {
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
}
  -- BG continued
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
love.mintmousse._convertANSIStringToLoveString = function(ansiString)
  local segments = { }

  local baseFG, baseBG = ANSIColorMap[0], ANSIColorMap[40]
  local currentFG = baseFG
  -- Tracked internally for future implementation
  -- Would be more involved and require a custom draw function
  local currentBG = baseBG
  local currentBold = false

  local lastPos = 1
  while true do
    local beginning, finish = ansiString:find(love.mintmousse._logging._ANSIPattern, lastPos)

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