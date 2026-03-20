local PATH = (...):match("^(.*)icon$")
local ROOT = PATH:match("^(.-)thread%.controller%.$")
local ROOT_DIR = ROOT:gsub("%.", "/")

local mintmousse = require(ROOT .. "conf")
local lustache = require(ROOT .. "libs.lustache")
local json = require(ROOT .. "libs.json")

local state = require(PATH .. "state")

local loggerIcon = require(PATH .. "logger"):extend("Icon")

local icon = { }

icon.setIconRaw = function(icon, iconType)
  local iconTemplate = love.filesystem.read(ROOT_DIR .. "icon/icon.mustache")
  state.icon = lustache:render(iconTemplate, {
    icon = "data:" .. iconType .. ";base64," .. love.data.encode("string", "base64", icon),
    iconType = iconType,
  })
  state.isDirty = true
end

icon.setSVGIcon = function(icon)
  local svgTemplate = love.filesystem.read(ROOT_DIR .. "icon/template.svg.mustache")
  local render = lustache:render(svgTemplate, icon)
  icon.setIconRaw(render, "image/svg+xml")
end

local SIFLogger = loggerIcon:extend("setIconFromFile", "bright_black")
icon.setIconFromFile = function(filepath)
  if not love.filesystem.getInfo(filepath, "file") then
    SIFLogger:warning("Couldn't locate given filepath (or wasn't a file). Gave:", filepath)
    return
  end

  local rawIcon = love.filesystem.read(filepath)
  local temp = filepath:lower()
  local iconType
  if temp:match("%.png$") then
    iconType = "image/png"
  elseif temp:match("%.jpeg$") or temp:match("%.jpg$") then
    iconType = "image/jpeg"
  elseif temp:match("%.svg$")
    iconType = "image/svg+xml"
  end
  if not iconType then
    SIFLogger:warning("Couldn't determine MIME type. File:", filepath)
    return
  end
  icon.setIconRaw(rawIcon, iconType)
end


local RFGLogger = loggerIcon:extend("setIconRFG", "bright_black")
icon.setIconRFG = function(filepath)
  local success = love.filesystem.mount(filepath, mintmousse.TEMP_MOUNT_LOCATION, true)
  if not success then
    RFGLogger:warning("Couldn't mount given RFG zip to temporary location. Location:", mintmousse.TEMP_MOUNT_LOCATION)
    return
  end

  local readAndEncode = function(path)
    local file = love.filesystem.read(mintmousse.TEMP_MOUNT_LOCATION .. path)
    return love.data.encode("string", "base64", file)
  end

  local RFG = {
    favicon96x96PNG   = "data:image/png;base64,"     .. readAndEncode("favicon-96x96.png"),
    faviconSVG        = "data:image/svg+xml;base64," .. readAndEncode("favicon.svg"),
    faviconICO        = "data:image/x-icon;base64,"  .. readAndEncode("favicon.ico"),
    faviconAppleTouch = "data:image/png;base64,"     .. readAndEncode("apple-touch-icon.png"),
  }

  local webmanifestJson = love.filesystem.read(mintmousse.TEMP_MOUNT_LOCATION .. "site.webmanifest")
  local manifest = json.decode(webmanifest)

  for _, icon in ipairs(manifest.icons) do
    local raw = love.filesystem.read(mintmousse.TEMP_MOUNT_LOCATION .. icon.src:sub(2))
    icon.src = "data:" .. icon.type .. ";base64," .. love.data.encode("string", "base64", raw)
  end

  RFG.webmanifest = "data:application/json;base64," .. love.data.encode("string", "base64", json.encode(manifest))

  local RFGTemplate = love.filesystem.read(ROOT_DIR .. "icon/RFG.mustache")
  state.icon = lustache:render(RFGTemplate, RFG)
  state.isDirty = true

  love.filesystem.unmount(filepath)
end

return icon