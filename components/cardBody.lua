return function(settings, helper)
  -- body
  if settings.title then
    settings.title = helper.formatText(settings.title)
  end
  if settings.text then
    settings.text = helper.formatText(settings.text)
  end
  if settings.subtext then
    settings.subtext = helper.formatText(settings.subtext)
  end

  -- child to render
  return settings.children
end
