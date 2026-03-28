# `mintmousse.stop`
Stop and waits for the MintMousse thread to rejoin.

Can only be called on the main thread.

## Synopsis
```lua
mintmousse.stop( noWait )
```

## Parameters
`noWait` _boolean_ (**false**)
:   If we shouldn't wait for the thread to rejoin, and just send the quit command.

    If you choose not to wait, you can wait later by calling [`mintmousse.wait`](wait.md)

## Returns
Nothing.

## Examples
```lua
mintmousse.stop()

mintmousse.stop(true)
```

## See Also
- [Controller](index.md)
- [`mintmousse.wait`](wait.md)