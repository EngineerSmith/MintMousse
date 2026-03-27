local mintmousse = ...

local log = mintmousse._loggerComponents:extend("HorizontalRule")

local horizontalRule = { }

horizontalRule.onCreate = function(component)
  if type(component.margin) ~= "number" then
    return
  end

  local wasMargin = component.margin
  component.margin = math.min(5, math.max(0, math.floor(component.margin)))

  if component.margin ~= wasMargin then
    log:info("HorizontalRule component[", component.id, "].margin required clamping. Changed from", wasMargin, "to", component.margin)
  end
end

return horizontalRule