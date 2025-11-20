local setupWindowsConsole = function()
  local windowsAPI = love.mintmousse._require("logger.ANSI.windowsSetup")
  if not windowsAPI then
    return false
  end

  local windowsVersion = windowsAPI.getMajorVersion()
  if type(windowsVersion) ~= "number" or windowsVersion < 10 then
    return false
  end

  local result = windowsAPI.enableVirtualTerminal()
  if not result then
    return false
  end

  return true
end

local ANSI = { }
ANSI.isANSISupported = true
if jit and jit.os == "Windows" then -- love.system may not be loaded; but `jit` is required for MM and must be loaded
  ANSI.isANSISupported = setupWindowsConsole()
elseif not jit and not (jit.os == "Linux" or jit.os == "OSX") then
  -- Assume it is a weird operating system / unknown / JIT not loaded (which is caught later)
  ANSI.isANSISupported = false
end

if not ANSI.isANSISupported then
  ANSI.applyANSI = function(_, text)
    return text
  end
else
  local writer = love.mintmousse._require("logger.ANSI.writer")
  ANSI.applyANSI = writer.applyANSI
end

return ANSI