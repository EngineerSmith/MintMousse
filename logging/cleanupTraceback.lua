local PATH = (...):match("^(.-)[^%.]+$"):sub(1, -2)

local patterns = {
  boot      = "%[love \"boot%.lua\"%]:%d+:",
  callbacks = "%[love \"callbacks%.lua\"%]:%d+:",
}

local match = function(line, pattern)
  return type(line) == "string" and line:find(pattern)
end

local filterPatterns = {
  { -- Remove the `logger.error` instance call
    pattern = "/logging/logger%.lua:%d+: in function 'error'",
    condition = function(lines, i)
      local logging = require(PATH)
      return logging.isInsideError and match(lines[i-1], "%[C%]: in function 'error'")
    end,
    counts = 1,
  },
  { -- Remove the `love.errorhandler` call
    pattern = "%.lua:%d+: in function 'handler'",
    condition = function(lines, i)
      local logging = require(PATH)
      local insideIssue = logging.isInsideFatal or logging.isInsideError
      return insideIssue and match(lines[i+1], patterns.boot)
    end,
    counts = 1,
  },
  { -- Remove love internal `xpcall` call; works by searching the stack above for "boot.lua"
    pattern = "%[C%]: in function 'xpcall'",
    condition = function(lines, i)
      return match(lines[i+1], patterns.boot) or match(lines[i-1], patterns.callbacks)
    end,
    counts = -1,
  },
  { -- Remove love internal `require` call; works by searching the stack above for "boot.lua"
    pattern = "%[C%]: in function 'require'",
    condition = function(lines, i)
      return match(lines[i+1], patterns.boot)
    end,
    counts = -1,
  },
  { pattern = patterns.boot, counts = -1 }, -- Remove all love internal boot calls
  { pattern = patterns.callbacks, counts = -1 }, -- Remove all love internal callbacks calls
}
-- Sort filters to reduce number of string matching required
table.sort(filterPatterns, function(a, b)
  if a.counts == -1 and b.counts == -1 then return false end
  if a.counts == -1 then return true end
  if b.counts == -1 then return false end
  return a.counts > b.counts
end)

local INDENT = "    "
local replaceTabsWithSpaces = function(tabs)
  return INDENT:rep(#tabs)
end

-- Cleans up a traceback string by removing lines matching specific filters to make the issue much more visible.
local cleanupTraceback = function(traceback)
  if traceback:sub(-1) ~= "\n" then
    traceback = traceback .. "\n"
  end

  local lines = { }
  for line in (traceback):gmatch("([^\n]+)\n") do
    line = line:gsub("^\t+", replaceTabsWithSpaces)
    table.insert(lines, line)
  end

  local toRemove = { }
  for _, rule in ipairs(filterPatterns) do
    local count = rule.counts

    for i, line in ipairs(lines) do
      if toRemove[i] then
        goto continue
      end

      if not line:find(rule.pattern) then
        goto continue
      end

      if rule.condition and not rule.condition(lines, i) then
        goto continue
      end

      toRemove[i] = true
      if count ~= -1 then
        count = count - 1
        if count == 0 then break end
      end

      ::continue::
    end
  end

  local cleanLines = { }
  for i, line in ipairs(lines) do
    if not toRemove[i] then
      table.insert(cleanLines, line)
    end
  end

  local finalTraceback = table.concat(cleanLines, "\n")
  finalTraceback = finalTraceback:gsub("stack traceback", "Traceback")

  if love and love._version_major <= 11 and love._version_minor <= 5 then
    -- Love 11.5 and earlier have a default love.errorhandler that doesn't read
    --  the traceback correctly. Append a new line to apply a general fix.
    finalTraceback = finalTraceback .. "\n"
  end

  return finalTraceback
end

return cleanupTraceback