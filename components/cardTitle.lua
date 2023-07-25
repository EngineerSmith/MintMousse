return function(settings, helper)
  if settings.title then
    settings.title = helper.formatText(settings.title)
  end
end
