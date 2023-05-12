local PATH = ... .. "."
local dirPATH = PATH:gsub("%.","/")

local lustache = require(PATH .. "libs.lustache")

local componentPath = dirPATH.."/components"

local components = { }
for _, item in ipairs(love.filesystem.getDirectoryItems(componentPath)) do
  local path = componentPath.."/"..item
  if love.filesystem.getInfo(path, "file") then
    local name = item:match("^(.+)%..-$")
    components[name] = love.filesystem.read(path)
  else
    print(item, "is not a file")
  end
end

local htmlTbl = {
  title = "Console",
  dashboard = {
    {
      componentType = "list",
      title = "Players",
      items = {
        "James Boo", "Steve", "Lily", "Kate", "Jay"
      }, size=3
    },
    {
      componentType = "list",
      title = "Players",
      items = {
        "James Boo", "Steve", "Lily", "Kate", "Jay"
      }, size=2
    },
    {
      componentType = "list",
      title = "Players",
      items = {
        "James Boo", "Steve", "Lily", "Kate", "Jay"
      }
    },
    {
      componentType = "list",
      title = "Players",
      items = {
        "James Boo", "Steve", "Lily", "Kate", "Jay"
      }
    },
    {
      componentType = "list",
      title = "Players",
      items = {
        "James Boo", "Steve", "Lily", "Kate", "Jay"
      }
    },
    {
      componentType = "card",
      --imgTop = "data:image/png;base64,"..love.data.encode("string", "base64", love.image.newImageData("file.jpg"):encode("png")),
      body = {
        title = "How to win at the game",
        text = "Well... well... wel.. give up now!\nI am on a new line!<p>TEXT</p>",
        subtext = "Oopie whoopie"
      }, size = 2
    },
  },
  tabs = {{
    name = "Chat"
  }, {
    name = "Logs"
  }}
}

--todo write helper for images to encode
--todo write helper to convert new line to <br> tag, similar for tab and other escaped characters

for _, component in ipairs(htmlTbl.dashboard) do
  if not components[component.componentType] then
    error("Could not find component: "..tostring(component.componentType))
  end
  component.render = lustache:render(components[component.componentType], component)
end

local htmlPage = lustache:render(love.filesystem.read(dirPATH.."index.html"), htmlTbl)

love.filesystem.write("temp.html", htmlPage)

