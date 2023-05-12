local defaultTheme = {
  colorState = "primary",
  outline = false,
}

return function(settings, helper)
  -- body
  if settings.text then
    settings.text = helper.formatText(settings.text)
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
