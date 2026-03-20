local socket_url = require("socket.url")

local http = require(PATH .. "thread.server.protocol.http")

local loggerHTTP1_1 = http._logger:extend("HTTP1.1")

local http1_1 = { }

http1_1.process = function(client)
  local request = http1_1.parseRequest(client)
  if type(request) == "string" then
    return request
  end

  local code, headers, content = http.processRequest(request, client)
  http1_1.respond(client, code, request.parsedURI.path, headers, content)

  if headers and headers["connection"] and headers["connection"]:match("close") then
    return "close"
  end

  return "keep-alive"
end

-- https://en.wikipedia.org/wiki/HTTP#HTTP/1.1_request_messages
local requestMethodPattern = "(%S*)%s*(%S*)%s*(HTTP/%S*)"
local requestHeaderPattern = "([^:]*):%s*(.*)$"

http1_1.parseRequest = function(client)
  local request = {
    headers = { },
    headerSet = { },
  }

  local err
  request.raw, err = client:receive("*l", love.mintmousse.TIMEOUT_HTTP)

  if err == "timeout" then
    return "close"
  end
  if not request.raw then
    return "close"
  end

  if request.raw == "PRI * HTTP/2.0" then
    http1_1.respond(client, 426, request.uri, { upgrade = http.upgradeValue or "HTTP/1.1", connection = "upgrade, close" })
    return "close"
  end

  request.method, request.uri, request.version = request.raw:match(requestMethodPattern)

  request.version = type(request.version) == "string" and request.version:upper() or nil

  if not request.method or not request.uri or not request.version then
    http1_1.respond(client, 400, request.uri, { upgrade = http.upgradeValue or "HTTP/1.1", connection = "upgrade, close" })
    return "close"
  end

  if request.version ~= "HTTP/1.1" then
    http1_1.respond(client, 426, request.uri, { upgrade = http.upgradeValue or "HTTP/1.1", connection = "upgrade, close" })
    return "close"
  end

  request.parsedURI = http1_1.parseURI(request.uri)

  if not request.parsedURI then
    http1_1.respond(client, 400, request.uri, { upgrade = http.upgradeValue or "HTTP/1.1", connection = "upgrade, close" })
    return "close"
  end

  while true do
    local header = client:receive("*l")
    if not header or header == "" then
      break
    end
    local key, value = header:match(requestHeaderPattern)
    if key and value then
      local lowerKey = key:lower()
      request.headers[lowerKey], request.headerSet[lowerKey] = { }, { }
      for v in value:gmatch("([^,]+)") do
        local trimmedValue = v:gsub("^%s*", ""):gsub("%s*$", "")
        if lowerKey ~= "sec-websocket-key" then
          trimmedValue = trimmedValue:lower()
        end
        table.insert(request.headers[lowerKey], trimmedValue)
        request.headerSet[lowerKey][trimmedValue] = true
      end
    end
  end

  if request.headers["content-length"] then
    local length = tonumber(request.headers["content-length"][1])
    if length and length > 0 then
      if length > love.mintmousse.MAX_HTTP_RECEIVE_SIZE then
        loggerHTTP1_1:info("Client sent body that exceeded limit. Sent:", length, ". Limit:", love.mintmousse.MAX_HTTP_RECEIVE_SIZE)
        http1_1.respond(client, 413, request.parsedURI.path, { connection = "close" })
        return "close"
      end

      request.body = client:receive(length)
      if request.body and request.body ~= "" and request.headerSet["content-type"] and request.headerSet["content-type"]["application/x-www-form-urlencoded"] then
        request.body = http1_1.parseUrlQuery(request.body)
      end
    elseif not length or length < 0 then
      http1_1.respond(client, 400, request.parsedURI.path, { connection = "close" })
      return "close"
    end
  elseif request.method ~= "GET" then
    http1_1.respond(client, 411, request.parsedURI.path)
    return "open"
  end

  return request
end

http1_1.parseURI = function(uri)
  local parsedURI = socket_url.parse(uri)

  if not parsedURI or not parsedURI.path then
    return nil
  end

  if parsedURI.path == "/" then
    parsedURI.path = "/index"
  end

  parsedURI.values = http1_1.parseUrlQuery(parsedURI.query)

  return parsedURI
end

http1_1.parseUrlQuery = function(query)
  local values = { }
  if not query then
    return values
  end
  for key, value in query:gmatch("([^&^=]+)=([^&^=]+)") do
    values[socket_url.unescape(key)] = socket_url.unescape(value)
  end
  return values
end

http1_1.respond = function(client, code, uri, headers, content)
  if not http.statusCode then
    loggerHTTP1_1:warning("Could not find given status code to respond. Tell a programmer:", code)
    http1_1.respond(client, 500, uri)
    return
  end
  
  local response = http1_1.generateStatusLine(code)

  headers = headers or { }
  if not headers["connection"] then
    headers["connection"] = "keep-alive"
  end

  if uri and code ~= 101 then
    headers["allow"] = http.getAllowedMethods(uri)
  end

  if content then
    headers["content-length"] = tostring(#content)
  elseif code ~= 101 then
    headers["content-length"] = "0"
  end

  headers["date"] = http.getDate()

  response = response .. http1_1.generateHeaders(headers)

  if content then
    response = response .. content
  end

  client:send(response)
end

http1_1.generateStatusLine = function(code)
  return ("HTTP/1.1 %d %s\r\n"):format(code, http.statusCode[code])
end

http1_1.generateHeaders = function(headers)
  local headerLines = ""
  for key, value in pairs(headers) do
    headerLines = ("%s%s: %s\r\n"):format(headerLines, key, value)
  end
  return headerLines .. "\r\n"
end

http1_1.close = function(client, reason)
  if client.client then
    if reason == "timeout" then
      pcall(http1_1.respond, client, 408, "/", { connection = "close" })
    end
    client.client:close()
    client.client = nil
  end
end

return http1_1