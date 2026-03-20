local http = {
  methods = {
    GET = { },
    POST = { },
  },
  defaultResponse = { },
  statusCode = {
    [101] = "Switching Protocols",
    [200] = "OK",
    [204] = "No Content",
    [400] = "Bad Request",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [411] = "Length Required",
    [413] = "Content Too Large",
    [426] = "Upgrade Require",
    [500] = "Internal Server Error",
  },
}

http.getAllowedMethods = function(uri)
  local allowedMethods = { }
  for method, uriTable in pairs(http.methods) do
    if uriTable[uri] then
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
    love.mintmousse.error("HTTP: Method is not supported:", method)
    return
  end
  methodTable[uri] = func
end

http.processRequest = function(request)
  local methodTable = http.methods[request.method]
  if not methodTable then
    love.mintmousse.info("HTTP: Client tried to use method", request.method, "for", request.parsedURI.path)
    return 405, nil, nil
  end

  local uriFunc = methodTable[request.parsedURI.path]
  if not uriFunc then
    local allowedMethods = http.getAllowedMethods(request.parsedURI.path)
    if not allowedMethods then
      love.mintmousse.info("HTTP: Client requested for unknown uri:", request.parsedURI.path)
      return 404, nil, nil
    end
    love.mintmousse.info("HTTP: Client tried to use method", request.method, "for", request.parsedURI.path)
    return 405, nil, nil
  end

  local success, code, headers, content = true, nil, nil, nil

  if type(uriFunc) == "function" then
    success, code, headers, content = pcall(uriFunc, request)
  else
    code = uriFunc
  end

  if not success then
    love.mintmousse.warning("HTTP: Error occurred while trying to call:", request.method, request.parsedURI.path, ". Error message:", code)
    return 500, { connection = "close" }, nil
  end

  return code, headers, content
end

http.getDate = function()
  return os.date("!%a, %d %b %Y %H:%M:%S GMT", os.time())
end

return http