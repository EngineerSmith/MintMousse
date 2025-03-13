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
-- Do not change these at run time they won't affect the thread!
    MAX_DATA_RECEIVE_SIZE = 50000,
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

  -- Logging
  local prefix = "MintMousse" .. (love.isThread and " Thread" or "") .. ": "
  local logPrefix = {
    info  = prefix .. "info:",
    warn  = prefix .. "warn:",
    error = prefix .. "error:",
  }
  prefix = nil
  local assertingDepthOffset = 0
  
  local getTimestamp = function()
    return os.date(love.mintmousse.loggingTimestampFormat)
  end

  local createLogMessage = function(logLevel, ...)
    local message
    if love.mintmousse.loggingTimestampEnable then
      message = { getTimestamp(), logPrefix[logLevel], ... }
    else
      message = { logPrefix[logLevel], ... }
    end
    return table.concat(message, " ")
  end

  local dispatchToSinks = function(logLevel, message)
    for _, sink in ipairs(love.mintmousse.loggingSinks) do
      sink(logLevel, message)
    end
  end

  -- Sink must be a function which 1st argument is the log level['info', 'warn', 'error'], and 2nd argument is the message
  love.mintmousse.addLogSink = function(sink)
    assert(type(sink) == "function", "1st argument was not type function")
    table.insert(love.mintmousse.loggingSinks, sink)
  end

  love.mintmousse.info = function(...)
    if #love.mintmousse.loggingSinks == 0 and not love.mintmousse.loggingEnable then
      return
    end

    local message = createLogMessage("info", ...)

    if love.mintmousse.loggingEnable then
      print(message)
    end
    dispatchToSinks("info", message)
  end

  love.mintmousse.warning = function(...)
    if #love.mintmousse.loggingSinks == 0 and not love.mintmousse.loggingEnable then
      return
    end

    local message = createLogMessage("warn", ...)

    if love.mintmousse.loggingEnable then
      print(message)
    end
    dispatchToSinks("warn", message)
  end

  love.mintmousse.error = function(...)
    if #love.mintmousse.loggingSinks == 0 and not love.mintmousse.loggingEnable and not love.mintmousse.errorEnable then
      return
    end

    local debugInfo
    if type(debug) == "table" and type(debug.getinfo) == "function" then
      local info = debug.getinfo(2 + assertingDepthOffset, "fnS")
      if info then
        local name = info.name and info.name or info.func and tostring(info.func):gsub("function: ", "") or "UNKNOWN"
        if info.short_src then
          name = name .. "@" .. info.short_src .. (info.linedefined and "#" .. info.linedefined or "")
        end
        debugInfo = name .. ": "
      end
    end

    local message = debugInfo and createLogMessage("error", debugInfo, ...) or createLogMessage("error", ...)

    if love.mintmousse.loggingEnable then
      print(message)
    end
    dispatchToSinks("error", message)
    if love.mintmousse.errorEnable then
      error(message)
    end
  end

  love.mintmousse.assert = function(condition, ...)
    if not condition then
      assertingDepthOffset = 1
      love.mintmousse.error(...)
      assertingDepthOffset = 0
    end
  end

end