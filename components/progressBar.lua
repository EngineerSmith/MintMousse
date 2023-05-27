local defaultStyle = {
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
    settings.generatedLabel = tostring(math.floor(settings.percentage*1000)/1000).."%"
    settings.updateLabel = true
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
