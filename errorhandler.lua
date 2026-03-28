-- Provides a custom, replacement implementation of love.errorhandler.
-- This handler is based on Love's default logic, copied from 'callbacks.lua' 
-- at commit hash 5670df1 from December 2025 (love12-unreleased).
--
-- The goal for this error handler was to inject MintMousse without changing the default
-- function and it's behaviour. There are many ways to improve this error handler.
--
-- The key modification is the injection of MintMousse logging to ensure all uncaught
-- runtime exceptions (e.g., nil-calls) are captured and processed by the MintMousse
-- sink system (e.g., sent to a file or network) before the crash screen is drawn.
--
-- There is a 2nd modification, which is optional, to clean up the traceback by removing
-- internal or irrelevant entries from the traceback displayed on the error screen
--
-- Beyond that are more modifications for handling quitting the MintMousse thread, and flushing logs
--
local PATH = (...):match("^(.-)%.[^%.]+$") or ""

local utf8 = require("utf8")

local function error_printer(msg, layer)
  (GLOBAL_print or print)((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

local errorhandler = function(msg)
  msg = tostring(msg)

---- MintMousse Logging Injection ----
  local success, mintmousse = pcall(require, PATH)
  if success then
    -- We call logUncaughtError() to ensure this runtime exception (which bypassed logger:error())
    -- is captured and directed to all configured sinks (like file or network output).
    -- This function also captures traceback.
    mintmousse.logUncaughtError(msg, 0)
  else
    mintmousse = nil
    error_printer(msg, 2)
  end
----                              ----

  if not love.window or not love.graphics or not love.event then
    return
  end

  if not love.graphics.isCreated() or not love.window.isOpen() then
    local success, status = pcall(love.window.setMode, 800, 600)
    if not success or not status then
      return
    end
  end

  -- Reset state.
  if love.mouse then
    love.mouse.setVisible(true)
    love.mouse.setGrabbed(false)
    love.mouse.setRelativeMode(false)
    if love.mouse.isCursorSupported() then
      love.mouse.setCursor()
    end
  end
  if love.joystick then
    -- Stop all joystick vibrations.
    for i,v in ipairs(love.joystick.getJoysticks()) do
      v:setVibration()
    end
  end
  if love.audio then love.audio.stop() end

  love.graphics.reset()
  love.graphics.setFont(love.graphics.newFont(15))

  love.graphics.setColor(1, 1, 1)

  local trace = debug.traceback()
---- MintMousse OPTIONAL ----
  if mintmousse then
    trace = mintmousse.cleanupTraceback(trace)
  end
----          ----

  love.graphics.origin()

  local sanitizedmsg = {}
  for char in msg:gmatch(utf8.charpattern) do
    table.insert(sanitizedmsg, char)
  end
  sanitizedmsg = table.concat(sanitizedmsg)

  local err = {}

  table.insert(err, "Error\n")
  table.insert(err, sanitizedmsg)

  if #sanitizedmsg ~= #msg then
    table.insert(err, "Invalid UTF-8 string in error message.")
  end

  table.insert(err, "\n")

  for l in trace:gmatch("([^\n]+)") do
    if not l:match("boot.lua") then
      l = l:gsub("stack traceback:", "Traceback\n")
      table.insert(err, l)
    end
  end

  local p = table.concat(err, "\n")

  p = p:gsub("\t", "")
  p = p:gsub("%[string \"(.-)\"%]", "%1")

  local function draw()
    if not love.graphics.isActive() then return end
    local pos = 70
    love.graphics.clear(89/255, 157/255, 220/255)
    love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
    love.graphics.present()
  end

  local fullErrorText = p
  local function copyToClipboard()
    if not love.system then return end
    love.system.setClipboardText(fullErrorText)
    p = p .. "\nCopied to clipboard!"
  end

  if love.system then
    p = p .. "\n\nPress Ctrl+C or tap to copy this error"
  end

  local wait
  if mintmousse then
    mintmousse.stop(true) -- We wait at quit, so it stops in the background than freezing the errorhandler up
    wait = mintmousse.wait -- Wait for thread to rejoin, called later in the loop below
  end

  return function()
    if mintmousse and mintmousse.flushLogs then
      mintmousse.flushLogs() -- Continues to flush logs
    end

    love.event.pump(0.1)

    for e, a, b, c in love.event.poll() do
      if e == "quit" then
        if wait then wait() end
        return a or 1, b
      elseif e == "keypressed" and a == "escape" then
        if wait then wait() end
        return 1
      elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
        copyToClipboard()
      elseif e == "touchpressed" then
        local name = love.window.getTitle()
        if #name == 0 or name == "Untitled" then name = "Game" end
        local buttons = {"OK", "Cancel"}
        if love.system then
          buttons[3] = "Copy to clipboard"
        end
        local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
        if pressed == 1 then
          if wait then wait() end
          return 1
        elseif pressed == 3 then
          copyToClipboard()
        end
      end
    end

    draw()

    if love.timer then
      love.timer.sleep(0.001)
    end
  end

end

return errorhandler