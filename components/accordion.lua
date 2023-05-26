return function(settings, helper)
  if type(settings.children) ~= "table" then
    error("Children must be a table")
  end
  
  local componentChildren = { }

  for i, child in ipairs(settings.children) do
    if child.type and not child.text then
      table.insert(componentChildren, child)
    else
      child.id = tostring(settings.id) .. ":" .. tostring(i)
    end
    
    if type(child.title) == "string" then
      child.title = helper.formatText(child.title)
    end
    
    if not child.type and type(child.text) == "string" then
      child.text = helper.formatText(child.text)
    end

    -- inherited values
    child.parentID = settings.id
  end

  return #componentChildren ~= 0 and componentChildren or nil
end
