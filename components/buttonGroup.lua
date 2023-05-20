local defaultTheme = {
  colorState = "primary",
  outline = false
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

    if type(theme.colorState) == "number" then
      theme.colorState = helper.getColor(theme.colorState)
    end
  end
  -- buttons
  for i, button in ipairs(settings.buttons) do
    if type(button) == "string" then
      settings.buttons[i] = {
        text = helper.formatText(button),
        theme = settings.theme
      }
    else
      if button.text then
        button.text = helper.formatText(button.text)
      end
      -- theme
      if not button.theme then
        button.theme = settings.theme
      elseif button.theme then
        for k, v in pairs(settings.theme) do
          if not button.theme[k] then
            button.theme[k] = v
          end
        end
        if type(button.theme.colorState) == "number" then
          button.theme.colorState = helper.getColor(button.theme.colorState)
        end
      end
    end
  end
end
