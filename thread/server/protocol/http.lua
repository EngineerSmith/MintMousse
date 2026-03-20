local loggerHTTP = require(PATH .. "thread.server.protocol.logger"):extend("HTTP")

local http = {
  methods = {
    GET = { },
    POST = { },
  },
  -- Edit below if there are other supported versions in the future
  upgradeValue = "HTTP/1.1",
  defaultResponse = { },
  statusCode = {
    [101] = "Switching Protocols",
    [200] = "OK",
    [204] = "No Content",
    [400] = "Bad Request",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [408] = "Request Timeout",
    [411] = "Length Required",
    [413] = "Content Too Large",
    [426] = "Upgrade Require",
    [500] = "Internal Server Error",
  },
  _logger = loggerHTTP,
}

local findHandler = function(methodTable, path)
  local uriFunc = methodTable[path]
  if type(uriFunc) == "function" then
    return uriFunc, nil, nil
  end

  if methodTable.wildcards then
    for _, wc in ipairs(methodTable.wildcards) do
      local captures = { path:match(wc.pattern) }
      if captures[1] ~= nil then
        local namedParams = { }
        if wc.params then
          for i, name in ipairs(wc.params) do
            local value = captures[i]
            if value ~= nil then
             namedParams[name] = value
            end
          end
        end
        return wc.handler, captures, namedParams
      end
    end
  end
  return nil, nil
end

http.getAllowedMethods = function(uri)
  local allowedMethods = { }
  for method, uriTable in pairs(http.methods) do
    if findHandler(uriTable, uri) then
      table.insert(allowedMethods, method)
    end
  end
  if #allowedMethods == 0 then
    return nil
  end
  return table.concat(allowedMethods, ", ")
end

http.addMethod = function(method, uri, func)
  local methodTable = http.methods[method]
  if not methodTable then
    loggerHTTP:error("Tried to add method that isn't supported:", method)
    return
  end

  if uri:find("[*:]") then
    if not methodTable.wildcards then
      methodTable.wildcards = { }
    end

    local escaped = uri:gsub("([%^%$%(%)%.%[%]%+%-%?%%])", "%%%1")
    local paramNames = { }

    escaped = escaped:gsub(":([%w_]+)", function(name)
      table.insert(paramNames, name)
      return "([^/]+)"
    end)

    escaped = escaped:gsub("%*([%w_]*)", function(suffix)
      if suffix == "" then
        table.insert(paramNames, "*")
      else
        table.insert(paramNames, suffix)
      end
      return "(.*)"
    end)

    local pattern = "^" .. escaped .. "$"

    table.insert(methodTable.wildcards, {
      pattern  = pattern,
      handler  = func,
      original = uri,
      params   = paramNames,
    })

    table.sort(methodTable.wildcards, function(a, b)
      return #a.original > #b.original
    end)
  else
    if uri == "wildcard" then
      loggerHTTP:warning("Tried to add method uri 'wildcard'. This is a protected keyword. Maybe you meant '/wildcard'.")
      return
    end
    methodTable[uri] = func
  end
end

http.removeMethod = function(method, uri)
  local methodTable = http.methods[method]
  if not methodTable then
    loggerHTTP:warning("Tried to remove from unsupported method:", method)
    return false
  end

  if uri:find("[*:]") then
    if methodTable.wildcards then
      for i = #methodTable.wildcards, 1, -1 do
        if methodTable.wildcards[i].original == uri then
          table.remove(methodTable.wildcards, i)
          if #methodTable.wildcards == 0 then
            methodTable.wildcards = nil
          end
          return true
        end
      end
    end
  else
    if uri == "wildcard" then
      loggerHTTP:warning("Tried to remove 'wildcard'. This is a protected keyword.")
      return false
    end
    if methodTable[uri] then
      methodTable[uri] = nil
      return true
    end
  end

  return false
end

http.processRequest = function(request, client)
  local methodTable = http.methods[request.method]
  if not methodTable then
    loggerHTTP:info("Client tried to use method", request.method, "for", request.parsedURI.path)
    return 405, nil, nil
  end

  local handler, wildcardCaptures, namedParams = findHandler(methodTable, request.parsedURI.path)
  if not handler then
    local allowedMethods = http.getAllowedMethods(request.parsedURI.path)
    if not allowedMethods then
      loggerHTTP:info("Client requested for unknown uri:", request.parsedURI.path)
      return 404, nil, nil
    end
    loggerHTTP:info("Client tried to use method", request.method, "for", request.parsedURI.path)
    return 405, nil, nil
  end

  if wildcardCaptures then
    request.wildcardMatches = wildcardCaptures
    if namedParams and next(namedParams) then
      request.params = namedParams
    elseif next(wildcardCaptures) then
      request.params = { ["*"] = wildcardCaptures[1] }
    end
  end

  local success, code, headers, content = true, nil, nil, nil

  if type(handler) == "function" then
    success, code, headers, content = pcall(handler, request, client)
  else
    code = handler
  end

  if not success then
    loggerHTTP:warning("Error occurred while trying to call:", request.method, request.parsedURI.path, ". Error message:", code)
    return 500, { connection = "close" }, nil
  end

  return code, headers, content
end

http.getDate = function()
  return os.date("!%a, %d %b %Y %H:%M:%S GMT", os.time())
end

return http