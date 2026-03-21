# Logging
Included in MintMousse is a rather powerful and flexible logging system. From customising [logger](logger.md) instances to show a link-listed name 

## `mintmousse.newLogger`
Creates a new logger instance

### Synopsis
```lua
mintmousse.newLogger(name, color)
```

### Parameters
`name` _string_
<dd>Identifier shown in the logs</dd>

`color` _[color](color.md)_
<dd>Color used to highlight the name in consoles that support color highlighting</dd>

### Returns
`logger` _[logger](logger.md)_
<dd>A new instance of a logger</dd>

## `mintmousse.flushLogs`
Thread-safe function to flush io buffer for the base implemented logging sink.

### Synopsis
```lua
mintmousse.flushLogs(forced)
```

### Parameters
`forced` _boolean_ (**false**)
<dd>Used to override the thread lock and immediately flush the buffer</dd>

### Returns
Nothing.

---
mintmousse.newLogger(name : string, color : string) : logger
mintmousse.flushLogs(forced : boolean false)
mintmousse.logUncaughtError(message : string, tracebackLayer : number 0)
mintmousse.addLogSink(sink : function)

logger:extend(name : string, color : string) : logger
logger:info(message...)
logger:warning(message...)
logger:debug(message...)
logger:error(message...)
logger:assert(condition : boolean false, message...)
logger:getAncestry() : table
logger.inspect(tbl : table, level : number)


---
Colors:
