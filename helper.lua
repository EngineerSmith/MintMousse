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

local html_escape_characters = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&quot;",
  ["'"] = "&#39;",
  ["/"] = "&#x2F;"
}
local html_escape_charactersFn = function(s)
  return html_escape_characters[s]
end

helper.formatText = function(str)

  str = str:gsub('[&<>"\'/]', html_escape_charactersFn)

  str = str:gsub("\n", "<br>")
  str = str:gsub("\t", "    ")

  return str
end

return helper
