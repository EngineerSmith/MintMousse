local defaultStyle = {
  color = "primary",
  outline = false
}

return function(settings, helper)
  -- body
  if settings.text then
    settings.text = helper.formatText(settings.text)
  end
  if not (type(settings.disabled) == "boolean" or type(settings.disabled) == "nil") then -- if not bool or nil then set bool to true
    settings.disabled = true -- must be boolean or nil
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
end
