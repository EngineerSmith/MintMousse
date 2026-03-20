local PATH = (...):match("^(.-)%.[^%.]+$")
local ROOT = PATH:match("^(.-)[^%.]+$") or ""

local logger = { }
logger.__index = logger

local mintmousse = require(ROOT .. ".conf") -- the last coupling to mintmousse? Do we need to fully decouple?
local stack = require(PATH .. ".stack")
local loggingColors = require(PATH .. ".color")

local dispatchToSinks
local getTime
logger.setup = function(dependencies)
  dispatchToSinks = dependencies.dispatch
  getTime = dependencies.getTime
end

logger.extend = function(parent, name, colorDef)
  if type(parent) == "string" then
    colorDef, prefix, parent = name, parent, nil
  end

  local self = setmetatable({
    name = name,
    colorDef = loggingColors.validateColorDef(colorDef),
    parent = parent,
  }, logger)
  -- init
  self:getAncestry()

  return self
end

logger.getAncestry = function(self)
  if self.chain then
    return self.chain
  end

  local chain = { }

  local current = self
  while current do
    if type(current.name) == "string" then
      table.insert(chain, current)
    end
    current = current.parent
  end

  self.chain = chain
  return self.chain
end

logger.info = function(self, ...)
  local time = getTime()
  stack.push()
  dispatchToSinks("info", self, time, mintmousse.LOG_INCLUDE_TRACE and stack.getDebugInfo() or nil, ...)
  stack.pop()
end

logger.warning = function(self, ...)
  local time = getTime()
  stack.push()
  local debugInfo = nil
  if mintmousse.LOG_INCLUDE_TRACE or mintmousse.LOG_WARNINGS_INCLUDE_TRACE then
    debugInfo = stack.getDebugInfo()
  end
  dispatchToSinks("warning", self, time, debugInfo, ...)
  if mintmousse.LOG_WARNINGS_CAUSE_ERRORS then
    -- Reroute the call to the error handler to raise a clean error
    -- Note, this will call dispatchToSinks again, which is intended.
    self:error("[PROMOTED WARNING]", ...)
  end
  stack.pop()
end

logger.debug = function(self, ...)
  local time = getTime()
  stack.push()
  -- Always get debug info for debug messages
  dispatchToSinks("debug", self, time, stack.getDebugInfo(), ...)
  stack.pop()
end

logger.error = function(self, ...)
  local time = getTime()
  stack.push()
  -- Always get debug info for errors
  dispatchToSinks("error", self, time, stack.getDebugInfo(), ...)

  if mintmousse.LOG_ENABLE_ERROR or isMintMousseThread then
    local logMessage = table.concat({ ... }, " ")
    local logging = require(PATH)
    logging.isInsideError = true
    error(logMessage, stack.frameOffset + 1)
    logging.isInsideError = false
  end
  stack.pop()
end

logger.assert = function(self, condition, ...)
  if not condition then
    stack.push()
    self:error(...)
    stack.pop()
  end
end

return logger