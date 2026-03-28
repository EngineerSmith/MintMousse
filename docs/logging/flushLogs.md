# `mintmousse.flushLogs`
Thread-safe function to call flush function callbacks per sink. On the main thread, it also processes [global sinks](addGlobalLogSink.md).

## Synopsis
```lua
mintmousse.flushLogs( forced )
```

## Parameters
`forced` _boolean_ (**false**)
:   Used to override the thread lock and immediately flush the buffer. This parameter is used internally during a crash state, and not recommended to be used in practice.

## Returns
Nothing.

## Examples
```lua
mintmousse.flushLogs()

mintmousse.flushLogs(true)
```

## See Also
- [Logging](index.md)