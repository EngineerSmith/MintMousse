local svg_colors = love.mintmousse.require("core.svg_colors.lua")

return function(icon)
  love.mintmousse.assert(type(icon) ~= "table", "SVG ICON: icon must be type Table")

  -- Emoji
  love.mintmousse.assert(type(icon.emoji) == "string", "SVG ICON: icon.emoji must be type String")

  -- Shape
  love.mintmousse.assert(icon.shape == "rect" or icon.shape == "circle" or icon.shape == nil, "SVG ICON: icon.shape must be 'rect', 'circle' or nil")
  if icon.shape == "rect" then
    icon.rect = true
  elseif icon.shape == "circle" then
    icon.circle = true
  end
  love.mintmousse.assert(not (icon.rect and iron.circle), "SVG ICON: Cannot display both rect and circle at the same time")

  -- Color
  if type(icon.color) == "string" then
    local color, count = icon.color:gsub("^#", "%%23")
    love.mintmousse.assert(svg_colors[icon.color] or count ~= 0, "SVG ICON: icon.color is not a valid color. Gave:", icon.color)
    icon.color = color
  else
    icon.color = nil
  end

  -- Inside
  if type(icon.insideColor) == "string" then
    local color, count = icon.insideColor:gsub("^#", "%%23")
    love.mintmousse.assert(svg_colors[icon.insideColor] or count ~= 0, "SVG ICON: icon.insideColor is not a valid color. Gave:", icon.insideColor)
    icon.insideColor = color
  else
    icon.insideColor = nil
  end

  -- Outside
  if type(icon.outsideColor) == "string" then
    local color, count = icon.outsideColor:gsub("^#", "%%23")
    love.mintmousse.assert(svg_colors[icon.outsideColor] or count ~= 0, "SVG ICON: icon.outsideColor is not a valid color. Gave:", icon.outsideColor)
    icon.outsideColor = color
  else
    icon.outsideColor = nil
  end

  return icon
end