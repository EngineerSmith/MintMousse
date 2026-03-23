# `mintmousse.flushLogs`
Thread-safe function to flush io buffer for the base implemented logging sink.

## Synopsis
```lua
mintmousse.flushLogs( forced )
```

## Parameters
`forced` _boolean_ (**false**)
:   Used to override the thread lock and immediately flush the buffer. This parameter is used internally during a crash state, and not recommended to be used.

## Returns
Nothing.

## Examples
```lua
mintmousse.flushLogs()

mintmousse.flushLogs(true)
```
