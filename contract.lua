local PATH = (...):match("^(.-)[^%.]+$")

local mintmousse = require(PATH .. "conf")
local codec = require(PATH .. "codec")

local loggerContract = mintmousse._logger:extend("Contract")

local contract = { }

local componentTypesChannel = love.thread.getChannel(mintmousse.READONLY_BASIC_TYPES_ID)
local timeoutValue = mintmousse.COMPONENT_PARSE_TIMEOUT
contract.waitForComponents = function()
  contract.componentTypes = componentTypesChannel:peek()
  if contract.componentTypes ~= nil then
    -- Components are already loaded and ready to go
    if not love.isThread then -- is Main thread
      loggerContract:info("MintMousse components successfully loaded")
    end
    return
  end

  local thread = love.thread.getChannel(mintmousse.READONLY_THREAD_LOCATION):peek()
  loggerContract:assert(thread, "MintMousse Thread object is unexpectedly missing.")

  loggerContract:info("Blocking thread to wait for MintMousse component load.")
  local timeout = false

  local start = love.timer.getTime()
  while thread:isRunning() do
    contract.componentTypes = componentTypesChannel:peek()
    if contract.componentTypes ~= nil then
      break
    end

    if love.timer.getTime() - start >= timeoutValue then
      timeout = true
      break
    end

    love.timer.sleep(5e-4)
  end
  local timeElapsed = love.timer.getTime() - start

  if contract.componentTypes ~= nil then
    contract.componentTypes = codec.decode(contract.componentTypes)

    loggerContract:info("MintMousse components successfully loaded",
      ("(blocked main thread for %.2fms)."):format(timeElapsed*1000))
    return
  end

  if timeout then
    loggerContract:warning("Timeout reached ("..timeoutValue.."s) while waiting for MintMousse Thread to load components.",
      "Consider increasing the timeout ("..timeoutValue.."s).")
  end

  if not thread:isRunning() then
    loggerContract:warning("Thread isn't running while waiting for componentTypes. Checking for errors.")
    local errorMessage = thread:getError()
    if errorMessage then
      if type(love.handlers) == "table" and love.handlers["threaderror"] then
        -- love.handlers shouldn't be initialised yet; but check anyway
        pcall(love.handlers["threaderror"], thread, errorMessage)
      elseif love.event then -- fallback
        love.event.push("threaderrror", thread, errorMessage)
      end
      loggerContract:error("MintMousse's thread encountered an error:", errorMessage)
    else
      loggerContract:warning("The thread object reported no error.",
        "This suggests the MintMousse Thread is stuck or overloaded.",
        "Consider increasing the timeout ("..timeoutValue.."s).")
    end
  end
end

return contract