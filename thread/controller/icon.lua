local lfs = love.filesystem

local lustache = require(PATH .. "libs.lustache")

local signal = require(PATH .. "thread.signal")
local store = require(PATH .. "thread.store")
local http = require(PATH .. "thread.server.protocol.http")

local loggerIcon = love.mintmousse._logger:extend("Icon")

local dir = PATH:gsub("%.", "/")

local contentTypeMap = {
  ["png"]         = "image/png",
  ["jpg"]         = "image/jpeg",
  ["jpeg"]        = "image/jpeg",
  ["svg"]         = "image/svg+xml",
  ["webmanifest"] = "application/manifest+json",
  ["ico"]         = "image/x-icon",
  ["xml"]         = "application/xml",
}

local getContentType = function(path)
  local extension = (path:match("%.(%w+)$") or ""):lower()
  return contentTypeMap[extension] or "application/octet-stream"
end

local isImageType = function(ct)
  return ct and ct:match("^image/") ~= nil
end

local arg = function(args, key, expectedType)
  if not args then return nil end
  local value = args[key]
  if type(expectedType) == "string" then
    if type(value) ~= expectedType then
      return nil
    end
  elseif type(expectedType) == "table" then
    local success = false
    for _, expected in ipairs(expectedType) do
      if type(value) == "userdata" and value.typeOf then
        if value:typeOf(expected) then
          success = true
          break
        end
      elseif type(value) == expected then
        success = true
        break
      end
    end
    if not success then
      return nil
    end
  end
  return value
end

local readTemplate = function(path)
  local content, errorMessage = lfs.read(path)
  if type(content) ~= "string" then
    loggerIcon:error("Failed to read file", path, ". Reason:", errorMessage or "UNKNOWN")
    return ""
  end
  return content
end

signal.on("setSchemaIcon", function(args)
  local icon = arg(args, "icon", "table")
  if not icon then return end

  local viewModel = require(PATH .. "thread.icon.schema_svg")(icon)
  local template = readTemplate(dir .. "thread/icon/template.svg.mustache")
  local svg = lustache:render(template, viewModel)

  signal.emit("setIconRaw", {
    icon = svg,
    iconType = "image/svg+xml",
  })
end)

signal.on("setIconFromFile", function(args)
  local filepath = arg(args, "filepath", "string")
  if not filepath or not lfs.getInfo(filepath) then return end

  local iconType = getContentType(filepath)
  if not isImageType(iconType) then
    loggerIcon:warning("setIconFromFile only supports image/* types. Got", iconType, "for", filepath)
    return
  end

  local icon, errorMessage = lfs.read("data", filepath)
  if not icon then
    loggerIcon:warning("Failed to read icon file:", filepath)
    return
  end

  signal.emit("setIconRaw", {
    icon = icon,
    iconType = iconType,
  })
end)

local mount = {
  location = nil,
  filepath = nil,
}

signal.on("setIconRaw", function(args)
  local icon = arg(args, "icon", { "string", "Data" })
  local iconType = arg(args, "iconType", "string")
  if not icon or not iconType then return end

  -- Cleanup RFG mount + route
  if mount.http then
    http.removeMethod("GET", mount.http)
    mount.http = nil
  end
  if mount.data then
    lfs.unmount(mount.data)
    mount.data = nil
    mount.location = nil
  end

  mount.http = love.mintmousse.FAVICON_PATH .. "/icon"

  http.addMethod("GET", mount.http, function(request, _)
    return 200, {
      ["cache-control"] = love.mintmousse.CACHE_CONTROL_HEADER,
      ["content-type"] = iconType,
    }, type(icon) == "string" and icon or icon:getString()
  end)

  local template = readTemplate(dir .. "thread/icon/icon.mustache")
  local html = lustache:render(template, {
    iconEndPoint = mount.http,
    iconType = iconType,
  })

  store.setIconHTML(html)
end)

signal.on("setIconRFG", function(args)
  local filepath = arg(args, "filepath", "string")
  if not filepath or not lfs.getInfo(filepath) then return end

  if mount.http then
    http.removeMethod("GET", mount.http)
    mount.http = nil
  end
  if mount.data then
    lfs.unmount(mount.data)
    mount.data = nil
    mount.location = nil
  end

  mount.location = love.mintmousse.ZIP_MOUNT_LOCATION .. "favicon/"
  mount.http = love.mintmousse.FAVICON_PATH .. "/*filepath"

  http.addMethod("GET", mount.http, function(request, _)
    local file = request.params["filepath"]
    if not file then return 400, nil, nil end

    local fullPath = mount.location .. file
    if not lfs.getInfo(fullPath, "file") then return 404, nil, nil end

    local contents, errorMessage = lfs.read(fullPath)
    if not contents then return 404, nil, nil end

    local ext = file:match("%.(%w+)$") or ""
    local ct = getContentType(file)

    return 200, {
      ["cache-control"] = love.mintmousse.CACHE_CONTROL_HEADER,
      ["content-type"] = ct,
    }, contents
  end)

  local errorMessage
  mount.data, errorMessage = lfs.read("data", filepath)
  if not mount.data then
    loggerIcon:warning("Could not read RFG ZIP to mount:", filepath, ". Reason:", errorMessage)
    return
  end

  local success = lfs.mount(mount.data, mount.location, true)
  if success then
    loggerIcon:info("Successfully mounted RFG favicons! Mounted:", filepath, "to", mount.location)
  else
    loggerIcon:warning("Failed to mount RFG ZIP:", filepath)
  end

  -- Cheat to read the file than add more validation 
  local template = readTemplate(dir .. "icon/RFG.html")
  store.setIconHTML(template)
end)

signal.on("quit", function(_)
  if mount.http then
    http.removeMethod("GET", mount.http)
    mount.http = nil
  end
  if mount.data then
    lfs.unmount(mount.data)
    mount.data = nil
  end
end)