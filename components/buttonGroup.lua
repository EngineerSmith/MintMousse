local defaultStyle = {
  colorState = "primary",
  outline = false
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

    if type(style.colorState) == "number" then
      style.colorState = helper.getColor(style.colorState)
    end
  end
  --
  settings.vertical = true
  -- buttons
  for i, button in ipairs(settings.buttons) do
    if type(button) == "string" then
      settings.buttons[i] = {
        text = helper.formatText(button),
        style = settings.style
      }
      settings.buttons[i].variable = settings.buttons[i].text
    else
      if button.text then
        button.text = helper.formatText(button.text)
      end
      if not button.event then
        button.event = settings.event
      end
      -- style
      if not button.style then
        button.style = settings.style
      elseif button.style then
        for k, v in pairs(settings.style) do
          if not button.style[k] then
            button.style[k] = v
          end
        end
        if type(button.style.colorState) == "number" then
          button.style.colorState = helper.getColor(button.style.colorState)
        end
      end
    end
  end
end
