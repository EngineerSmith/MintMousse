local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")

local getDictionary = function()
  -- These don't need to be perfect, but a rough idea is good enough
  local words = {
    "mintmousse",

    -- Commands
    "func", "args", "batch",
      -- Proxy commands, and their arguments
    "updateComponent", "id", "index", "value",
    "removeComponent", "id",
    "setChildrenOrder", "id", "newOrder",
    "moveBefore", "id", "siblingID",
    "moveAfter", "id", "siblingID",
    "moveToFront", "id",
    "moveToBack", "id",
    "addComponent", "component",
    "newTab", "id", "title", "index",

      -- ThreadController commands, and their arguments
    "start", "config",
    "quit",
    "addToWhitelist", "additions",
    "removeFromWhitelist", "removals",
    "clearWhitelist",
    "setSchemaIcon", "icon",
    "setIconFromFile", "filepath",
    "setIconRaw", "icon", "iconType",
    "setIconRFG", "filepath",
    "setTitle", "title",
    "notify", "message", "title", "text",

    -- Common Component/UI Keys
    "title", -- accordion
    "text", "color", "isDismissible", -- alert
    "color", "colorOutline", "text", "isDisabled", "width", "isCentered", "click", -- button
    "color", "isContentCenter", "borderColor", "title", "text", -- card
    "text", "isTransparent", -- cardFooter
    "text", "isTransparent", -- cardHeader
    "text", -- cardSubtitle,
    "text", -- cardText
    "text", -- cardTitle
    "isNumbered", -- list
    "percentage", "showLabel", "ariaLabel", "isStriped", "color", -- progressBar
    "columnWidth", -- row
    "percentage", -- stackedProgressBar,
    "title", "size", -- tab,
    "text", -- text
  }

  local proxy = require(PATH .. "proxy")
  for _, word in ipairs(proxy.getProtectedKeys()) do -- order isn't guaranteed
    table.insert(words, word)
  end

  -- Remove repeating
  local dictionary, lookup = { }, { }
  for index, word in ipairs(words) do
    if not lookup[word] then
      lookup[word] = true
      table.insert(dictionary, word)
    end
  end

  return dictionary
end

local createBuffer = function()
  local channelDictionary = love.thread.getChannel(mintmousse.READONLY_BUFFER_DICTIONARY_ID)

  channelDictionary:performAtomic(function()
    if not channelDictionary:peek() then
      local dictionary = getDictionary()
      channelDictionary:push(dictionary)
    end
  end)
  local dictionary = channelDictionary:peek()

  local buffer = require("string.buffer").new({
    dict = dictionary,
  })

  return buffer
end

local codec = { }

local bufferEnc
codec.encode = function(message)
  if not bufferEnc then bufferEnc = createBuffer() end
  return bufferEnc:reset():encode(message):get()
end

local bufferDec
codec.decode = function(encodedMessage)
  if not bufferDec then bufferDec = createBuffer() end
  return bufferDec:set(encodedMessage):decode()
end

return codec