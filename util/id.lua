local PATH = (...):match("^(.-)%.[^%.]+$")
local ROOT = PATH:match("^(.-)[^%.]+$") or ""
PATH = PATH .. "."

local mintmousse = require(ROOT .. "conf")

local id = { }

local base62_Alphabet = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

local base62Encode = function(num)
  if num == 0 then
    return base62_Alphabet:sub(1, 1)
  end

  local encoded, current = "", num
  while current > 0 do
    local remainder = current % 62
    encoded = base62_Alphabet:sub(remainder + 1, remainder + 1) .. encoded
    current = math.floor(current / 62)
  end
  return encoded
end

local idPrefix = "MM" .. mintmousse._threadID .. "_"
local idCounter = 0
id.generateID = function()
  local newID = idPrefix .. base62Encode(idCounter)
  idCounter = idCounter + 1
  return newID
end

local threadCounterChannel = love.thread.getChannel(mintmousse.THREAD_ID_COUNTER)
-- init channel
threadCounterChannel:performAtomic(function()
  if threadCounterChannel:getCount() == 0 then
    threadCounterChannel:push(0)
  end
end)

id.getNewThreadID = function()
  local id
  threadCounterChannel:performAtomic(function()
    id = threadCounterChannel:pop()
    threadCounterChannel:push(id + 1)
  end)
  return id
end

local protectedKeywords = {
  ["all"]     = true,
  ["unknown"] = true,
}
local invalidPattern = "[^%w%._,:;@-]"

id.isValidID = function(str)
  if type(str) ~= "string" then
    return false, "ID isn't type string"
  end

  if #str == 0 then
    return false, "ID cannot be empty"
  end

  local firstByte = str:byte(1)
  if firstByte >= 48 and firstByte <= 57 then
    return false, "ID cannot start with number"
  end

  if protectedKeywords[str] then
    return false, "ID cannot use the protected keyword '" .. str .. "'"
  end

  local badChar = str:match(invalidPattern)
  if badChar then
    return false, "ID contains invalid character: '" .. badChar .. "'"
  end

  return true, nil
end

return id