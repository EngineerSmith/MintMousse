# `mintmousse.wait`
Waits for the thread to rejoin. Note, if [`mintmousse.stop`](stop.md) hasn't been called, it will indefinitely block the main thread.

Can only be called on the main thread.

## Synopsis
```lua
mintmousse.wait()
```

## Parameters
Nothing.

## Returns
Nothing.

## Examples
```lua
mintmousse.wait()

love.quit()
  mintmousse.stop(true)
  -- ...
  mintmousse.wait()
  return
end
```

## See Also
- [Controller](index.md)
- [`mintmousse.stop`](stop.md)