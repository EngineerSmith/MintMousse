local loggerWhitelist = require(PATH .. "thread.server.logger"):extend("Whitelist")

local whitelist = {
  ipv4 = { singles = { }, cidrs = { }, cidrSet = { } },
  ipv6 = { singles = { }, cidrs = { }, cidrSet = { } },
}

local CIDRv4Pattern = "^(%d+%.%d+%.%d+%.%d+)/(%d+)$"
local CIDRv6Pattern = "^(.+)/(%d+)$"

-- IPv4 helpers
local ipv4Parts = function(address)
  if type(address) ~= "string" then return nil end
  local parts = { }
  for p in address:gmatch("(%d+)") do
    local n = tonumber(p)
    if not n or n < 0 or n > 255 then return nil end
    table.insert(parts, n)
  end
  return parts
end

local normalizeIPv4 = function(address)
  local parts = ipv4Parts(address)
  if type(parts) ~= "table" then return nil end
  return table.concat(parts, ".")
end

local ipv4ToInt = function(address)
  local parts = ipv4Parts(address)
  if type(parts) ~= "table" then return nil end
  return parts[1] * 2^24 + parts[2] * 2^16 + parts[3] * 2^8 + parts[4]
end

local isValidIPv4 = function(address)
  return ipv4Parts(address) ~= nil
end

local isValidCIDRv4 = function(cidr)
  local ip, mask = cidr:match(CIDRv4Pattern)
  if not ip or not mask then return false end
  local m = tonumber(mask)
  return isValidIPv4(ip) and m and m >= 0 and m <= 32
end

-- IPv6 helpers
local expandIPv6 = function(str)
  if type(str) ~= "string" then return nil end
  str = str:lower():match("^%s*(.-)%s*$")
  if str == "" or str == "::" then return { 0, 0, 0, 0, 0, 0, 0, 0 } end

  local ipv4Tail = str:match(":(%d+%.%d+%.%d+%.%d+)$")
  if ipv4Tail and str:find("ffff", 1, true) and isValidIPv4(ipv4Tail) then
    local parts = ipv4Parts(ipv4Tail)
    local high = parts[1] * 256 + parts[2]
    local low  = parts[3] * 256 + parts[4]
    return { 0, 0, 0, 0, 0, 0xffff, high, low }
  end

  local firstDouble = str:find("::")
  if firstDouble and str:find("::", firstDouble + 2) then return nil end

  local hasDouble = firstDouble ~= nil
  local colonCount = select(2, str:gsub(":", ""))
  if not hasDouble and colonCount ~= 7 then return nil end
  if hasDouble and colonCount > 7 then return nil end

  local left, right = str:match("^(.-)::(.*)$")
  if not left then left, right = str, "" end

  local leftGroups, rightGroups = { }, { }
  for part in (left .. ":"):gmatch("([^:]+):") do
    table.insert(leftGroups, part)
  end
  for part in (right .. ":"):gmatch("([^:]+):") do
    table.insert(rightGroups, part)
  end

  local total = #leftGroups + #rightGroups
  if total > 8 then return nil end

  local result = { }
  for _, part in ipairs(leftGroups) do
    if #part > 4 or not part:match("^[0-9a-f]+$") then return nil end
    local v = tonumber(part, 16)
    if not v or v > 0xffff then return nil end
    table.insert(result, v)
  end
  for _ = 1, 8 - total do
    table.insert(result, 0)
  end
  for _, part in ipairs(rightGroups) do
    if #part > 4 or not part:match("^[0-9a-f]+$") then return nil end
    local v = tonumber(part, 16)
    if not v or v > 0xffff then return nil end
    table.insert(result, v)
  end

  return #result == 8 and result or nil
end

local isValidIPv6 = function(address)
  return expandIPv6(address) ~= nil
end

local isValidCIDRv6 = function(cidr)
  local ip, mask = cidr:match(CIDRv6Pattern)
  if not ip or not mask then return false end
  local m = tonumber(mask)
  return m and m >= 0 and m <= 128 and expandIPv6(ip) ~= nil
end

local maskIPv6 = function(ipTable, maskLength)
  local full = math.floor(maskLength / 16)
  local rem = maskLength % 16
  local masked = { }
  for i = 1, full do
    masked[i] = ipTable[i]
  end
  local startZero = full + 1
  if rem > 0 and full < 8 then
    local shift = 16 - rem
    masked[full + 1] = math.floor(ipTable[full + 1] / 2^shift) * 2^shift
    startZero = full + 2
  end
  for i = startZero, 8 do
    masked[i] = 0
  end
  return masked
end

local tablesEqual = function(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

local extractIPv4FromMapped = function(expanded)
  if expanded[1] == 0 and expanded[2] == 0 and expanded[3] == 0 and
     expanded[4] == 0 and expanded[5] == 0 and expanded[6] == 0xffff then
    local a, b = math.floor(expanded[7] / 256), expanded[7] % 256
    local c, d = math.floor(expanded[8] / 256), expanded[8] % 256
    return a .. "." .. b .. "." .. c .. "." .. d
  end
  return nil
end

local matchesIPv4Rules = function(address)
  local norm4 = normalizeIPv4(address)
  if not norm4 then return false end
  if whitelist.ipv4.singles[norm4] then return true end
  local int = ipv4ToInt(norm4)
  if not int then return false end
  for _, rule in ipairs(whitelist.ipv4.cidrs) do
    if math.floor(int / (2^(32 - rule.maskLength))) == rule.network then
      return true
    end
  end
  return false
end

----

whitelist.add = function(address)
  if type(address) ~= "string" then
    loggerWhitelist:warning("Invalid whitelist address format:", address)
    return false
  end

  local lower = address:lower():match("^%s*(.-)%s*$")

  if lower == "localhost" or lower == "local" or lower == "127.0.0.1" or lower == "::1" then
    local key6 = table.concat(expandIPv6("::1"), ":")

    whitelist.ipv4.singles["127.0.0.1"] = true
    whitelist.ipv6.singles[key6] = true

    loggerWhitelist:info("Added localhost (IPv4 + IPv6):", address)
    return true
  end

  -- CIDR IPv4
  if isValidCIDRv4(lower) then
    local ipPart, maskPart = lower:match(CIDRv4Pattern)
    local ipv4Int, mask = ipv4ToInt(ipPart), tonumber(maskPart)
    local network = math.floor(ipv4Int / (2^(32 - mask)))
    local key = network .. "|" .. mask
    if whitelist.ipv4.cidrSet[key] then
      loggerWhitelist:info("IPv4 CIDR already whitelisted:", address)
      return true
    end
    table.insert(whitelist.ipv4.cidrs, {
      network = network,
      maskLength = mask,
    })
    whitelist.ipv4.cidrSet[key] = true
    loggerWhitelist:info("Added IPv4 CIDR:", address)
    return true
  end

  -- CIDR IPv6
  if isValidCIDRv6(lower) then
    local ipPart, maskPart = lower:match(CIDRv6Pattern)
    local expanded, mask = expandIPv6(ipPart), tonumber(maskPart)
    local network = maskIPv6(expanded, mask)
    local key = table.concat(network, ":") .. "|" .. mask
    if whitelist.ipv6.cidrSet[key] then
      loggerWhitelist:info("IPv6 CIDR already whitelisted:", address)
      return true
    end
    table.insert(whitelist.ipv6.cidrs, {
      network = network,
      maskLength = mask,
    })
    whitelist.ipv6.cidrSet[key] = true
    loggerWhitelist:info("Added IPv6 CIDR:", address)
    return true
  end

  -- Single IPv4
  local norm4 = normalizeIPv4(lower)
  if norm4 then
    whitelist.ipv4.singles[norm4] = true
    loggerWhitelist:info("Added IPv4 address:", address)
    return true
  end

  -- Single IPv6
  if isValidIPv6(lower) then
    local expanded = expandIPv6(lower)
    local key = table.concat(expanded, ":")
    whitelist.ipv6.singles[key] = true
    loggerWhitelist:info("Added IPv6 address:", address)
    return true
  end

  loggerWhitelist:warning("Invalid whitelist address format:", address)
  return false
end

whitelist.remove = function(address)
  if type(address) ~= "string" then
    return false
  end

  local lower = address:lower():match("^%s*(.-)%s*$")

  if lower == "localhost" or lower == "local" or lower == "127.0.0.1" or lower == "::1" then
    whitelist.ipv4.singles["127.0.0.1"] = nil
    local key6 = table.concat(expandIPv6("::1"), ":")
    whitelist.ipv6.singles[key6] = nil
    loggerWhitelist:info("Removed localhost (both IPv4 and IPv6)")
    return true
  end

  -- Remove IPv4 CIDR
  if isValidCIDRv4(lower) then
    local ipPart, maskPart = lower:match(CIDRv4Pattern)
    local mask = tonumber(maskPart)
    local network = math.floor(ipv4ToInt(ipPart) / (2^(32 - mask)))
    local key = network .. "|" .. mask
    for i = #whitelist.ipv4.cidrs, 1, -1 do
      local rule = whitelist.ipv4.cidrs[i]
      if rule.network == network and rule.maskLength == mask then
        table.remove(whitelist.ipv4.cidrs, i)
        whitelist.ipv4.cidrSet[key] = nil
        loggerWhitelist:info("Removed IPv4 CIDR:", address)
        return true
      end
    end
  end

  -- Remove IPv6 CIDR
  if isValidCIDRv6(lower) then
    local ipPart, maskPart = lower:match(CIDRv6Pattern)
    local expanded, mask = expandIPv6(ipPart), tonumber(maskPart)
    local network = maskIPv6(expanded, mask)
    local key = table.concat(network, ":") .. "|" .. mask
    for i = #whitelist.ipv6.cidrs, 1, -1 do
      local rule = whitelist.ipv6.cidrs[i]
      if rule.maskLength == mask and tablesEqual(rule.network, network) then
        table.remove(whitelist.ipv6.cidrs, i)
        whitelist.ipv6.cidrSet[key] = nil
        loggerWhitelist:info("Removed IPv6 CIDR:", address)
        return true
      end
    end
  end

  -- Remove single IPv4
  local norm4 = normalizeIPv4(lower)
  if norm4 and whitelist.ipv4.singles[norm4] then
    whitelist.ipv4.singles[norm4] = nil
    loggerWhitelist:info("Removed IPv4 address:", norm4)
    return true
  end

  -- Remove single IPv6
  if isValidIPv6(lower) then
    local key = table.concat(expandIPv6(lower), ":")
    if whitelist.ipv6.singles[key] then
      whitelist.ipv6.singles[key] = nil
      loggerWhitelist:info("Removed IPv6 address:", address)
      return true
    end
  end

  loggerWhitelist:info("Address/CIDR to remove not found or invalid:", address)
  return false
end

whitelist.check = function(address, family)
  if family == "inet" then
    return matchesIPv4Rules(address)

  elseif family == "inet6" then
    local expanded = expandIPv6(address)
    if not expanded then return false end

    local key = table.concat(expanded, ":")
    if whitelist.ipv6.singles[key] then return true end

    for _, rule in ipairs(whitelist.ipv6.cidrs) do
      local masked = maskIPv6(expanded, rule.maskLength)
      if tablesEqual(masked, rule.network) then
        return true
      end
    end

    local ipv4 = extractIPv4FromMapped(expanded)
    if ipv4 then
      return matchesIPv4Rules(ipv4)
    end
  end

  return false
end

whitelist.clear = function()
  whitelist.ipv4.singles = { }
  whitelist.ipv4.cidrs   = { }
  whitelist.ipv4.cidrSet = { }
  whitelist.ipv6.singles = { }
  whitelist.ipv6.cidrs   = { }
  whitelist.ipv6.cidrSet = { }
  loggerWhitelist:info("Whitelist cleared")
end

return whitelist