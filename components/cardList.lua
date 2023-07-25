return function(settings, helper)
  if settings.children then
    local childComponents = {}
    for i, child in ipairs(settings.children) do
      local t = type(child)
      if t == "string" then
        settings.children[i] = helper.formatText(child)
      elseif t == "table" then -- assume component
        table.insert(childComponents, child)
      end
    end
    return childComponents[1] and childComponents or nil
  end
end
