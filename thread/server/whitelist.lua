local PATH = (...):match("^(.*)whitelist$")
local ROOT = PATH:match("^(.-)thread%.server%.$")
PATH = PATH .. "."

local mintmousse = require(ROOT .. "conf")

local loggerWhitelist = mintmousse._logger:extend("Whitelist")

local whitelist = {
  rules = { },
}

local ipv4ToInt = function(ipAddress)
  local parts = { }
  for part in ipAddress:gmatch("(%d+)") do
    local n = tonumber(part)
    if n < 0 or n > 255 then
      return nil
    end
    table.insert(parts, n)
  end
  if #parts ~= 4 then
    return nil
  end
  return parts[1] * 2^24 + parts[2] * 2^16 + parts[3] * 2^8 + parts[4]
end

local isValidIpv4 = function(address)
  if not address:match("^%d+%.%d+%.%d+%.%d+$") then
    return false
  end
  for part in address:gmatch("(%d+)") do
    local n = tonumber(part)
    if not n or n < 0 or n > 255 then
      return false
    end
  end
  return true
end

local CIDRPattern = "^(%d+%.%d+%.%d+%.%d+)/(%d+)$"
local isValidCIDR = function(cidrString)
  local ipPart, maskPart = cidrString:match(CIDRPattern)
  if not ipPart or not maskPart then
    return false
  end
  if not isValidIpv4(ipPart) then
    return false
  end
  local maskLength = tonumber(maskPart)
  return maskLength ~= nil and maskLength >= 0 and maskLength <= 32
end

whitelist.add = function(address)
  if isValidCIDR(address) then
    local ipPart, maskPart = address:match(CIDRPattern)
    local ipv4Int = ipv4ToInt(ipPart)
    local maskLength = tonumber(maskPart)
    networkAllowed = math.floor(ipv4Int / (2^(32 - maskLength)))
    table.insert(whitelist.rules, {
      type = "cidr",
      networkAllowed = networkAllowed,
      maskLength = maskLength,
    })
    return
  elseif isValidIpv4(address) then
    table.insert(whitelist.rules, {
      type = "ipv4",
      ip = address,
    })
    return
  end
  loggerWhitelist:warning("Invalid whitelist address format:", address)
end

whitelist.check = function(address)
  local ipToCheckInt = ipv4ToInt(address)
  if not ipToCheckInt then
    return false
  end

  for _, allowedEntry in ipairs(whitelist.rules) do
    if allowedEntry.type == "cidr" then
      local networkToCheck = math.floor(ipToCheckInt / (2^(32 - allowedEntry.maskLength)))
      if networkToCheck == allowedEntry.networkAllowed then
        return true
      end
    elseif allowedEntry.type == "ipv4" then
      if address == allowedEntry.ip then
        return true
      end
    end
  end
  return false
end

return whitelist