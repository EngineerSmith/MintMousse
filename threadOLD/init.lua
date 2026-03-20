local ROOT = ...

isMintMousseThread = true
local mintmousse = require(ROOT:sub(1, -2))
local threadCommand = require(ROOT .. "threadCommand")

local json = require(ROOT .. "libs.json")

local components = require(ROOT .. "thread.components")
components.init()

local http = require(ROOT .. "thread.http")
local server = nil -- deferred require until server needs to start
local controller = require(ROOT .. "thread.controller")
local websocket13 = require(ROOT .. "thread.websocket13")
local whitelist = require(ROOT .. "thread.server.whitelist")

require(ROOT .. "thread.routes")

-- Set defaults
controller.setTitle("MintMousse")
controller.setSVGIcon({
  emoji = "🍮",
  rect = true,
  rounded = true,
  insideColor = "#95d7ab",
  outsideColor = "#00FF07",
  easterEgg = true,
})

local callbacks = { }

callbacks.newTab = controller.newTab
callbacks.setTitle = controller.setTitle
callbacks.setSVGIcon = controller.setSVGIcon
callbacks.setIconRaw = controller.setIconRaw
callbacks.setIconRFG = controller.setIconRFG
callbacks.setIconFromFile = controller.setIconFromFile
callbacks.updateSubscription = controller.updateThreadSubscription

callbacks.addComponent = controller.addComponent
callbacks.updateComponent = controller.updateComponent
callbacks.updateParentComponent = controller.updateParentComponent
callbacks.removeComponent = controller.removeComponent

callbacks.notify = controller.notifyToast

callbacks.start = function(config)
  if not server then
    server = require(ROOT .. "thread.server")
    local loggerWebsocket = mintmousse._logger:extend("WebSocket")
    server.handleIncomingEvent = function(request)
      if request.type == "text/utf8" or request.type == "application/json" then
        -- attempt json convert & handle
        local success, payload = pcall(json.decode, request.payload)
        if not success then
          loggerWebsocket:warning("Couldn't decode incoming event request via json. Got error: ", payload)
          return
        end

        local component
        if type(payload.id) == "string" and payload.id ~= "" then
          local _
          _, _, component = controller.splitWebsiteID(payload.id)
        end

        if type(payload.event) == "string" and payload.event ~= "" then
          if not component then
            loggerWebsocket:warning("Incoming event didn't include valid component ID.")
            return
          end
          local componentType = controller.getType(component.type)
          local event = payload.event:lower()
          if not event or not componentType.events[event] then
            loggerWebsocket:warning("Incoming event didn't include valid event type["..event.."] for component: ", component.type)
            return
          end

          -- Find component's callback field
          local componentEvent = event:sub(1,1):upper() .. event:sub(2)
          componentEvent = mintmousse.COMPONENT_EVENT_FIELD:format(componentEvent)
          local callbackID = component[componentEvent]

          if not callbackID then
            -- love.mintmousse.info("WS: Incoming event component doesn't have event callback for", componentEvent)
            return
          end

          -- Dispatch event to main thread to handle callback
          threadCommand.pushEvent("MintMousseJSEvent", component.id, callbackID)
          return
        end

        loggerWebsocket:warning("Unhandled incoming server event. Successfully converted from json, but wasn't used.")
        return
      end
      loggerWebsocket:warning("Unhandled incoming server event! Type:", request.type)
    end
  end
  if config then
    if type(config.title) == "string" then
      callbacks.setTitle(config.title)
    end
    if type(config.whitelist) == "table" then
      for _, rule in ipairs(config.whitelist) do
        whitelist.add(rule)
      end
    elseif type(config.whitelist) == "string" then
      whitelist.add(config.whitelist)
    end
  end

  server.start(config and config.host, config and config.httpPort)
end

http.addMethod("GET", "/index", function(request)
  return 200, {
    ["cache-control"] = mintmousse.CACHE_CONTROL_HEADER,
    ["content-type"] = "text/html; charset=utf8",
  }, controller.getIndex()
end)

http.addMethod("GET", "/index.js", function(request)
  return 200, {
    ["cache-control"] = mintmousse.CACHE_CONTROL_HEADER,
    ["content-type"] = "text/javascript; charset=utf8",
  }, controller.javascript
end)

http.addMethod("GET", "/index.css", function(request)
  return 200, {
    ["cache-control"] = mintmousse.CACHE_CONTROL_HEADER,
    ["content-type"] = "text/css; charset=utf8",
  }, controller.css
end)

-- Callback; todo rename onNewConnection
websocket13.newConnection = function(client)
  local array = controller.getInitialPayload()
  table.insert(client.queue, {
    type = "text/utf8",
    payload = array,
  })
end

-- Callback; todo rename - called when webpage has an update to push
controller.update = function(jsonPayload)
  if not server or not server.isRunning() then
    return
  end
  local payload = {
    type = "text/utf8",
    payload = "["..jsonPayload.."]",
  }
  for client in pairs(server.clients) do
    if client.connection.type == "WS/13" then
      table.insert(client.queue, payload)
    end
  end
end

while true do
  for _ = 1, 50 do
    local message = love.mintmousse.pop()
    if type(message) ~= "table" then
      break
    end
    if message.func == "quit" then
      if server then
        server.cleanUp()
      end
      return
    end
    if type(message.func) == "string" then
      local func = callbacks[message.func]
      if type(func) == "function" then
        local success, errorMessage = pcall(func, unpack(message))
        if not success then
          mintmousse._logger:warning("Failed to process message:", message.func, ". Error:", errorMessage)
        end
      else
        mintmousse._logger:warning("Could not find callback for:", message.func)
      end
    end
  end
  if server and server.isRunning() then
    server.newIncomingConnection()
    server.updateConnections()
  end
  love.timer.sleep(0.0001)
end