local ANSI = { }
ANSI.isANSISupported = true
if jit and jit.os == "Windows" then -- love.system may not be loaded; but `jit` is required for MM and must be loaded
  local windowsAPI = love.mintmousse._require("logger.ANSI.windowsAPI")
  ANSI.isANSISupported = windowsAPI.setupANSIConsole()
  -- ANSI.isANSISupported = false
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