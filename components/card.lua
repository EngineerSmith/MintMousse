local style = {
  color = nil
}

return function(settings, helper)
  -- images
  if settings.imgTop then
    settings.imgTop = helper.formatImage(settings.imgTop)
  end
  if settings.imgBottom then
    settings.imgBottom = helper.formatImage(settings.imgBottom)
  end
  -- Header and Footer
  if settings.header then
    settings.header = helper.formatText(settings.header)
  end
  if settings.footer then
    settings.footer = helper.formatText(settings.footer)
  end
  -- ensure boolean
  settings.headerTitle = settings.headerTitle ~= nil
  settings.footerSubtext = settings.footerSubtext ~= nil

  -- wrap in body
  if settings.children then
    for _, child in ipairs(settings.children) do
      if type(child.type) == "string" and not child.type:find("^card") then
        child._wrapBody = true
      end
    end
  end

  -- child to render
  return settings.children
end
