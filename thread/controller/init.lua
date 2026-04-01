require(PATH .. "thread.controller.notification")
require(PATH .. "thread.controller.server")
require(PATH .. "thread.controller.store")
require(PATH .. "thread.controller.icon")

-- Set Defaults
local signal = require(PATH .. "thread.signal")
signal.emit("setTitle", { title = "MintMousse" })
signal.emit("setSchemaIcon", { icon = { }})