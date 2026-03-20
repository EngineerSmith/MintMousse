local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")

local getDictionary = function()
  return {
  -- Protocol & Structure
  "id", "func", "args", "mintmousse", "batch",

  -- Commands
  "addComponent", "newTab", "removeComponent", -- componentManager
  "updateComponent", "reorderChildren", "moveChild", -- proxyTable
  "start", "quit", "setSVGIcon", "setIconRaw", "setIconRFG", "setTitle", "notify", -- threadController

  -- Component/UI Keys
  "type", "parentID", "children",
  "color", "size", "text", "title", "icon", "config",

  -- State & Lifecycle
  "update", -- is this needed?

-- old
    --"id",
    --"type",
    --"func",
    --"quit",
    --"size",
    --text",
    --"start",
    -- "style",
    --"color",
    --"update",
    -- "latest",
    "parent",
    --"newTab",
    --"setTitle",
    --"children",
    --"parentID",
    --"setSVGIcon",
    --"setIconRaw",
    --"setIconRFG",
    --"mintmousse",
    -- "onEventClick",
    --"addComponent",
    -- "componentAdded",
    --"updateComponent",
    --"removeComponent",
    "setIconFromFile",
    "componentRemoved",
    -- "updateSubscription",
  }
end

local createBuffer = function()
  local channelDictionary = love.thread.getChannel(mintmousse.READONLY_BUFFER_DICTIONARY_ID)

  if not channelDictionary:peek() then
    local dictionary, lookup = getDictionary(), { }
    for index, word in ipairs(dictionary) do
      assert(not lookup[word], "You've duplicated a word in the list! " .. index .. " index was already added")
      lookup[word] = true
    end

    channelDictionary:push(dictionary)
  end

  local buffer = require("string.buffer").new({
    dict = channelDictionary:peek(),
  })

  return buffer
end

local codec = { }

local buffer = createBuffer()
codec.encode = function(message)
  return buffer:reset():encode(message):get()
end

codec.decode = function(encodedMessage)
  return buffer:set(encodedMessage):decode()
end

return codec