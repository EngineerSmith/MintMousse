-- https://en.wikipedia.org/wiki/HTTP#HTTP/1.1_response_messages
return {
  ["200"] = "HTTP/1.1 200 OK\r\n",
  ["202"] = "HTTP/1.1 202 Accepted\r\n",
  ["204"] = "HTTP/1.1 204 No Content\r\n",
-- error codes (html page is generated, if header is included below, via the equivalent /httpErrorPages/*.lua file)
  ["404"] = "HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\n\r\n",
  ["405"] = "HTTP/1.1 405 Method Not Allowed\r\n",
  ["408"] = "HTTP/1.1 408 Request Timeout\r\n",
  ["422"] = "HTTP/1.1 422 Unprocessable Entity\r\n",
  ["500"] = "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/html\r\n\r\n",
  ["505"] = "HTTP/1.1 505 HTTP Version Not Supported\r\n\r\n",
}
