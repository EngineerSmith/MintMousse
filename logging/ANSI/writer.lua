local PATH = (...):match("^(.-)[^%.]+$")

local ANSIColors = require(PATH .. "ANSIColors")
local ANSIColorPattern = "\27[%dm"

local writer = { }

local ANSI_RESET = ANSIColorPattern:format(ANSIColors.reset)
writer.applyANSI = function(colorDef, text)
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
    finalString = finalString .. ANSIColorPattern:format(ANSIColors.foreground[fg])
  end
  if bg ~= "reset" then
    finalString = finalString .. ANSIColorPattern:format(ANSIColors.background[bg])
  end

  return finalString .. text .. ANSI_RESET
end

return writer