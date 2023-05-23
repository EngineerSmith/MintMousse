local helper = {}

helper.formatImage = function(image)
  if type(image) == "string" then
    if love.filesystem.getInfo(image, "file") then
      local extension = image:match("^.+%.(.+)$"):lower()
      return extension .. ";base64," .. love.data.encode("string", "base64", love.filesystem.read(image))
    else
      error(tostring(image) .. " isn't a file, or could not be found") --todo assume it's already encoded png?
    end
  end
  if image:typeOf("ImageData") then
    return "png;base64," .. love.data.encode("string", "base64", image:encode("png"))
  end
  error("given image is not a string or image data")
end

local htmlEscapeCharacters = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&quot;",
  ["'"] = "&#39;",
  ["/"] = "&#x2F;",
  ["#"] = "%23",
}

local escapeCharactersFn = function(s)
  return htmlEscapeCharacters[s]
end

helper.formatText = function(str)

  str = str:gsub('[&<>"\'/#]', escapeCharactersFn)

  str = str:gsub("\n", "<br>")
  str = str:gsub("\t", "&nbsp;&nbsp;&nbsp;&nbsp;")
  str = str:gsub("  ", "&nbsp;&nbsp;")

  return str
end

local escapeCharactersFn = function(s)
  return string.char(tonumber(s, 16))
end
helper.unformatText = function(str)
  return str:gsub("%+", " "):gsub("[%%%$](..)", escapeCharactersFn)
end

helper.limitSize = function(size)
  return size > 5 and 5 or size < 0 and 1 or size
end

helper.getColor = function(num)
  if num == 1 then
    return "primary"
  elseif num == 2 then
    return "secondary"
  elseif num == 3 then
    return "success"
  elseif num == 4 then
    return "danger"
  elseif num == 5 then
    return "warning"
  elseif num == 6 then
    return "info"
  elseif num == 7 then
    return "light"
  elseif num == 8 then
    return "dark"
  elseif num == 9 then
    return "link"
  end
  return "primary"
end

return helper
