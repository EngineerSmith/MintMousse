return function(PATH, prefix, log, warning, _error, _assert)
  requireMintMousse = function(file)
    return require(PATH .. file)
  end

  prefix = "MintMousse" .. (prefix and " " .. prefix or "") .. ": "

  if log ~= false then -- note, nil is true
    local logging_log = prefix .. "log: "
    logMintMousse = function(...)
      print(logging_log .. table.concat({...}, " "))
    end
  end

  if warning ~= false then
    local logging_warning = prefix .. "warning: "
    warningMintMousse = function(...)
      print(logging_warning .. table.concat({...}, " "))
    end
  end

  if _error ~= false then
    local asserting = 0  -- Used to raise the stack depth when generating debug info
    local logging_error = prefix .. "error: "
    errorMintMousse = function(...)
      local str = table.concat({...}, " ")

      if debug then
        local info = debug.getinfo(2 + asserting, "fnS")
        if info then
          local name = "UNKNOWN"
          if info.name then
            name = info.name
          elseif info.func then -- Attempt to create a name from memory address
            name = tostring(info.func):sub(10)
          end
          if info.short_src then
            name = name .. "@" .. info.short_src .. (info.linedefined and "#" .. info.linedefined or "")
          end
          str = name .. ": " .. str
        end
      end

      print(logging_error .. str)
      error(logging_error .. str)
    end

    if _assert ~= false then
      assertMintMousse = function(condition, ...)
        if not condition then
          asserting = 1
          errorMintMousse(...)
          asserting = 0
        end
      end
    end
  end
end
