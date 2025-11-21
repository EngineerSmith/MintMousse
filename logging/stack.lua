local stack = {
-- Used to dynamically change the depth required to find the stack trace information (caller file/line).
  frameOffset = 0,
}

--- Increases the stack frame offset.
-- Must be called before making an internal logging call from a wrapper function
-- to ensure the stack trace points to the original user/caller code.
stack.push = function()
  stack.frameOffset = stack.frameOffset + 1
end

--- Decreases the stack frame offset.
-- Must be called immediately after the logging operation completes to reset the depth.
stack.pop = function()
  stack.frameOffset = stack.frameOffset - 1
end

stack.getDebugInfo = function()
  stack.push()
  local debugInfo
  local info = debug.getinfo(1 + stack.frameOffset, "nSl")
  if info then
    if not info.name and info.what == "C" then
      info.name = "CFunc" -- if C function is anonymous
    elseif info.what == "main" then
      info.name = nil -- file/chunk scope
    end

    if info.short_src then
      debugInfo = (info.name and info.name .. "@" or "") .. info.short_src .. (info.currentline and "#" .. info.currentline or "")
    else
      debugInfo = info.name or "UNKNOWN"
    end
  end
  stack.pop()
  return debugInfo
end

return stack