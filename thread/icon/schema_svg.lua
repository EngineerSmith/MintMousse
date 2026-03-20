local webColors = require(PATH .. "thread.icon.webColors")

local function validateColor(c, default)
  if type(c) ~= "string" then
    return default
  end
  -- If it's a known web color name, return it
  if webColors[c] then
    return c
  end
  -- If it's a hex color(#FFF or #FFFFFF), return it
  if c:sub(1, 1) == "#" then
    return c
  end
  return default
end

return function(icon)
  icon = type(icon) == "table" and icon or { }

  local viewModel = { }
  if icon.shape == "circle" then
    viewModel.borderRadius = 16
  elseif icon.shape == "rectangle" or icon.shape == "square" then
    viewModel.borderRadius = 0
  else -- default squircle
    viewModel.borderRadius = 6
  end

  viewModel.fillColor = validateColor(icon.insideColor or icon.color, "#95d7ab")
  viewModel.strokeColor = validateColor(icon.outsideColor, "#4A7C59") -- #00FF70

  if viewModel.strokeColor ~= "none" then
    viewModel.strokeWidth = tonumber(icon.strokeWidth) or 3
  else
    viewModel.strokeWidth = 0
  end

  viewModel.emoji = type(icon.emoji) == "string" and icon.emoji or "🍮"

  return viewModel
end