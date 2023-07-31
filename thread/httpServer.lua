local socket = require("socket")
local helper = requireMintMousse("helper")

local httpServer = {
  connections = {},
  whitelist = {},
  methods = {
    GET = {},
    POST = {}
  },
  defaultResponse = {}
}

httpServer.start = function(host, port, backupPort)
  if httpServer.tcp then
    httpServer.cleanUp()
  end

  local errorMessage
  httpServer.tcp, errorMessage = socket.bind(host, port or 80)
  if not httpServer.tcp then
    if backupPort then
      warningMintMousse("HTTPServer could not be started. Attempting to start again on backupPort. Reason:",
        errorMessage)
      httpServer.tcp, errorMessage = socket.bind(host, backupPort)
    end
    if not httpServer.tcp then
      errorMintMousse("HTTPServer could not be started. Reason:", errorMessage)
    end
  end

  httpServer.tcp:settimeout(0)

  local _, port = httpServer.tcp:getsockname()
  if port then
    logMintMousse("HTTPServer started on port:", port)
  else
    logMintMousse("HTTPServer started.")
  end
end

httpServer.cleanUp = function()
  if httpServer.tcp then
    httpServer.tcp:close()
  end
end

httpServer.addMethod = function(method, url, func)
  local methodTable = httpServer.methods[method]
  if not methodTable then
    return errorMintMousse("HTTPServer method is not supported:", method)
  end
  methodTable[url] = func
end

httpServer.newIncomingConnection = function()
  local client, errorMessage = httpServer.tcp:accept()
  if client then
    client:settimeout(0)
    local address = client:getsockname()
    if httpServer.isWhitelisted(address) then
      httpServer.connections[coroutine.wrap(function()
        local closed, maxAlive = false, 1000
        for it = 1, maxAlive do
          local status = httpServer.processConnection(client, maxAlive - it)
          if status == "close" then
            break
          elseif status == "error" then
            return
          end
          coroutine.yield(true)
        end
        httpServer.respond(client, 408, false)
        client:close()
      end)] = true
    else
      logMintMousse("HTTPServer non-whitelisted connection attempt from:", address)
      client:close()
    end
  elseif errorMessage ~= "timeout" and errorMessage ~= "closed" then
    warningMintMousse("HTTPServer error occurred while accepting a connection:", errorMessage)
  end
end

httpServer.updateConnections = function()
  for connection in pairs(httpServer.connections) do
    if connection() == nil then
      httpServer.connections[connection] = nil
    end
  end
end

httpServer.processConnection = function(client, maxAlive)
  local request = httpServer.parseRequest(client)
  local keepAlive = request.headers["Connection"] == "keep-alive"
  client:setoption("keepalive", keepAlive)

  if request.protocol == "HTTP/1.1" then

    local methodTable = httpServer.methods[request.method]
    if not methodTable then
      logMintMousse("HTTPServer client requested for unsupported method:", request.method)
      httpServer.respond(client, 405, false)
      return "error", client:close()
    end

    local urlFunc = methodTable[request.parsedURL.path]
    if not urlFunc then
      logMintMousse("HTTPServer client requested for unknown url:", request.parsedURL.path)
      httpServer.respond(client, 404, false)
      return "error", client:close()
    end

    local status, code, content, contentType = true, nil, nil, nil
    if type(urlFunc) == "function" then
      status, code, content, contentType = pcall(urlFunc, request)
    else
      code = urlFunc
    end

    if not status then
      warningMintMousse("HTTPServer error occurred while trying to call:", request.method, request.url,
        ". Error message:", code)
      httpServer.respond(client, 500, false)
      return "error", client:close()
    end

    httpServer.respond(client, code, keepAlive and maxAlive or nil, content, contentType)

  elseif request.protocol and request.protocol:find("HTTP") then
    logMintMousse("HTTPServer client using unsupported HTTP protocol:", request.protocol)
    httpServer.respond(client, 505, false)
    return "error", client:close()
  end

  ::continue::
  if not keepAlive then
    return "close"
  end
  return "open"
end

--[[whitelist]]

local whitelistPattern = function(c)
  if c == "." then
    return "%." -- "127.0.0.1" -> "127%.0%.0%.0"
  elseif c == "*" then
    return "%d+" -- > "192.168.*.*" - > "192.168.%d+.%d+"
  end
end

httpServer.addToWhitelist = function(address)
  table.insert(httpServer.whitelist, "^" .. address:gsub("[%.%*]", whitelistPattern) .. "$")
end

httpServer.isWhitelisted = function(address)
  for _, allowedAddress in ipairs(httpServer.whitelist) do
    if address:match(allowedAddress) then
      return true
    end
  end
  return false
end

--[[default response]]

httpServer.addDefaultResponse = function(code, content, contentType)
  if not httpServer.statusCode[code] then
    return warningMintMousse("HTTPServer tried to add default response for non-existing status code:", code)
  end
  httpServer.defaultResponse[code] = {
    content = content,
    contentType = contentType
  }
  logMintMousse("HTTPServer added default response for status", code)
end

--[[status codes]]

httpServer.statusCode = { -- https://en.wikipedia.org/wiki/HTTP#HTTP/1.1_response_messages
  [200] = "200 OK",
  [202] = "202 Accepted",
  [204] = "204 No Content",
  [404] = "404 Not Found",
  [405] = "405 Method Not Allowed",
  [408] = "408 Request Timeout",
  [422] = "422 Unprocessable Entity",
  [500] = "500 Internal Server Error",
  [505] = "505 HTTP Version Not Supported"
}
for key, value in pairs(httpServer.statusCode) do
  httpServer.statusCode[key] = "HTTP/1.1 " .. value .. "\r\n"
end

httpServer.generateHeaders = function(keepAlive, contentLength, contentType)
  local headers = {}
  if keepAlive then
    if type(keepAlive) == "number" then
      table.insert(headers, "Connection: keep-alive\r\nKeep-Alive: max=" .. keepAlive)
    else
      table.insert(headers, "Connection: keep-alive")
    end
  else
    table.insert(headers, "Connection: close")
  end
  if contentLength then
    table.insert(headers, "Content-Length: " .. contentLength)
  else
    table.insert(headers, "Content-Length: 0")
  end
  if contentType then
    table.insert(headers, "Content-Type: " .. contentType)
  end
  return table.concat(headers, "\r\n") .. "\r\n\r\n"
end

httpServer.respond = function(client, code, keepAlive, content, contentType)
  if not httpServer.statusCode[code] then
    warningMintMousse("HTTPServer could not find given status code to respond:", code)
    httpServer.respond(client, 500, false)
  end

  if not content and httpServer.defaultResponse[code] then
    local defaultResponse = httpServer.defaultResponse[code]
    content = defaultResponse.content
    contentType = defaultResponse.contentType
  end
  local httpResponse = httpServer.statusCode[code] ..
                         httpServer.generateHeaders(keepAlive, type(content) == "string" and #content, contentType) ..
                         (content or "")
  httpServer.send(client, httpResponse)
end

--[[helper]]

httpServer.getTime = love.timer.getTime

httpServer.receive = function(client, pattern)
  while true do
    local data, errMsg = client:receive(pattern)
    if not data then
      coroutine.yield(errMsg == "timeout") -- if timeout; wait
    else
      return data
    end
  end
end

httpServer.send = function(client, data)
  local i, size = 1, #data
  while i < size do
    local j, errorMessage, k = client:send(data, i)
    if not j then
      if errorMessage == "closed" then
        return coroutine.yield(nil)
      end
      i = k + 1
    else
      i = i + j
    end
    coroutine.yield(true)
  end
end

-- https://en.wikipedia.org/wiki/HTTP#HTTP/1.1_request_messages
local requestMethodPattern = "(%S*)%s*(%S*)%s*(%S*)"
local requestHeaderPattern = "(.-):%s*(.*)$"
httpServer.parseRequest = function(client)
  local request = {
    headers = {}
  }
  -- method
  local requestMethod = httpServer.receive(client, "*l")
  request.rawMethod = requestMethod
  request.method, request.url, request.protocol = requestMethod:match(requestMethodPattern) -- GET /images/logo.png HTTP/1.1 -> GET | /images/logo.png | HTTP/1.1
  request.parsedURL = httpServer.parseURL(request.url)
  -- headers
  while true do
    local data = httpServer.receive(client, "*l")
    if not data or data == "" then
      break
    end
    local header, value = data:match(requestHeaderPattern) -- Content-Type: text/html
    request.headers[header] = value --todo, support multiple values into table: "Keep-Alive: timeout=99,max=99"
  end
  if request.headers["Content-Length"] then
    local length = tonumber(request.headers["Content-Length"])
    if length then
      request.body = httpServer.receive(client, length)
    end
  end
  -- body
  if request.body then
    request.parsedBody = httpServer.parseBody(request.body)
  end
  --
  return request
end

local pathPattern = "/([^%?]*)%??(.*)"
local variablePattern = "([^?^&]-)=([^&^#]*)"
httpServer.parseURL = function(url)
  local parsedURL = {
    values = {}
  }
  local postfix
  parsedURL.path, postfix = url:match(pathPattern)
  if parsedURL.path == "/" or parsedURL.path == "" then
    parsedURL.path = "index"
  end
  for variable, value in postfix:gmatch(variablePattern) do
    parsedURL.values[variable] = value
  end
  return parsedURL
end

local bodyPattern = "([^&]-)=([^&^#]*)"
httpServer.parseBody = function(body)
  local parsedBody = {}
  for key, value in body:gmatch(bodyPattern) do
    parsedBody[helper.restoreText(key)] = helper.restoreText(value)
  end
  return parsedBody
end

return httpServer
