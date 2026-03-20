local idUtil = require(PATH .. "util.id")

local signal = require(PATH .. "thread.signal")

local store = require(PATH .. "thread.store")

local arg = function(args, key, expectedType)
  if not args then return nil end
  local value = args[key]
  if expectedType and type(value) ~= expectedType then
    return nil
  end
  return value
end

signal.on("setTitle", function(args)
  local title = arg(args, "title", "string")
  if title then store.setTitle(title) end
end)

signal.on("newTab", function(args)
  local id    = arg(args, "id")
  local title = arg(args, "title", "string")
  local index = arg(args, "index", "number") and math.floor(args.index) or nil
  if id then store.newTab(id, title, index) end
end)

signal.on("addComponent", function(args)
  local comp = arg(args, "component")
  if comp then store.addComponent(comp, arg(args, "index", "number")) end
end)

signal.on("removeComponent", function(args)
  local id = arg(args, "id")
  if id then store.removeComponent(id) end
end)

signal.on("updateComponent", function(args)
  local id    = arg(args, "id")
  local index = arg(args, "index")
  if id and index then
    store.updateComponent(id, index, args and args.value)
  end
end)

signal.on("reorderChildren", function(args)
  local id   = arg(args, "id")
  local arr  = arg(args, "newOrderArray", "table")
  if id and arr and #arr > 0 then
    store.reorderChildren(id, arr)
  end
end)

signal.on("moveComponent", function(args)
  local id       = arg(args, "id")
  local newIndex = arg(args, "newIndex", "number")
  if id and newIndex then
    store.moveComponent(id, newIndex)
  end
end)