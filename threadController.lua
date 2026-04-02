local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")
local threadCommand = require(PATH .. "threadCommand")

local loggerController = mintmousse._logger:extend("Controller")
local iconLogger = loggerController:extend("Icon")

local threadController = {
  threadChannel = love.thread.getChannel(mintmousse.READONLY_THREAD_LOCATION)
}

threadController.start = function(config)
  local thread = threadController.threadChannel:peek()
  if not thread:isRunning() then
    thread:start(PATH)
  end

  if config then
    if config.title ~= nil and type(config.title) ~= "string" then
      loggerController:warning("config.title expected to be type string")
      config.title = nil
    end

    if config.host ~= nil and type(config.host) ~= "string" then
      loggerController:warning("config.host expected to be type string")
      config.host = nil
    end

    if config.port ~= nil and type(config.port) ~= "number" then
      loggerController:warning("config.port expected to be type number")
      config.port = nil
    end

    if config.autoIncrement ~= nil then
      config.autoIncrement = config.autoIncrement == true
    end

    if config.whitelist ~= nil then
      threadController.addToWhitelist(config.whitelist, "config.whitelist")
    end
  end

  -- Whitelist is sent separately, so remove it from config, and added 
  --      back after so we don't break the config table
  local whitelist
  if config then
    whitelist, config.whitelist = config.whitelist, nil
  end
  threadCommand.call("start", {
    config = config,
  })
  if config then
    config.whitelist = whitelist
  end
end

threadController.stop = function(noWait)
  threadCommand.commandQueue:performAtomic(function(channel)
    channel:clear()
    threadCommand.call("quit")
  end)
  if not noWait then
    threadController.wait()
  end
end

threadController.wait = function()
  threadController.threadChannel:performAtomic(function(channel)
    local thread = channel:peek()
    thread:wait()
  end)
end

threadController.addToWhitelist = function(additions, context)
  if additions == nil then return end

  local source = context or "additions"

  if type(additions) == "table" then
    if #additions == 0 then return end

    for i, addition in ipairs(additions) do
      if type(addition) ~= "string" then
        loggerController:warning(source .. "[" .. tostring(i) .. "] expected to be type string")
        return
      end
    end
  elseif type(additions) ~= "string" then
    loggerController:warning(source, "expected to be type table or string")
    return
  end

  threadCommand.call("addToWhitelist", { additions = additions })
end

threadController.removeFromWhitelist = function(removals)
  if removals == nil then return end

  if type(removals) == "table" then
    if #removals == 0 then return end
    for i, removal in ipairs(removals) do
      if type(removal) ~= "string" then
        loggerController:warning("removals[" .. tostring(i) .. "] expected to be type string")
        return
      end
    end
  elseif type(removals) ~= "string" then
    loggerController:warning("removals expected to be type table or string")
    return
  end

  threadCommand.call("removeFromWhitelist", { removals = removals })
end

threadController.clearWhitelist = function()
  threadCommand.call("clearWhitelist")
end

local pngMagicNumber = string.char(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)
local jpegMagicNumber = string.char(0xff, 0xd8, 0xff)

threadController.setIcon = function(icon)
  if type(icon) == "userdata" then
    if icon.typeOf and icon:typeOf("Data") then
      icon = icon:getString()
    end
  end
  if type(icon) == "table" then
    threadCommand.call("setSchemaIcon", {
      icon = icon,
    })
    return
  elseif type(icon) == "string" then
    if lfs.getInfo(icon, "file") then
      local temp = icon:lower()
      local extension = icon:lower():match("%.(%w+)$")
      if extension == "png" or extension == "jpeg" or extension == "jpg" or
         extension == "svg" or extension == "ico" then
        threadCommand.call("setIconFromFile", {
          filepath = icon,
        })
        return
      end
      iconLogger:warning("Valid file provided, invalid file extension. Only .PNG, .JPEG, .JPG, .ICO, or .SVG are supported for icon from file.")
      return
    elseif icon:sub(#pngMagicNumber) == pngMagicNumber then
      threadController.setIconRaw(icon, "image/png")
      return
    elseif icon:sub(#jpegMagicNumber) == jpegMagicNumber then
      threadController.setIconRaw(icon, "image/jpeg")
      return
    end
  end
  iconLogger:warning("Invalid icon provided. Please supply either an SVG schema table, a file path to a .PNG, .JPEG, .JPG, or .SVG image, or raw PNG or JPEG image data (identified by their magic numbers).")
end

threadController.setIconRaw = function(icon, iconType)
  threadCommand.call("setIconRaw", {
    icon = icon,
    iconType = iconType,
  })
end

-- https://realfavicongenerator.net @ 2026 Q1
threadController.setIconRFG = function(filepath)
  iconLogger:assert(type(filepath) == "string", "Filepath must be type String")
  iconLogger:assert(filepath:lower():match("%.zip$"), "Invalid filepath, must end with .ZIP file extension. Gave:", filepath)
  iconLogger:assert(love.filesystem.getInfo(filepath), "Invalid filepath, couldn't find file at given path. Gave:", filepath)
  threadCommand.call("setIconRFG", {
    filepath = filepath,
  })
end

threadController.setTile = function(title)
  loggerController:assert(type(title) == "string", "Title must be type String")
  threadCommand.call("setTitle", {
    title = title,
  })
end

threadController.notify = function(message)
  if type(message) == "string" then
    message = {
      text = message,
    }
  end
  loggerController:assert(type(message) == "table", "Message must be type Table")
  if not message.title and not message.text then
    return -- If we have nothing to send; why send it?
  end
  threadCommand.call("notify", {
    message = message,
  })
end

return threadController