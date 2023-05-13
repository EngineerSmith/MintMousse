return function(settings, helper)
  if type(settings.items) ~= "table" then
    error("Items must be a table")
  end

  for i, item in ipairs(settings.items) do

    if not item.id then
      item.id = tostring(settings.id) .. tostring(i)
    end

    if type(item.title) == "string" then
      item.title = helper.formatText(item.title)
    end
    if type(item.text) == "string" then
      item.text = helper.formatText(item.text)
    end

    -- inherited values
    item.parentID = settings.id
  end
end
