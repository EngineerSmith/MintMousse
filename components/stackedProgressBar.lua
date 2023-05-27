local defaultStyle = {
  colorStates = {"primary", "success", "danger", "secondary"},
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

    if type(style.colorStates) ~= "table" or #style.colorStates == 0 then
      style.colorStates = defaultStyle.colorStates
    end

    for i, color in ipairs(style.colorStates) do
      if type(color) == "number" then
        style.colorStates[i] = helper.getColor(color)
      end
    end
  end
  -- bars
  local colorIndex = 1
  for i, bar in ipairs(settings.bars) do
    if type(bar) == "number" then
      if bar < 0 then bar = 0 end
      if bar > 100 then bar = 100 end
      local bar = {
        percentage = bar,
        colorState = settings.style.colorStates[colorIndex]
      }
      if settings.label then
        bar.percentageLabel = tostring(math.floor(bar.percentage*1000)/1000).."%"
      end
      settings.bars[i] = bar
    elseif type(bar) == "table" then
      if bar.percentage < 0 then bar.percentage = 0 end
      if bar.percentage > 100 then bar.percentage = 100 end
      if settings.label and not bar.percentageLabel then
        bar.percentageLabel = tostring(math.floor(bar.percentage*1000)/1000).."%"
      end
    end
    -- color
    colorIndex = colorIndex + 1
    if colorIndex > #settings.style.colorStates then
      colorIndex = 1
    end
  end
end
