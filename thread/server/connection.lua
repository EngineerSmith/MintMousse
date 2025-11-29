local PATH = (...):match("^(.*)connection$")
local ROOT = PATH:match("^(.-)thread%.server%.$")

local mintmousse = require(ROOT .. "conf")

local http1_1 = require(ROOT .. "thread.http1_1")
local websocket13 = require(ROOT .. "thread.websocket13")

local loggerConnection = mintmousse._logger:extend("Connection")

local connection = { }

connection.run = function(client, serverEventCallback)
  return coroutine.wrap(function()
    while not client:peek(14) do -- todo add timeout
      coroutine.yield(true)
    end

    if client.buffer and client.buffer:sub(1, 14) == "PRI * HTTP/2.0" then
      client.connection.type = "HTTP/2"
    else
      client.connection.type = "HTTP/1.1"
    end

    while true do
      local status = "keep-alive"
      
      if client.connection.type == "HTTP/1.1" then
        local request = http1_1.parseRequest(client)
        if type(request) ~= "table" then
          status = request
        else
          local code, headers, content = http.processRequest(request)
          http1_1.respond(client, code, request.parsedURI.path, headers, content)
          if headers and headers["connection"] and headers["connection"]:match("close") then
            status = "close"
          end
          if code == 101 then
            if headers["upgrade"] == "websocket" then
              client.connection.type = "WS/" .. headers["sec-websocket-version"]
              if client.connection.type == "WS/13" then
                websocket13.newConnection(client)
              else
                loggerConnection:warning("Unknown websocket version:", client.connection.type)
              end
            else
              loggerConnection:warning("HTTP 101 returned unexpected upgrade; tell a programmer to add connection type. Upgrade: '" .. tostring(headers["upgrade"]) .. "'")
            end
          end
        end
      elseif client.connection.type == "HTTP/2" then
        http1_1.respond(client, 426, nil, { upgrade = "HTTP/1.1", connection = "upgrade, close" })
        status = "close"
      elseif client.connection.type == "WS/13" then
        if client:hasData() then
          local request, errorMessage = websocket13.processRequest(client)
          if not request then
            loggerConnection:warning("WebSocket encountered an error:", errorMessage)
            websocket13.closeConnection(client)
            status = "close"
          else
            if request.type == "close" then
              websocket13.closeConnection(client)
              status = "close"
            elseif request.type == "text/utf8" or request.type == "binary" then
              serverEventCallback(request)
            else
              status = websocket.handleRequest(client, request)
            end
          end
        end
        for _ = 1, 5 do
          local payload = table.remove(client.queue, 1)
          if not payload then
            break
          end
          local opcode = payload.type == "binary" and 0x2 or 0x1
          websocket13.send(client, opcode, payload.payload)
        end
      else -- Unknown state,
        status = "close"
      end

      coroutine.yield(true)

      if status == "close" then
        break
      end
    end
    client:close()
  end)
end

return connection