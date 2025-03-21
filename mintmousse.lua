if love.isThread == nil then
  love.isThread = arg == nil
end

return function(path, directoryPath)
  if love.mintmousse then
    return love.mintmousse.error("mintmousse/mintmousse.lua has already been ran, or there is a conflict in namespace with love.mintmousse")
  end

  love.mintmousse = {
    path = path,
    directoryPath = directoryPath,
-- Do not change these at run time they won't affect the thread! Change the file
    MAX_DATA_RECEIVE_SIZE = 50000, -- Maximum body character limit of incoming HTTP requests
      -- Thread Communication
    THREAD_COMMAND_QUEUE_ID = "MintMousse", -- id for a thread Channel
    THREAD_RESPONSE_QUEUE_ID = "MintMousse", -- id for the Event handler
    READONLY_BUFFER_DICTIONARY_ID = "MintMousseDictionary", -- id for a thread Channel
      -- logging
    loggingTimestampEnable = true, -- if timestamp should be appended to log messages
    loggingTimestampFormat = "%Y-%m-%d %H:%M:%S", -- os.date format
    loggingEnable = true, -- if any logging function calls global 'print' function
    errorEnable = true, -- if love.mintmousse.error calls global 'error' function
    loggingSinks = { },
  }

  love.mintmousse.require = function(file)
    return require(love.mintmousse.path .. file)
  end

  if love.isThread then
    love.mintmousse.pushEvent = function(enum, ...)
      love.event.push(love.mintmousse.THREAD_RESPONSE_QUEUE_ID, enum, ...)
    end

    print = function(...)
      love.mintmousse.pushEvent("print", ...)
    end
  elseif not love.isThread then
    love.handlers[love.mintmousse.THREAD_RESPONSE_QUEUE_ID] = function(enum, ...)
      if enum == "print" then
        print(select(1, ...))
      else
        -- todo remove
        print(...)
      end
    end
  end

  -- Cross-thread communication
  local buffer
  local bufferMetatable = { }

  local channelDictionary = love.thread.getChannel(love.mintmousse.READONLY_BUFFER_DICTIONARY_ID)
  if not channelDictionary:peek() then
    local dictionary, lookup = {
      "id",
      "type",
      "func",
      "quit",
      "children",
    }, { }
    for _, word in ipairs(dictionary) do
      lookup[word] = true
    end

      -- Add commonly found strings to push into dictionary
    -- !!todo!!

    channelDictionary:push(dictionary)

    buffer = require("string.buffer").new({
      dict = dictionary,
      metatable = bufferMetatable,
    })
  else
    buffer = require("string.buffer").new({
      dict = channelDictionary:peek(),
      metatable = bufferMetatable,
    })
  end
  channelDictionary, bufferMetatable = nil, nil

  local COMMAND_QUEUE = love.thread.getChannel(love.mintmousse.THREAD_COMMAND_QUEUE_ID)
  love.mintmousse.push = function(message)
    local encodedMessage = buffer:reset():encode(message):get()
    COMMAND_QUEUE:push(encodedMessage)
  end

  love.mintmousse.pop = function()
    local encodedMessage = COMMAND_QUEUE:pop()
    if not encodedMessage then
      return nil
    end
    return buffer:set(encodedMessage):decode()
  end

  love.mintmousse.stop = function()
    love.mintmousse.push({func = "quit"})
  end

  love.mintmousse.stopNow = function()
    COMMAND_QUEUE:performAtomic(function()
      COMMAND_QUEUE:clear()
      love.mintmousse.stop()
    end)
  end
end