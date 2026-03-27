local signal = require(PATH .. "thread.signal")

local server = require(PATH .. "thread.server")
local whitelist = require(PATH .. "thread.server.whitelist")

local arg = function(args, key, expectedType)
  if not args then return nil end
  local value = args[key]
  if expectedType and type(value) ~= expectedType then
    return nil
  end
  return value
end

signal.on("start", function(args)
  local config = arg(args, "config", "table") or { }

  signal.emit("setTitle", { title = config.title })
  signal.emit("addToWhitelist", { additions = config.whitelist })

  server.start(config.host, config.port, config.autoIncrement)
end)

signal.on("addToWhitelist", function(args)
  local additions = arg(args, "additions")

  if type(additions) == "table" then
    for _, rule in ipairs(additions) do
      whitelist.add(rule)
    end
  elseif type(additions) == "string" then
    whitelist.add(additions)
  end
end)

signal.on("removeFromWhitelist", function(args)
  local removals = arg(args, "removals")

  if type(removals) == "table" then
    for _, rule in ipairs(removals) do
      whitelist.remove(rule)
    end
  elseif type(removals) == "string" then
    whitelist.remove(removals)
  end
end)

signal.on("clearWhitelist", function(_)
  whitelist.clear()
end)

signal.on("broadcast", function(args)
  if not server:isRunning() then return end

  -- local message = arg(args, "message")
  -- if not message then return end

  for client in pairs(server.clients) do
    if not client.closing and client.queue then
      client:queue(args)
    end
  end
end)