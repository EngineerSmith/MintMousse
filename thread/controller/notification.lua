local signal = require(PATH .. "thread.signal")

local arg = function(args, key, expectedType)
  if not args then return nil end
  local value = args[key]
  if expectedType and type(value) ~= expectedType then
    return nil
  end
  return value
end

signal.on("notify", function(args)
  local message = arg(args, "message", "table")
  if not message then return end

  local title = arg(message, "title", "string")
  local text = arg(message, "text", "string")

  if (not title or title == "") and (not text or text == "") then
    return
  end

  local animatedFade = message.animatedFade == true or nil
  local autoHide = message.autoHide == true or nil
  local hideDelay = type(message.hideDelay) == "number" and math.floor(message.hideDelay) or nil

  signal.emit("broadcast", {
    action = "toast",
    title = title,
    text = text,
    animatedFade = animatedFade,
    autoHide = autoHide,
    hideDelay = hideDelay,
  })
end)