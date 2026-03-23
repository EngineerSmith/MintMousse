# `mintmousse.logUncaughtError`
Use within [`love.errorhandler`](https://love2d.org/wiki/love.errorhandler), to make sure all thrown errors are caught and directed into the sinks. See the [`errorhandler` that MintMousse implements](https://github.com/EngineerSmith/MintMousse/blob/main/errorhandler.lua), but TLDR; it's put in place of `error_printer` in the default [`love.errorhandler`](https://love2d.org/wiki/love.errorhandler).

Messages caught using this function will appear as the [log level](level.md) `fatal` indicated the halt to the program.

!!! warning "Error Handler"

    MintMousse by default sets it's own error handler which already implements it. If you override `love.errorhandler` yourself later with your own implementation, you will need to add this function yourself. Otherwise, the logs may appear incomplete at time of crash, or be out of order.

    To disable MintMousse setting it's own error handler, see the config. -- TODO link

## Synopsis
```lua
mintmousse.logUncaughtError( message, tracebackLayer )
```

## Parameters
`message` _string_
:   The reported error message</dd>

`tracebackLayer` _number_ (**0**)
:   Increase to reduce the generated traceback to correctly report the cause of the crash. 'layer' 0 is when it is directly called within `love.errorhandler`.

## Returns
Nothing.

## Examples
```lua
love.errorhandler = function(msg)
  msg = tostring(msg)

  mintmousse.logUncaughtError(msg)
  -- or
  mintmousse.logUncaughtError(msg, 0)
  -- or
  (function()
    mintmousse.logUncaughtError(msg, 1)
  end)()

  -- etc..
end
```
