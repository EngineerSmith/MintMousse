local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")
local componentManager = require(PATH .. "componentManager")
local codec = require(PATH .. "codec")

local loggerSync = mintmousse._logger:extend("Poll")

local syncPoll = { }

local COMPONENT_UPDATES_QUEUE = love.thread.getChannel(mintmousse.THREAD_COMMAND_QUEUE_ID:format(mintmousse._threadID))
syncPoll.poll = function()
  local package = COMPONENT_UPDATES_QUEUE:pop()
  while package do
    package = codec.decode(package)
    if package.type == "latestChildren" then
      local parentID = package.id
      local childrenIDs = package.children -- Array of IDs e.g. { "foo", "bar" }

      local parentProxy = componentManager.proxyComponents[parentID]
      if parentProxy then
        local childrenProxy = parentProxy.children
        local rawChildren = rawget(childrenProxy, "__raw")

        for i, childID in ipairs(childrenIDs) do
          local childProxy = componentManager.proxyComponents[childID]
          if childProxy then
            rawChildren[i] = childProxy
          else
            rawChildren[i] = childID
          end
        end

        -- Trim children
        for i = #childrenIDs + 1, #rawChildren do
          rawChildren[i] = nil
        end

      end
    elseif package.type == "componentRemoved" then
      local componentID = package.id
      proxyComponents.cleanupProxy(componentID)
    else
      loggerSync:warning("Unhandled MintMousse hinting event!", package.type)
    end
    package = COMPONENT_UPDATES_QUEUE:pop()
  end
end

return syncPoll