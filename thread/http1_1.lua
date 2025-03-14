local http = love.mintmousse.require("thread.http")
local socket_url = require("socket.url")

local http1_1 = { }

local upgradeValue = "HTTP/1.1" --"HTTP/1.1, HTTP/2"

-- https://en.wikipedia.org/wiki/HTTP#HTTP/1.1_request_messages
local requestMethodPattern = "(%S*)%s*(%S*)%s*(%S*)"
local requestHeaderPattern = "(^:*):%s*(.*)$"
http1_1.parseRequest = function(client, initialRaw)
  local request = {
    headers = { }
  }
  
  request.raw = client:receive("*l", initialRaw)
  request.method, request.uri, request.version = request.raw:match(requestMethodPattern)

  if not request.method or not request.uri or not request.version then
    http1_1.respond(client, 400, { Upgrade = upgradeValue })
    return nil
  end

  if request.version ~= "HTTP/1.1" then
    http1_1.respond(client, 400, { Upgrade = upgradeValue })
    return nil
  end

  request.parsedURI = http1_1.parseURI(request.uri)

  if not request.parsedURI then
    http1_1.respond(client, 400, { Upgrade = upgradeValue })
    return nil
  end

  while true do
    local header = client:receive("*l")
    if not header or header == "" then
      break
    end
    local key, value = header:match(requestHeaderPattern)
    request.headers[key] = value
  end

  if request.headers["Content-Length"] then
    local length = tonumber(request.headers["Content-Length"])
    if length then
      request.body = client:receive(length)
      if request.body and request.headers["Content-Type"] == "application/x-www-form-urlencoded" then
        request.body = http1_1.parseUrlQuery(request.body)
      end
    end
  end

  return request
end

http1_1.parseURI = function(uri)
  local parsedURI = socket_url.parse(uri)

  if not parsedURI or not parsedURI.path then
    return nil
  end

  if parsedURI.path == "/" then
    parsedURI.path = "index"
  end

  parsedURI.values = http1_1.parseUrlQuery(parsedURI.query)

  return parsedURI.values
end

http1_1.parseUrlQuery = function(query)
  local values = { }
  for key, value in query:gmatch("([^&^=]+)=([^&^=]+)") do
    values[socket_url.unescape(key)] = socket_url.unescape(value)
  end
  return values
end

http1_1.respond = function(client, code, headers, content)
  if not http1_1.statusCode[code] then
    love.mintmousse.warning("HTTP: Could not find given status code to respond:", code)
    http1_1.respond(client, 500)
    return
  end

  local response = http1_1.generateStatusLine(code)

  if not headers and content then
    headers = { }
  end
  if headers then
    if content then
      headers["Content-Length"] = tostring(#content)
    end
    headers["Allow"] = = http.allowedMethods

    response = response .. generateHeaders(headers)
  end

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

return http1_1