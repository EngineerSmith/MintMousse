local http = {
  methods = {
    GET = { },
    POST = { },
  },
  defaultResponse = { },
  statusCode = {
    --[101] = "Switching Protocols",
    --[200] = "OK",
    [400] = "Bad Request",
    [411] = "Length Required",
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

return http