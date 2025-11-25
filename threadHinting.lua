local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")
local loggingStack = require(PATH .. "logging.stack")
local codec = require(PATH .. "codec")

local hintingLogger = mintmousse._logger:extend("Hinting")

local threadHinting = { }

local COMPONENT_UPDATES_QUEUE = love.thread.getChannel(mintmousse.THREAD_COMMAND_QUEUE_ID:format(mintmousse._threadID))
threadHinting.poll = function()
  loggingStack.push()
  local package = COMPONENT_UPDATES_QUEUE:pop()
  while package do
    package = codec.decode(package)
    if package.type == "latestChildren" then
      local parentID = package.id
      local childrenIDs = package.children -- Array of IDs e.g. { "foo", "bar" }

      local parentProxy = mintmousse._proxyComponents[parentID]
      if parentProxy then
        local childrenProxy = parentProxy.children
        local rawChildren = rawget(childrenProxy, "__raw")#

        for i, childID in ipairs(childrenIDs) do
          local childProxy = mintmousse._proxyComponents[childID]
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
    else
      hintingLogger:warning("Unhandled MintMousse hinting event!", package.type)
    end
    package = COMPONENT_UPDATES_QUEUE:pop()
  end
  loggingStack.pop()
end

return threadHinting