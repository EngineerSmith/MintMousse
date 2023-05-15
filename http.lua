-- https://en.wikipedia.org/wiki/HTTP#HTTP/1.1_response_messages
return {
  ["200"] = "HTTP/1.1 200 OK\r\n\r\n",
  ["404"] = "HTTP/1.1 404 Not Found\r\n\r\n",
  ["500"] = "HTTP/1.1 500 Internal Server Error\r\n\r\n"
}
