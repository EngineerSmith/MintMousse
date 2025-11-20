local PATH = ... .. "."
local dirPATH = PATH:gsub("%.", "/")
local love = love

assert(love, "MintMousse: Library is missing dependency LÖVE")
assert(jit, "MintMousse: Library is missing dependency LuaJIT. This is usually packaged with LÖVE.")
assert(pcall(require, "string.buffer"), "MintMousse: Library is missing dependency LuaJIT's String Buffer Library. This is packaged with LÖVE from 11.4")

require("love.timer")

if love.isThread == nil then
  love.isThread = love.path == nil
end

if type(love.mintmousse) ~= "nil" then
  local message = "There is a conflict in namespace with 'love.mintmousse'. Expected a nil value"
  if type(love.mintmousse) == "table" and type(love.mintmousse._libLog) == "table" then
    love.mintmousse._libLog:error(message)
  else
    error(message)
  end
  return
end

love.mintmousse = {
  _path = PATH,
  _directoryPath = dirPATH,

  -- Internal per thread
  _proxyComponents = { },
  _componentTypes = nil, -- given via blocking call at bottom of this file
}

love.mintmousse._require = function(filepath)
  return require(love.mintmousse._path .. filepath)
end

love.mintmousse._read = function(filepath)
  return love.filesystem.read(love.mintmousse._directoryPath .. filepath)
end

local conf = love.mintmousse._require("conf")(love.mintmousse._path, love.mintmousse._directoryPath)
for k, v in pairs(conf) do
  love.mintmousse[k] = v
end

love.mintmousse._require("preload")

love.mintmousse._require("threadCommunication")

love.mintmousse.logger = love.mintmousse._require("logger").extend()

local libraryLogger = love.mintmousse.logger:extend("MintMousse", "bright_green")

local internalLogger
if love.isMintMousseThread then -- Library's own thread
  internalLogger = libraryLogger:extend("Thread", "magenta")
elseif love.isThread then       -- Library user's thread
  internalLogger = libraryLogger:extend("Worker", "cyan")
else                            -- Main thread
  internalLogger = libraryLogger:extend("Main", "white")
end

love.mintmousse._libLog = internalLogger

if love.mintmousse.REPLACE_FUNC_PRINT then
  -- Overrides global print and redirects it to logger.debug;
  -- global print can still be access via `GLOBAL_print` variable set in `logger.lua`
  print = function(...)
    love.mintmousse._stackFramePush()
    love.mintmousse.logger:debug(...)
    love.mintmousse._stackFramePop()
  end
end

love.mintmousse._require("sanitizer")

if love.isMintMousseThread then
  return
end

if not love.isThread then -- is Main thread

  love.mintmousse._require("errorhandler")

  love.mintmousse._require("threadController")

  love.mintmousse._require("eventManager")

end

love.mintmousse._require("threadIDManager")

-- love.mintmousse._require("threadHinting")
love.mintmousse._require("threadContract")

love.mintmousse._require("proxyTable")



-- Wait for component types to be parsed: this can be a quick operation, but it is blocking
local start = love.timer.getTime()
local timeoutValue = love.mintmousse.COMPONENT_PARSE_TIMEOUT
repeat
  love.mintmousse._checkTypeCompleteness()

  local success = love.mintmousse._componentTypes ~= nil
  local timedOut = love.timer.getTime() - start >= timeoutValue

  if not success and not timedOut then
    love.timer.sleep(0.0005) -- 0.5 ms
  end
until success or timedOut

-- If timeout is reached
if love.mintmousse._componentTypes == nil then
  local logger = love.mintmousse._libLog
  logger:warning(
    "Timeout reached ("..timeoutValue.."s) while waiting for MintMousse thread to parse components.",
    "Attempting to check for thread error."
  )

  local channel = love.thread.getChannel(love.mintmousse.READONLY_THREAD_LOCATION)
  local thread = channel:peek()
  if not thread then
    logger:warning("MintMousse Thread channel was empty after timeout.",
      "Thread may have not properly initialized. Check preload.lua.")
    return
  end
  local errorMessage = thread:getError()
  if errorMessage then
    local success = false
    if type(love.handlers) == "table" and love.handlers["threaderror"] then
      pcall(love.handlers["threaderror"], thread, errorMessage)
    end
    logger:error(errorMessage) -- ensure we log the error even if `threaderror` was successfully called
  else
    logger:warning("The thread object reported no error.",
      "This suggests the MintMousse Thread is stuck or overloaded.",
      "Consider increasing the timeout ("..timeoutValue.."s).")
  end
  return
end