local defaultTheme = {
  colorState = "primary",
  striped = true,
  animated = true,
}

return function(settings, helper)

  if type(settings.min) ~= "number" then
    settings.min = 0
  end
  if type(settings.max) ~= "number" then
    settings.max = 100
  end
  if type(settings.value) ~= "number" then
    settings.value = 0
  end

  if settings.min > settings.max then
    settings.min = settings.max
  end
  if settings.max < settings.min then
    settings.max = settings.min
  end

  if settings.value < settings.min then
    settings.value = settings.min
  end
  if settings.value > settings.max then
    settings.value = settings.max
  end

  settings.percentage = math.floor((settings.min + settings.value) / (settings.max - settings.min)*100)

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
