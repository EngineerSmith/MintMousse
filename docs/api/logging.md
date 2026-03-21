# Logging
Included in MintMousse is a rather powerful and flexible logging system
## Module functions
### mintmousse.newLogger
Creates a new logger instance
#### Synopsis
```lua
mintmousse.newLogger(name, color)
```

#### Parameters
`name` _string_
<dd>Identifier shown in the logs</dd>

`color` _string_
<dd>Colour used to highlight the name in consoles that support colour highlighting</dd>

#### Returns
`logger` _logger_
<dd>A new instance of a logger</dd>

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