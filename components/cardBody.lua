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
  local children = settings.children
  if settings.beforeText or settings.afterText then
    children = {}
    if settings.children then
      for k, v in ipairs(settings.children) do
        children[k] = v
      end
    end
  end
  if settings.beforeText then
    table.insert(children, settings.beforeText)
  end
  if settings.afterText then
    table.insert(children, settings.afterText)
  end
  return children
end
