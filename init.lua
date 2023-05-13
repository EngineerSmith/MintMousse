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
    componentType = "card",
    size = 5,
    body = {
      child = {
        componentType = "progressBar",
        percentage = 50.789,
        label = false,
        percentageLabel = "Hello world"
      }
    }
  }, {
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
      text = "Jay"
    }, {
      componentType = "buttonGroup",
      buttons = {"First", "Second", "Third"},
      theme = {
        colorState = "danger",
        outline = true
      }
    }, {
      componentType = "progressBar",
      percentage = 50.789,
      label = false,
      percentageLabel = "Hello world"
    }, {
      componentType = "accordion",
      alwaysOpen = true,
      items = {{
        title = "#1",
        text = "Hello world"
      }, {
        title = "#2",
        text = "Hello world 2"
      }}
    }}
  }, {
    componentType = "card",
    imgTop = "file.png",
    body = {
      title = "How to win at the game",
      text = "Well... well... well... give up now!\n\tI am on a new line!<p>TEXT</p>",
      subtext = "Oopie whoopie was 5 minutes ago",
      child = {
        componentType = "stackedProgressBar",
        bars = {10, 10, 10, 10, 10, 10, 10},
        label = true
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

renderComponent = function(component, id)
  local componentType = components[component.componentType]
  if not componentType then
    error("Could not find component: " .. tostring(component.componentType))
  end

  component.id = id
  id = id + 1

  if componentType.format then
    local children = componentType.format(component, helper)
    if children then
      id = render(children, id)
    end
  end
  if component.size then
    component.size = helper.limitSize(component.size)
  end
  component.render = lustache:render(componentType.template, component)
  return id
end

render = function(settings, id)
  id = id or 0
  if settings.componentType then
    return renderComponent(settings, id)
  end
  for _, component in ipairs(settings) do
    id = renderComponent(component, id)
  end
  return id
end

render(settings.dashboard)

local htmlPage = lustache:render(love.filesystem.read(dirPATH .. "index.html"), settings)

love.filesystem.write("temp.html", htmlPage)

