local defaultStyle = {
  color ="dark", -- white spinner
}

return function(settings, helper)
  if type(settings.size) ~= "number" then
    settings.size = nil
  end

  if settings.style then
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