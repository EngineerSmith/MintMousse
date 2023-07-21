local error = function(str)
  error("MintMousse:Icon Validation:"..tostring(str))
end

local assert = function(bool, errorMessage)
  if not bool then
    error(errorMessage)
  end
end

return function(PATH, icon)
  local svg = require(PATH .. "svg")

  if type(icon) == "string" then
    if icon:find("%.svg$") then
      return love.filesystem.read(icon)
    end
    icon = {
      emoji = icon
    }
  end
  -- Emoji
  if type(icon.emoji) == "string" then
    assert(require("utf8").len(icon.emoji) == 1,
      "It is determined that you haven't given an emoji, raise an issue on github and you have a valid emoji")
  else
    error("icon.emoji must be type string")
  end
  -- Shape
  assert(icon.shape == "rect" or icon.shape == "circle" or icon.shape == nil,
    "icon.shape must be 'rect', 'circle', or nil")
  if icon.shape == "rect" then
    icon.rect = true
  end
  if icon.shape == "circle" then
    icon.circle = true
  end
  assert(not (icon.rect and icon.circle), "Cannot display both rect and circle at the same time")
  -- Color
  local count
  if type(icon.color) == "string" then
    icon.color, count = icon.color:gsub("^#", "%%23")
    assert(svg.color[icon.color] or count ~= 0, icon.color .. " is not a valid color")
  else
    icon.color = nil
  end
  -- inside
  if type(icon.insideColor) == "string" then
    icon.insideColor, count = icon.insideColor:gsub("^#", "%%23")
    assert(svg.color[icon.insideColor] or count ~= 0, icon.insideColor .. " is not a valid color")
  else
    icon.insideColor = icon.color
  end
  -- outside
  if type(icon.outsideColor) == "string" then
    icon.outsideColor, count = icon.outsideColor:gsub("^#", "%%23")
    assert(svg.color[icon.outsideColor] or count ~= 0, icon.outsideColor .. " is not a valid color")
  else
    icon.outsideColor = icon.color
  end

  return icon
end
