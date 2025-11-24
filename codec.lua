local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")

local getDictionary = function()
  return {
    "id",
    "type",
    "func",
    "quit",
    "size",
    "text",
    "start",
    "style",
    "color",
    "update",
    "latest",
    "parent",
    "newTab",
    "creator",
    "setTitle",
    "children",
    "parentID",
    "setSVGIcon",
    "setIconRaw",
    "setIconRFG",
    "mintmousse",
    "onEventClick",
    "addComponent",
    "componentAdded",
    "updateComponent",
    "removeComponent",
    "setIconFromFile",
    "componentRemoved",
    "updateSubscription",
  }
end

local createBuffer = function()
  local bufferMetatable = { }

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
    metatable = bufferMetatable,
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