local defaultTheme = {
  colorStates = {"primary", "success", "danger", "secondary"},
  striped = true,
  animated = true
}

return function(settings, helper)
  -- theme
  if not settings.theme then
    settings.theme = defaultTheme
  else
    local theme = settings.theme
    for k, v in pairs(defaultTheme) do
      if not theme[k] then
        theme[k] = v
      end
    end

    if type(theme.colorStates) ~= "table" or #theme.colorStates == 0 then
      theme.colorStates = defaultTheme.colorStates
    end

    for i, color in ipairs(theme.colorStates) do
      if type(color) == "number" then
        theme.colorStates[i] = helper.getColor(color)
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
        colorState = settings.theme.colorStates[colorIndex]
      }
      if settings.label then
        bar.percentageLabel = tostring(math.floor(bar.percentage*1000)/1000).."%"
      end
      settings.bars[i] = bar
    else
      if bar.percentage < 0 then bar.percentage = 0 end
      if bar.percentage > 100 then bar.percentage = 100 end
      if settings.label and not bar.percentageLabel then
        bar.percentageLabel = tostring(math.floor(bar.percentage*1000)/1000).."%"
      end
    end
    -- color
    colorIndex = colorIndex + 1
    if colorIndex > #settings.theme.colorStates then
      colorIndex = 1
    end
  end
end
