local signal = {
  events = { }
}

signal.on = function(funcName, func)
  if not signal.events[funcName] then
    signal.events[funcName] = { }
  end
  table.insert(signal.events[funcName], func)
end

signal.emit = function(funcName, args)
  if type(funcName) ~= "string" then
    return
  end
  if type(args) ~= "table" and type(args) ~= "nil" then
    return
  end
  if signal.events[funcName] then
    for _, method in ipairs(signal.events[funcName]) do
      method(args)
    end
  end
end

signal.on("batch", function(args)
  if not args then return end
  for _, command in ipairs(args) do
    signal.emit(command.func, command.args)
  end
end)

return signal