local PATH = ... .. "."
local dirPATH = PATH:gsub("%.", "/")

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
        colorState = "primary",
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

local consoleSettings = {
  host = "*",
  port = 80,
  backupPort = 0, -- 0 lets system pick as a backup
  whitelist = {"127.0.0.1"}
}

local thread = love.thread.newThread(dirPATH .. "thread.lua")

thread:start(PATH, dirPATH, consoleSettings, settings, "foo", "bar")

love.handlers["bar"] = function(...)
  print(...)
end

return thread
