return function(settings, helper)
  -- images
  if settings.imgTop then
    settings.imgTop = helper.formatImage(settings.imgTop)
  end
  if settings.imgBottom then
    settings.imgBottom = helper.formatImage(settings.imgBottom)
  end
  if settings.imgLeft then
    settings.imgLeft = helper.formatImage(settings.imgLeft)
  end
  if settings.imgRight then
    settings.imgRight = helper.formatImage(settings.imgRight)
  end
  if settings.imgOverlay then
    settings.imgOverlay = helper.formatImage(settings.imgOverlay)
  end
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
