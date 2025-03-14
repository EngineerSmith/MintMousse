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
    [426] = "Upgrade Require",
    [500] = "Internal Server Error",
  },
}

local allowedMethods = { }
for method in pairs(http.methods) do
  table.insert(allowedMethods, method)
end
http.allowedMethods = table.concat(allowedMethods, ", ")
allowedMethods = nil

http.addMethod = function(method, uri, func)
  local methodTable = http.methods[method]
  if not methodTable then
    love.mintmousse.error("HTTP: Method is not supported:", method)
    return
  end
  methodTable[uri] = func
end

return http