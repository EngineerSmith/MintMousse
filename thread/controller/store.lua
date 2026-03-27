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
  if comp then store.addComponent(comp) end
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

signal.on("pushComponent", function(args)
  local id    = arg(args, "id")
  local index = arg(args, "index")
  local value = arg(args, "value")
  if id and index and value then
    store.pushComponent(id, index, value)
  end
end)

signal.on("setChildrenOrder", function(args)
  local id    = arg(args, "id")
  local array = arg(args, "newOrder", "table")
  if id and array and #array > 0 then
    store.setChildrenOrder(id, array)
  end
end)

signal.on("moveBefore", function(args)
  local id        = arg(args, "id", "string")
  local siblingID = arg(args, "siblingID", "string")
  if id and siblingID then
    store.moveBefore(id, siblingID)
  end
end)

signal.on("moveAfter", function(args)
  local id        = arg(args, "id", "string")
  local siblingID = arg(args, "siblingID", "string")
  if id and siblingID then
    store.moveAfter(id, siblingID)
  end
end)

signal.on("moveToFront", function(args)
  local id = arg(args, "id", "string")
  if id then store.moveToFront(id) end
end)

signal.on("moveToBack", function(args)
  local id = arg(args, "id", "string")
  if id then store.moveToBack(id) end
end)
