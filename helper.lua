local helper = {}

helper.formatImage = function(image)
  if type(image) == "string" then
    if love.filesystem.getInfo(image, "file") then
      local extension = image:match("^.+%.(.+)$"):lower()
      return "data:image/" .. extension .. ";base64," ..
               love.data.encode("string", "base64", love.filesystem.read(image))
    elseif image:find("^data:image/") then
      return image;
    elseif image:find("^.PNG") then
      return "data:image/png;base64," .. love.data.encode("string", "base64", image)
    else
      error(tostring(image) .. " isn't a file, could not be found, or recognised as string of an png")
    end
  end
  if not image:typeOf("ImageData") and image:typeOf("Data") then
    local err, imageData = pcall(love.image.newImageData, image)
    if not err then
      image = imageData
    end
  end
  if image:typeOf("ImageData") then
    return "data:image/png;base64," .. love.data.encode("string", "base64", image:encode("png"))
  end
  error("given image is not a string or image data")
end

local htmlEscapeCharacters = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&quot;",
  ["'"] = "&#39;",
  ["/"] = "&#x2F;"
}

local escapeCharactersFn = function(s)
  return htmlEscapeCharacters[s]
end

helper.formatText = function(str)

  str = str:gsub('[&<>"\'/]', escapeCharactersFn)

  str = str:gsub("\n", "<br>")
  str = str:gsub("\t", "&nbsp;&nbsp;&nbsp;&nbsp;")
  str = str:gsub("  ", "&nbsp;&nbsp;")

  return str
end

local escapeCharactersFn = function(s)
  return string.char(tonumber(s, 16))
end
helper.restoreText = function(str)
  return str:gsub("%+", " "):gsub("[%%%$](..)", escapeCharactersFn)
end

helper.limitSize = function(size)
  return size > 5 and 5 or size < 0 and 1 or size
end

helper.color = {"primary", "secondary", "success", "danger", "warning", "info", "light", "dark", "link"}

helper.getColor = function(num)
  return helper.color[num] or "primary"
end

helper.getFileNameExtension = function(file)
  return file:match("^(.+)%..-$"), file:match("^.+%.(.+)$"):lower()
end

return helper
