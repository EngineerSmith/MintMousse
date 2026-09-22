# (Logger)._stack Push/Pop
A function to alter the traceback position. Shouldn't be needed unless you're working with metafunctions. There are other situations you could use it, but if you're writing good code, you shouldn't need it. Useful if you're writing code for others to point to the correct issue.

!!! warning "Warning"

    Make sure any push call has a matching pop. There are no internal checks for performance reasons. No matching push and pops will result in undefined behaviour.

## Synopsis
```lua
Logger._stackPush()

Logger._stackPop()
```

## Parameters
Nothing.

## Returns
Nothing.

## Examples
```lua
setmetatable({ }, {
  newIndex = function(_, _, _)
    Logger._stackPush()
    Logger:debug("I trace to the caller line!")
    Logger:error("Rather than this unhelpful meta function")
    Logger._stackPop()
  end,
})
```

## See Also
- [Logging](../index.md)
- [Logger](index.md)
- [`(Logger):debug`](debug.md)