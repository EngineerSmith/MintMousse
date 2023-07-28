return function(settings, helper)
  if settings.title then
    settings.title = helper.formatText(settings.title)
  end

  -- child to render
  local children
  if settings.beforeText or settings.afterText then
    children = {}
  end
  if settings.beforeText then
    table.insert(children, settings.beforeText)
  end
  if settings.afterText then
    table.insert(children, settings.afterText)
  end
  return children
end
