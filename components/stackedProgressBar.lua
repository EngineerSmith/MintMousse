local defaultStyle = {
  colors = {"primary", "success", "danger", "secondary"},
  striped = true,
  animated = true
}

return function(settings, helper)
  -- style
  if not settings.style then
    settings.style = defaultStyle
  else
    local style = settings.style
    for k, v in pairs(defaultStyle) do
      if not style[k] then
        style[k] = v
      end
    end

    if type(style.colors) ~= "table" or #style.colors == 0 then
      style.colors = defaultStyle.colors
    end

    for i, color in ipairs(style.colors) do
      if type(color) == "number" then
        style.colors[i] = helper.getColor(color)
      end
    end
  end
  -- bars
  local colorIndex = 1
  for i, bar in ipairs(settings.bars) do
    if type(bar) == "number" then
      if bar < 0 then
        bar = 0
      end
      if bar > 100 then
        bar = 100
      end
      bar = {
        percentage = bar
      }
      settings.bars[i] = bar
      if settings.label then
        bar.percentageLabel = tostring(math.floor(bar.percentage * 1000) / 1000) .. "%"
      end
    elseif type(bar) == "table" then
      if bar.percentage < 0 then
        bar.percentage = 0
      end
      if bar.percentage > 100 then
        bar.percentage = 100
      end
      if settings.label and not bar.percentageLabel then
        bar.percentageLabel = tostring(math.floor(bar.percentage * 1000) / 1000) .. "%"
      end
    end
    if not bar.id then
      bar.id = settings.id .. ":" .. i
    end
    if not bar.color then
      bar.color = settings.style.colors[colorIndex]
    end
    -- color
    colorIndex = colorIndex + 1
    if colorIndex > #settings.style.colors then
      colorIndex = 1
    end
  end
end
