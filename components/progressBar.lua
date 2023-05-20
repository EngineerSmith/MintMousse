local defaultTheme = {
  colorState = "primary",
  striped = true,
  animated = true,
}

return function(settings, helper)

  settings.updateLabel = false

  if type(settings.percentage) ~= "number" then
    settings.percentage = 0
  end
  if settings.percentage < 0 then settings.percentage = 0 end
  if settings.percentage > 100 then settings.percentage = 100 end
  if settings.label and not settings.percentageLabel then
    settings.percentageLabel = tostring(math.floor(settings.percentage*1000)/1000).."%"
    settings.updateLabel = true
  end

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

    if type(theme.colorState) == "number" then
      theme.colorState = helper.getColor(theme.colorState)
    end
  end
end
