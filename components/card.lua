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
  -- text
  if settings.body then
    local body = settings.body
    if body.title then
      body.title = helper.formatText(body.title)
    end
    if body.text then
      body.text = helper.formatText(body.text)
    end
    if body.subtext then
      body.subtext = helper.formatText(body.subtext)
    end
  end
  if settings.children and not settings.body then
    settings.body = { children = settings.children }
  end
  -- child to render
  return settings.children
end
