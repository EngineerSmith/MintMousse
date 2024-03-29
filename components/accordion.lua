return function(settings, helper)
  if type(settings.children) ~= "table" then
    error("Children must be a table!")
  end

  local componentChildren = {}

  for i, child in ipairs(settings.children) do
    if child.type then
      table.insert(componentChildren, child)
    else
      child.id = settings.id .. "_" .. i

      if type(child.title) == "string" then
        child.title = helper.formatText(child.title)
      end

      if type(child.text) == "string" then
        child.text = helper.formatText(child.text)
      end
    end

    child._idTitle = "title_" .. child.id

    -- inherited values
    child.parentID = settings.id
  end

  if settings.beforeText then
    table.insert(componentChildren, settings.beforeText)
  end
  if settings.afterText then
    table.insert(componentChildren, settings.afterText)
  end

  return #componentChildren ~= 0 and componentChildren or nil
end
