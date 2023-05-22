return function(settings, helper)
  if type(settings.children) ~= "table" then
    error("Children must be a table")
  end
  
  -- todo set children components that need rendered, to be rendered

  for i, child in ipairs(settings.children) do

    if not child.id then
      child.id = tostring(settings.id) .. ":" .. tostring(i)
    end

    if type(child.title) == "string" then
      child.title = helper.formatText(child.title)
    end
    if type(child.text) == "string" then
      child.text = helper.formatText(child.text)
    end

    -- inherited values
    child.parentID = settings.id
  end
end
