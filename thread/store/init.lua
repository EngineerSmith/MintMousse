local signal = require(PATH .. "thread.signal")

local loggerStore = love.mintmousse._logger:extend("Store")

local store = {
  root = { },
  idLookUp = { },
  meta = { dirty = false, title = "", icon = nil },
  resources = { html = "", javascript = "", css = "" },
  componentTypes = nil,
}

local metaModule = require(PATH .. "thread.store.meta")(store, loggerStore)
local treeModule = require(PATH .. "thread.store.tree")(store, loggerStore)

for k, v in pairs(metaModule) do
  store[k] = v
end
for k, v in pairs(treeModule) do
  store[k] = v
end

store.registerComponentTypes = function(types, scripts, styles)
  store.componentTypes = types or { }
  if not store.componentTypes["Tab"] then
    store.componentTypes["Tab"] = {
      updates = { title = true },
      childUpdates = { },
      hasCreateFunction = true,
      hasInsertFunction = true,
    }
  end

  if scripts then
    store.renderJavascript(scripts)
  end
  if styles then
    store.renderCSS(styles)
  end
end

signal.on("init", function()
  store.renderHTML()
end)

return store