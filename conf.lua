--- Configuration for MintMousse Web Console Library.
-- Primarily loaded at startup; runtime changes usually have no effect unless noted.
-- Access via `mintmousse.<NAME>`, e.g. `mintmousse.MAX_HTTP_RECEIVE_SIZE`.

local PATH = (...):match("^(.-)[^%.]+$") or ""
local DIRECTORY_PATH = PATH:gsub("%.", "/")

local mintmousse = {
  -- File paths and locations
  -----------------------------------------------------------------------------------------------------------------
  COMPONENTS_PATHS = { DIRECTORY_PATH .. "components/" }, -- Directory searched for components (later entries override earlier)

  -- File location for primary resources
  DEFAULT_INDEX_HTML = DIRECTORY_PATH .. "thread/index.html",
  DEFAULT_INDEX_JS   = DIRECTORY_PATH .. "thread/index.js",
  DEFAULT_INDEX_CSS  = DIRECTORY_PATH .. "thread/index.css",

  ZIP_MOUNT_LOCATION = ".MintMousse/", -- Directory for mounting archives (e.g. ZIPs with RFG.net icons).
  FAVICON_PATH = "/favicon", -- HTTP endpoint for the icon - this should match 'favicon path' when using RFG.net icons

  -- Network and Server settings
  -----------------------------------------------------------------------------------------------------------------
  SOCKET_BACKLOG = 32,                -- Listen backlog. Max pending connections the OS will queue before refusing new ones.

  MAX_HTTP_RECEIVE_SIZE = 2^16,       -- 65Kb: Max incoming HTTP body size. Rejects larger requests.
  MAX_WEBSOCKET_FRAME_SIZE = 2^19,    -- 512Kb: Max size of a single WebSocket frame.
  MAX_WEBSOCKET_MESSAGE_SIZE = 2^21,  -- 2Mb: Max total size of a fragmented WebSocket message

  CACHE_CONTROL_HEADER = "no-store",  -- Cache-Control header for static assets ("no-store" for dev in library) -- "public, max-age=3600"

  COMPONENT_PARSE_TIMEOUT = 3,        -- Seconds: Max wait for component type parsing. Use preload script to reduce blocking.

  REPLACE_DEFAULT_ERROR_HANDLER = true, -- Replace Love's error handler with MintMousse's (adds logging & cleaned stack traces).

  MAX_PORT_ATTEMPTS = 100,            -- Max sequential port bind attempts before aborting.

  TIMEOUT_HTTP = 30,                  -- Seconds: Idle timeout for HTTP connections (sends 408).
  TIMEOUT_WEBSOCKET = 60,             -- Seconds: Max idle time for WebSocket connections (includes pongs).
  PING_WEBSOCKET = 30,                -- Seconds: Interval to send WebSocket ping frames for heartbeat.

  -- Logging settings
  -----------------------------------------------------------------------------------------------------------------
  LOG_ENABLE_TIMESTAMP = true,        -- Prefix log messages with timestamp
  LOG_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S.%f", -- Timestamp format (supports %f for ms)

  LOG_ENABLE_STREAM_OUT = true,       -- Enable logging to stdout/stderr (mimics print; strips ANSI in files).
  LOG_ENABLE_ERROR = true,            -- Call error() on ERROR logs (halts with traceback).
  LOG_INCLUDE_TRACE = false,          -- Include `file:line` in all log levels (performance cost)

  LOG_WARNINGS_CAUSE_ERRORS = false,  -- Promote WARNINGs to ERRORs (halts if LOG_ENABLE_ERROR == true).
  LOG_WARNINGS_INCLUDE_TRACE = false, -- Include `file:line` in WARNING logs without effecting other levels.

  REPLACE_FUNC_PRINT = true,          -- Replace global print with logger.debug (original available as GLOBAL_print)
                             -- Warning: GLOBAL_print is not thread-safe and may cause interleaved/garbled output in multi-threaded code.

  LOG_CLEAR_UP_TRACEBACK = true,      -- Clean internal MintMousse & Love calls from tracebacks in logs & error handler.

  LOG_BUFFER_SIZE = 2^20,             -- 1Mb: Stdout buffer size. Increase if output garbles; call mintmousse.flushLogs() as needed.

  LOG_MAX_PENDING_LOGS_PER_FLUSH = 512, -- Max number of logs global sinks can process per flush

  -- Thread settings
  -----------------------------------------------------------------------------------------------------------------
  MAX_THREAD_MESSAGES = 100,          -- Max commands processed per MintMousse thread loop.

  THREAD_SLEEP = 1e-4,                -- Seconds: Sleep time between thread loop iterations.

  -- Channel / Event IDs
  -----------------------------------------------------------------------------------------------------------------
  -- Only change these if they conflict with IDs already in use in your project.

  -- Channel
  READONLY_THREAD_LOCATION      = "MintMousseThread",
  THREAD_COMMAND_QUEUE_ID       = "MintMousseCommand",
  READONLY_BUFFER_DICTIONARY_ID = "MintMousseDictionary",
  THREAD_ID_COUNTER             = "MintMousseThreadCounter",
  READONLY_BASIC_TYPES_ID       = "MintMousseComponentTypes",
  LOCK_LOG_BUFFER_FLUSH         = "MintMousseLogBufferFlush",
  LOCK_LOG_BUFFER_ERR           = "MintMousseLogBufferErr",
  LOG_EVENT_CHANNEL             = "MintMousseLogEvents",

  -- Event
  THREAD_RESPONSE_QUEUE_ID      = "MintMousseEvent",

}

-- Setup logging
mintmousse._setupLogging = function()
  local logging = require(PATH .. "logging")
  logging.enableCleanupTraceback(mintmousse.LOG_CLEAR_UP_TRACEBACK)

  local libraryLogger = logging.newLogger("MintMousse", "bright_green")
  local internalLogger
  if isMintMousseThread then      -- Library's own thread
    internalLogger = libraryLogger:extend("Thread", "magenta")
  elseif love.isThread then       -- Library user's thread
    internalLogger = libraryLogger:extend("Worker", "cyan")
  else                            -- Main thread
    internalLogger = libraryLogger:extend("Main", "white")
  end
  mintmousse._logger = internalLogger
  libraryLogger, internalLogger = nil, nil

  mintmousse._loggerComponents = mintmousse._logger:extend("Components")

  require(PATH .. "loggerSinks")

  if mintmousse.REPLACE_FUNC_PRINT then
    GLOBAL_print = print

    local color = "bright_magenta"
    if isMintMousseThread then
      color = "magenta"
    elseif love.isThread then
      color = "cyan"
    end
    local printLogger = logging.newLogger("Print", color)
    local stack = require(PATH .. "logging.stack")

    print = function(...)
      stack.push()
      printLogger:debug(...)
      stack.pop()
    end
  end

  if not love.isThread then
    mintmousse._logger:info("MintMousse Config loaded")
  else
    mintmousse._logger:info("MintMouse Thread loaded")
  end
  mintmousse._setupLogging = nil
end

return mintmousse