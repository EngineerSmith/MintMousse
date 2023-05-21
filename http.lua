-- https://en.wikipedia.org/wiki/HTTP#HTTP/1.1_response_messages
return {
  ["200"] = "HTTP/1.1 200 OK\r\n\r\n",
  ["200header"] = "HTTP/1.1 200 OK\r\n",
  ["204"] = "HTTP/1.1 202 Accepted\r\n\r\n",
  ["204"] = "HTTP/1.1 204 No Content\r\n\r\n",
  ["404"] = "HTTP/1.1 404 Not Found\r\n\r\n",
  ["405"] = "HTTP/1.1 405 Method Not Allowed\r\n\r\n",
  ["422"] = "HTTP/1.1 422 Unprocessable Entity\r\n\r\n",
  ["500"] = "HTTP/1.1 500 Internal Server Error\r\n\r\n"
}
