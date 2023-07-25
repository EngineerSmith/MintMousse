return function(PATH, prefix)
  requireMintMousse = function(file)
    return require(PATH .. file)
  end

  prefix = prefix or ""
  prefix = "Mintmousse " .. prefix .. ": "

  local logging_log = prefix .. "log:"
  logMintMousse = function(...)
    print(logging_log .. table.concat({...}, " "))
  end

  local logging_warning = prefix .. "warning:"
  warningMintMousse = function(...)
    print(logging_warning .. table.concat({...}, " "))
  end

  local logging_error = prefix .. "error:"
  errorMintMousse = function(...)
    local str = table.concat({...}, " ")

    if debug then
      local info = debug.getinfo(2, "fnS")
      if info then
        local name
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
end
