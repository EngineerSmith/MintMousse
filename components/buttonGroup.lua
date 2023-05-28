local defaultStyle = {
  color = "primary",
  outline = false
}

return function(settings, helper)
  if settings.event then
    settings._event = settings.event
  end
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

    if type(style.color) == "number" then
      style.color = helper.getColor(style.color)
    end
  end
  -- children
  local id = 0
  for i, button in ipairs(settings.children) do
    if type(button) == "string" then
      settings.children[i] = {
        text = helper.formatText(button),
        style = settings.style,
        id = settings.id .. ":" .. id
      }
      id = id + 1
      settings.children[i].variable = settings.children[i].text
    else
      if button.text then
        button.text = helper.formatText(button.text)
      end
      if not button.id then
        button.id = settings.id .. ":" .. id
        id = id + 1
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
        if type(button.style.color) == "number" then
          button.style.color = helper.getColor(button.style.color)
        end
      end
    end
  end
end
