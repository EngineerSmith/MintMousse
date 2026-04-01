# `mintmousse.cleanupTraceback`
Used to remove unhelpful traces in the traceback. It removes internal Love and MintMousse traces reducing the noise you could see.

Removes internal Love and MintMousse traces from a traceback, leaving only the parts that matter.

This makes error messages much cleaner and easier to read, especially when something goes wrong deep inside your project.

**Before**:
```text
stack traceback:
        [love "boot.lua"]:479: in function <[love "boot.lua"]:475>
        [C]: in function 'error'
        MintMousse/logging/logger.lua:98: in function 'error'
        main.lua:5: in main chunk
        [C]: in function 'require'
        [love "boot.lua"]:444: in function <[love "boot.lua"]:173>
        [C]: in function 'xpcall'
        [love "boot.lua"]:492: in function <[love "boot.lua"]:483>
        [C]: in function 'xpcall'
        [love "boot.lua"]:515: in function <[love "boot.lua"]:470>
```
**After**:
```text
Traceback:
    [C]: in function 'error'
    main.lua:5: in main chunk
```

## Synopsis
```lua
cleanedTrace = mintmousse.cleanupTraceback( trace )
```

## Parameters
`trace` _string_
:   A traceback string, usually obtained from `debug.traceback()`

## Returns
`cleanedTrace` _string_
:   The same traceback with all internal Love and MintMousse traces removed.

## Examples
See MintMousse's implemented `errorhandler` to see it in a `love.errorhandler` situation.
```lua
local trace = debug.traceback()
local cleanedTrace = mintmousse.cleanupTraceback(trace)
print(cleanedTrace)
```

# See Also
- [Logging](index.md)
- [`mintmousse.logUncaughtError`](logUncaughtError.md)