local lfs = love.filesystem

local lustache = require(PATH .. "libs.lustache")

local signal = require(PATH .. "thread.signal")

return function(store, logger)
  loggerMeta = logger:extend("Meta")

  local readTemplate = function(path)
    local content, errorMessage = lfs.read(path)
    if type(content) ~= "string" then
      loggerMeta:error("Failed to read template", path, ". Reason:", errorMessage or "UNKNOWN")
      return ""
    end
    return content
  end

  local M = { }

  M.setTitle = function(title)
    store.meta.title = title or ""
    store.meta.dirty = true
    signal.emit("broadcast", { action = "setTitle", title = title })
  end

  M.setIconHTML = function(icon)
    store.meta.icon = icon
    store.meta.dirty = true
  end

  M.renderHTML = function()
    local template = readTemplate(love.mintmousse.DEFAULT_INDEX_HTML)
    store.resources.html = lustache:render(template, store.meta)
    store.meta.dirty = false
  end

  M.getHTML = function()
    if store.meta.dirty then M.renderHTML() end
    return store.resources.html
  end

  M.renderJavascript = function(scripts)
    local template = readTemplate(love.mintmousse.DEFAULT_INDEX_JS)
    store.resources.javascript = lustache:render(template, { components = scripts })
  end

  M.getJavascript = function()
    return store.resources.javascript
  end

  M.renderCSS = function(styles)
    local template = readTemplate(love.mintmousse.DEFAULT_INDEX_CSS)
    store.resources.css = lustache:render(template, { components = styles })
  end

  M.getCSS = function()
    return store.resources.css
  end

  return M
end