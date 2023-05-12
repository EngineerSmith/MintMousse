return function(settings, helper)
  if settings.items then
    local childComponents = { }
    for i, item in ipairs(settings.items) do
      local t = type(item)
      if t == "string" then
        settings.items[i] = helper.formatText(item)
      elseif t == "table" then -- assume component
        table.insert(childComponents, item)
      end
    end
    return childComponents[1] and childComponents or nil
  end
end