local colors = {
  black   = true,
  red     = true,
  green   = true,
  yellow  = true,
  blue    = true,
  magenta = true,
  cyan    = true,
  white   = true,
  bright_black   = true,
  bright_red     = true,
  bright_green   = true,
  bright_yellow  = true,
  bright_blue    = true,
  bright_magenta = true,
  bright_cyan    = true,
  bright_white   = true,
}

colors.validateColorDef = function(colorDef)
  if type(colorDef) == "table" then
    if colorDef.fg and not colors[colorDef.fg] then colorDef.fg = nil end
    if colorDef.bg and not colors[colorDef.bg] then colorDef.bg = nil end

    if colorDef.fg or colorDef.bg then
      return colorDef
    end
  elseif type(colorDef) == "string" then
    if colors[colorDef] then
      return colorDef
    end
  end
  return nil
end

return colors