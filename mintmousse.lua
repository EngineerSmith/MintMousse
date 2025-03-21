if love.isThread == nil then
  love.isThread = arg == nil
end

if not jit then
  error("Library MintMousse requires lua jit; this is usually packaged with love.")
end
local success = pcall(require, "string.buffer")
if not success then
  error("Library MintMousse requires lua jit with string buffer; update your love version.")
end

-- love.data, love.filesystem, & love.thread is preloaded for threads, other modules must be loaded
require("love.event")
require("love.timer")
require("love.math") -- todo check if can be removed

local createBuffer = function()
  local bufferMetatable = { }

  local channelDictionary = love.thread.getChannel(love.mintmousse.READONLY_BUFFER_DICTIONARY_ID)
  if not channelDictionary:peek() then
    local dictionary, lookup = {
      "id",
      "type",
      "func",
      "quit",
      "start",
      "style",
      "update",
      "latest",
      "typeMap",
      "children",
      "mintmousse"
      "relationships",
    }, { }
    for _, word in ipairs(dictionary) do
      lookup[word] = true
    end
    -- !!todo!! Add commonly found strings to push into dictionary

    channelDictionary:push(dictionary)
  end

  local buffer = require("string.buffer").new({
    dict = channelDictionary:peek(),
    metatable = bufferMetatable,
  })

  return buffer
end

return function(path, directoryPath)
  if love.mintmousse then
    local err = type(love.mintmousse) == "table" and love.mintmousse.error or error
    return err("mintmousse/mintmousse.lua has already been ran, or there is a conflict in namespace with love.mintmousse")
  end
  
  love.mintmousse = {
    path = path,
    directoryPath = directoryPath,
    -- Do not change these at run time they won't affect threads! Change the file
    MAX_DATA_RECEIVE_SIZE = 50000, -- Maximum body byte limit of incoming HTTP requests 

    -- Thread Communication
    THREAD_COMMAND_QUEUE_ID = "MintMousse", -- id for a love.thread Channel
    THREAD_RESPONSE_QUEUE_ID = "MintMousse", -- id for the love.event handler
    READONLY_BUFFER_DICTIONARY_ID = "MintMousseDictionary", -- id for a love.thread Channel
    THREAD_COMPONENT_UPDATES_ID = "MintMousseUpdate_%s", -- id for love.thread Channel (appended with threadID)

    -- Internal use
    hinting = {
      -- Hinting data received from the main MintMousse thread
      typeMap = { },
      relationships = { },
      -- Hinting locally generated from components created by this thread
      localTypeMap = { },
      localRelationships = { },
    },
  }

  -- todo; we should make it so any thread can start the MM thread if it isn't running
  --         ownership could be a channel; accepts love object thread
  if not love.isThread then
    -- Start MintMousse's thread
    love.mintmousse.thread = love.thread.newThread(love.mintmousse.directoryPath .. "thread/init.lua")
    love.mintmousse.thread:start(love.mintmousse.path, love.mintmousse.directoryPath)
  end

  local buffer = createBuffer()
  love.mintmousse._encode = function(message)
    return buffer:reset():encode(message):get()
  end

  love.mintmousse._decode = function(encodedMessage)
    return buffer:set(encodedMessage):decode()
  end

  local COMMAND_QUEUE = love.thread.getChannel(love.mintmousse.THREAD_COMMAND_QUEUE_ID)
  love.mintmousse.push = function(message)
    COMMAND_QUEUE:push(love.mintmousse._encode(message))
  end

  if love.isMintMousseServerThread then
    -- only the mintmousse thread should pop the command queue!
    love.mintmousse.pop() = function()
      local encodedMessage = COMMAND_QUEUE:pop()
      if not encodedMessage then
        return nil
      end
      return love.mintmousse._decode(encodedMessage)
    end
    
    love.mintmousse.threadID = "MintMousse"
  end

  local threadIDLength = 11
  if not love.isMintMousseServerThread then
    --todo match AppleCake; recently checked AppleCake, it just numbers threads based on order of initialisation
    love.mintmousse.threadID = ("x"):rep(threadIDLength):gsub("[x]", function(_) return ("%x"):format(love.math.random(0, 15)) end)
  end

  love.mintmousse.require = function(file)
    return require(love.mintmousse.path .. file)
  end

  if not love.isThread then -- main thread
    love.handlers[love.mintmousse.THREAD_RESPONSE_QUEUE_ID] = function(enum, ...)
      --todo; should all events go back to the main thread now that MM supports multithreaded calls?
      error("TODO")
    end

    love.mintmousse.start = function()
      error("TODO")
    end

    love.mintmousse.stop = function()
      love.mintmousse.push({
        func = "quit"
      })
    end

    love.mintmousse.stopNow = function()
      COMMAND_QUEUE:performAtomic(function()
        COMMAND_QUEUE:clear()
        love.mintmousse.stop()
      end)
    end
  else
    love.mintmousse.pushEvent = function(enum, ...)
      love.event.push(love.mintmousse.THREAD_RESPONSE_QUEUE_ID, enum, ...)
    end
  end

  love.mintmousse.require("logging")

  local _idCounter = 0
  love.mintmousse.generateID = function()
    local id = love.mintmousse.threadID .. (_idCounter >= 100 and "_"..string.char(threadIDLength*7, threadIDLength*7, threadIDLength*6-1, 99, 101).."_%x" or "_%x"):format(_idCounter)
    _idCounter = _idCounter + 1
    return id
  end

  love.mintmousse.isValidID = function(id)
    if type(id) ~= "string" then
      return false, "ID isn't type string"
    end
    local failed = id:match("[^%w%._,:;@]")
    if failed then
      return false, "ID Can only contain alphanumeric or . _ , : ; @ characters. Failed character:" tostring(failed)
    end
    if id:find("^%d") then
      return false, "ID cannot use a numeric as the first character of an id"
    end
    if id == "all" then
      return false, "ID cannot use the protected keyword 'all'"
    end
    return true, nil
  end

  love.mintmousse.updateSubscription = function(target)
    if target ~= "all" and target ~= "none" then
      local isValid, errorMessage = love.mintmousse.isValidID(target)
      if not isValid then
        love.mintmousse.warning("Could not update subscription for thread. Gave invalid target assumed to be an ID:", errorMessage)
        return
      end
    end
    love.mintmousse.push({
      func = "updateSubscription",
      love.mintmousse.threadID, target
    })
    -- todo should this function clear local hinting?
  end

  local COMPONENT_UPDATES_QUEUE = love.thread.getChannel(love.mintmousse.THREAD_COMPONENT_UPDATES_ID:format(love.mintmousse.threadID))
  love.mintmousse.processSubscription = function()
    local package = COMPONENT_UPDATES_QUEUE:pop()
    if not package then
      return
    end
    package = love.mintmousse._decode(package)
    if package.type == "latest" then
      love.mintmousse.hinting.typeMap = package.typeMap
      love.mintmousse.hinting.relationships = package.relationships

      -- Remove acknowledged type hints
      for id in pairs(love.mintmousse.hinting.localTypeMap) do
        if love.mintmousse.hinting.typeMap[id] then
          love.mintmousse.hinting.localTypeMap[id] = nil
        end
      end

      -- Remove acknowledged relationship hints
      -- pairs are used as local relationships may not be an unbroken indexed table
      for id, relationships in pairs(love.mintmousse.hinting.localRelationships) do
        for index in pairs(relationships) do
          if love.mintmousse.hinting.relationships[id][index] then
            love.mintmousse.hinting.localRelationships[id][index] = nil
          end
        end
        local hasIndex = false
        for _ in pairs(love.mintmousse.hinting.localRelationships[id]) do
          hasIndex = true
          break
        end
        if not hasIndex then
          love.mintmousse.hinting.localRelationships[id] = nil
        end
      end
    else
      love.mintmousse.error("TODO other package types", package.type)
      return
    end
  end

--   local TREE_VERSION_CHANNEL = love.thread.getChannel(love.mintmousse.COMPONENT_TREE_VERSION_ID)
--   local TREE_DATA_CHANNEL = love.thread.getChannel(love.mintmousse.COMPONENT_TREE_DATA_ID)

--   local lastVersion = nil
--   love.mintmousse.updateTree = function()
--     local treeVersion = TREE_VERSION_CHANNEL:peek()
--     if lastVerson ~= treeVersion then
--       lastVersion = treeVersion
--       local tree = love.mintmousse._decode(TREE_DATA_CHANNEL:peek())


--     end
--   end

--   love.mintmousse.isID = function(id)
--     love.mintmousse.updateTree()
--   end

-- -- Front facing commands
--   love.mintmousse.get = function(id)
--     if not love.mintmousse.isID(id) then
--       return error("TODO: component isn't an existing component? OR 'hope it exists'")
--     end
--     -- todo
--   end

--   love.mintmousse.newTab = function(title, id, index)
--     local id = id or title
--     if love.mintmousse.isID(id) then
--       love.mintmousse.warning("Tried to create Tab with id that already exists")
--       return nil
--     end
--     love.mintmousse.push({
--       func = "newTab",
--       id, title, index
--     })
--     return love.mintmousse.get(id)
--   end
end