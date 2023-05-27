local defaultStyle = {
  colorState = "primary",
  outline = false,
}

return function(settings, helper)
  -- body
  if settings.text then
    settings.text = helper.formatText(settings.text)
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

    if type(style.colorState) == "number" then
      style.colorState = helper.getColor(style.colorState)
    end
  end
end
