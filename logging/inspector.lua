local inspector = { }

local safeRepresent = function(x)
  if type(x) == "string" then
    return ("%q"):format(x)
  end
  return tostring(x)
end

local inspectLight = function(tbl)
  local messageParts = { }
  for k, v in pairs(tbl) do
    table.insert(messageParts,
      ("[%s] = %s"):format(safeRepresent(k), safeRepresent(v))
    )
  end
  local inner = table.concat(messageParts, ", ")
  return inner == "" and "{}" or "{ " .. inner .. " }"
end

local inspectDeep
inspectDeep = function(tbl, maxDepth, indentLevel, seen)
  maxDepth = maxDepth or 3
  if maxDepth <= 0 then
    return "{ ... (depth limit reached) }"
  end
  indentLevel = indentLevel or 0
  seen = seen or { }
  if seen[tbl] then
    return "{ <cycle> }"
  end
  seen[tbl] = true

  local parts = { }
  local indent = string.rep("  ", indentLevel)

  for k, v in pairs(tbl) do
    local keyStr = ("[%s]"):format(safeRepresent(k))

    local valStr
    if type(v) == "table" then
      valStr = inspectDeep(v, maxDepth - 1, indentLevel + 1, seen)
    else
      valStr = safeRepresent(v)
    end

    table.insert(parts, ("%s%s = %s"):format(indent, keyStr, valStr))
  end

  if #parts == 0 then
    return "{}"
  end

  local inner = table.concat(parts, ",\n")
  return "{\n" .. inner .. "\n" .. indent .. "}"
end

inspector.inspect = function(value, level)
  if type(value) ~= "table" then
    return tostring(value)
  end

  level = level or "light"

  if level == "light" then
    return inspectLight(value)
  elseif level == "deep" then
    return inspectDeep(value, 3)
  elseif level == "number" then
    return inspectDeep(value, level)
  else
    error("Inspect: level must be 'light', 'deep', or a number (depth). Got: " .. tostring(level), 2)
  end
end

return inspector