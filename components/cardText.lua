return function(settings, helper)
  if settings.text then
    settings.text = helper.formatText(settings.text)
  end
end
