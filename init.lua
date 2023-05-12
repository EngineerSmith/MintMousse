local PATH = ... .. "."
local dirPATH = PATH:gsub("%.", "/")

local lustache = require(PATH .. "libs.lustache")
local helper = require(PATH .. "helper")

local componentPath = dirPATH .. "/components"

local components = {}
for _, item in ipairs(love.filesystem.getDirectoryItems(componentPath)) do
  local path = componentPath .. "/" .. item
  if love.filesystem.getInfo(path, "file") then
    local name, extension = item:match("^(.+)%..-$"), item:match("^.+%.(.+)$"):lower()
    if extension == "html" then
      if not components[name] then
        components[name] = {}
      end
      components[name].template = love.filesystem.read(path)
    elseif extension == "lua" then
      if not components[name] then
        components[name] = {}
      end
      components[name].format = require((componentPath .. "." .. name):gsub("[\\/]", "."))
    end
  else
    print(item, "is not a file")
  end
end

local settings = {
  title = "MintMousse",
  dashboard = {{
    componentType = "list",
    title = "Players",
    items = {"James Boo", "Steve", "Lily", "Kate", "Jay"},
    size = 3
  }, {
    componentType = "list",
    title = "Players",
    items = {"James Boo", "Steve", "Lily", "Kate", "Jay"},
    size = 2
  }, {
    componentType = "list",
    title = "Players",
    items = {"James Boo", "Steve", "Lily", "Kate", "Jay"}
  }, {
    componentType = "list",
    title = "Players",
    items = {"James Boo", "Steve", "Lily", "Kate", "Jay"}
  }, {
    componentType = "list",
    title = "Players",
    items = {"James Boo", "Steve", "Lily", "Kate", {
      componentType = "button",
      text = "Jay",
    }}
  }, {
    componentType = "card",
    imgTop = "file.jpg",
    body = {
      title = "How to win at the game",
      text = "Well... well... well... give up now!\n\tI am on a new line!<p>TEXT</p>",
      subtext = "Oopie whoopie was 5 minutes ago",
      child = {
        componentType = "button",
        text = "Press me",
      }
    },
    size = 2
  }},
  tabs = {{
    name = "Chat"
  }, {
    name = "Logs"
  }}
}

local renderComponent
local render

renderComponent = function(component)
  local componentType = components[component.componentType]
    if not componentType then
      error("Could not find component: " .. tostring(component.componentType))
    end
    if componentType.format then
      local children = componentType.format(component, helper)
      if children then
        render(children)
      end
    end
    if component.size then
      component.size = helper.limitSize(component.size)
    end
    component.render = lustache:render(componentType.template, component)
end

render = function(settings)
  if settings.componentType then
    renderComponent(settings)
    return
  end
  for _, component in ipairs(settings) do
    renderComponent(component)
  end
end

render(settings.dashboard)

local htmlPage = lustache:render(love.filesystem.read(dirPATH .. "index.html"), settings)

love.filesystem.write("temp.html", htmlPage)

