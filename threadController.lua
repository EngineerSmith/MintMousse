local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")
local threadCommunication = require(PATH .. "threadCommunication")

local controllerLogger = mintmousse._logger:extend("Controller")
local iconLogger = controllerLogger:extend("Icon")

local threadController = {
  threadChannel = love.thread.getChannel(mintmousse.READONLY_THREAD_LOCATION)
}

threadController.start = function(config)
  local thread = threadController.threadChannel:peek()
  if not thread:isRunning() then
    thread:start(mintmousse._PATH, mintmousse._DIRECTORY_PATH)
  end
  -- todo config validation
  threadCommunication.push({
    func = "start",
    config,
  })
end

threadController.stop = function(noWait)
  threadCommunication.commandQueue(function(channel)
    channel:clear()
    threadCommunication.push({
      func = "quit",
    })
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

local pngMagicNumber = string.char(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)
local jpegMagicNumber = string.char(0xff, 0xd8, 0xff)

threadController.setIcon = function(icon)
  if type(icon) == "userdata" then
    if icon.typeOf and icon:typeOf("Data") then
      icon = icon:getString()
    end
  end
  if type(icon) == "table" then
    icon = require(PATH .. "icon.svg_icon")(icon)
    threadCommunication.push({
      func = "setSVGIcon",
      icon,
    })
    return
  elseif type(icon) == "string" then
    if lfs.getInfo(icon, "file") then
      local temp = icon:lower()
      if temp:match("%.png$") or temp:match("%.jpeg$") or temp:match("%.jpg$") or temp:match("%.svg$") then
        threadCommunication.push({
          func = "setIconFromFile",
          icon,
        })
        return
      end
      iconLogger:warning("Valid file provided, invalid file extension. Only .PNG, .JPEG, .JPG, or .SVG are supported for icon from file.")
      return
    elseif icon:sub(#pngMagicNumber) == pngMagicNumber then
      threadController.setIconRaw(icon, "image/png")
      return
    elseif icon:sub(#jpegMagicNumber) == jpegMagicNumber then
      threadController.setIconRaw(icon, "image/jpeg")
      return
    end
  end
  iconLogger:warning("Invalid icon provided. Please supply either an SVG table, a file path to a .PNG, .JPEG, .JPG, or .SVG image, or raw PNG or JPEG image data (identified by their magic numbers).")
end

threadController.setIconRaw = function(icon, iconType)
  threadCommunication.push({
    func = "setIconRaw",
    icon, iconType,
  })
end

-- https://realfavicongenerator.net @ 2025 Q1
threadController.setIconRFG = function(filepath)
  iconLogger:assert(type(filepath == "string", "Filepath must be type String"))
  iconLogger:assert(filepath:lower():match("%.zip$"), "Invalid filepath, must end with .ZIP file extension. Gave:", filepath)
  iconLogger:assert(love.filesystem.getInfo(filepath), "Invalid filepath, couldn't find file at given path. Gave:", filepath)
  threadCommunication.push({
    func = "setIconRFG",
    filepath,
  })
end

threadController.setTile = function(title)
  controllerLogger:assert(type(title) == "string", "Title must be type String")
  threadCommunication.push({
    func = "setTitle",
    title,
  })
end

return threadController