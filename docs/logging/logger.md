logger:extend(name : string, color : string) : logger
logger:info(message...)
logger:warning(message...)
logger:debug(message...)
logger:error(message...)
logger:assert(condition : boolean false, message...)
logger:getAncestry() : table
logger.inspect(tbl : table, level : number)