--- Configuration for MintMousse Web Console Library.
-- These settings are primarily loaded at startup and should not be changed at runtime.
-- Expect runtime changes to not affect threads unless explicitly noted in the documentation.
-- Access these options via `love.mintmousse.<NAME>`, e.g. `love.mintmousse.SUBSCRIPTION_MAX_QUEUE_READ`.
local PATH = (...):match("^(.-)[^%.]+$") or ""
local DIRECTORY_PATH = PATH:gsub("%.", "/")

local mintmousse = {
  -- File paths and locations
  -----------------------------------------------------------------------------------------------------------------
  -- Component paths. Later directories in the list will override same-named components from earlier directories.
  COMPONENTS_PATHS = { DIRECTORY_PATH .. "components/" },
  -- Default paths for base web page files.
  DEFAULT_INDEX_HTML = DIRECTORY_PATH .. "thread/index.html", -- Location of the webpage's HTML file.
  DEFAULT_INDEX_JS   = DIRECTORY_PATH .. "thread/index.js",     -- Location of the webpage's JavaScript file.
  DEFAULT_INDEX_CSS  = DIRECTORY_PATH .. "thread/index.css",   -- Location of the webpage's CSS file.

  -- General settings
  -----------------------------------------------------------------------------------------------------------------
  -- Maximum allowed size (in bytes) for incoming HTTP request bodies. Requests exceeding this limit will be rejected.
  MAX_DATA_RECEIVE_SIZE = 50000,

  TEMP_MOUNT_LOCATION = ".temp/MintMousse/", -- Directory for temporary zip file mounting.

  -- The Cache-Control HTTP header for static assets.
  -- Use "no-store" for active development. For production, consider using a public cache with a long max-age.
  -- For more information, see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cache-Control
  CACHE_CONTROL_HEADER = "no-store",

  -- The maximum time (seconds) a thread will actively poll and block for the MintMousse thread
  -- to complete mandatory component type parsing. This synchronous wait can be significantly reduced
  -- or eliminated by calling the preload script from your project's conf.lua, giving the
  -- MintMousse thread a background head start.
  COMPONENT_PARSE_TIMEOUT = 3,

  -- If true, set's the error handler to one that contains 
  REPLACE_DEFAULT_ERROR_HANDLER = true,

  -- Logging settings
  -----------------------------------------------------------------------------------------------------------------
  -- If true, prefixes all log messages with a timestamp
  LOG_ENABLE_TIMESTAMP = true,

  -- The format string for the timestamp, based on Lua's os.date() format codes. The non-standard '%f'
  -- placeholder is support for milliseconds, and will be replaced by a 3-digit padding number. (E.g. '042').
  -- There is a performance benefit to having milliseconds at the end of the format.
  LOG_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S.%f",

  -- If true, enable the library's logging sink that writes logs to io.stdout and io.stderr.
  -- The logs will appear on the screen, similar to using the global 'print' function.
  LOG_ENABLE_STREAM_OUT = true,

  -- If true, ERROR level logs will call the global 'error' function, causing the application to
  -- halt and display a traceback. Setting this to false prevents fatal crashes on errors, but may result
  -- in unexpected code flow states.
  LOG_ENABLE_ERROR = true,

  -- If true, include source location information (file and line number) in all levels of logs.
  -- This helps trace where the log was called from, but can have an adverse effect on performance.
  LOG_INCLUDE_TRACE = false,

  -- If true, all WARNING level logs will be promoted to ERRORS, causing the application to halt
  -- and traceback (assuming LOG_ENABLED_ERROR is also true). Useful for strict enforcement.
  LOG_WARNINGS_CAUSE_ERRORS = false,

  -- If true, includes source location information (file and line number) in all WARNING level logs.
  -- This helps trace where the warning was called from.
  LOG_WARNINGS_INCLUDE_TRACE = false,

  -- If true, replaces the global 'print' function with a wrapper that directs output to `logger.debug`.
  -- The original function can still be access via `GLOBAL_print` global variable created by logger.lua
  REPLACE_FUNC_PRINT = true,

  -- If true, MintMousse's traceback cleanup function is applied to tracebacks processed by its internal
  -- logging sink (FATAL level) and the custom `love.errorhandler`. This removes internal library calls and
  -- Love framework noise from the callstack. Note: This does not affect user-added sinks.
  LOG_CLEAR_UP_TRACEBACK = true,

  -- Size (in bytes) for the stdout buffer. Critical for performance (removes I/O latency)
  -- and thread safety (prevents interleaved writes)
  -- WARNING: Overflow triggers an uncontrolled flush, bypassing thread locks.
  -- Increase this size if you experience garbled output, or add more calls to `love.mintmousse.flushLogs`
  LOG_BUFFER_SIZE = 1024 * 1024, -- 1MB

  -- Thread communication settings
  -----------------------------------------------------------------------------------------------------------------
  -- The maximum number of updates to read from the poll queue to prevent blocking behaviour.
  -- This is a runtime-editable (per thread) setting.
  POLL_MAX_READ = 50,

  -- IDs used for love.thread Channels.
  -- Only change these if they conflict with IDs already in use in your project.
  READONLY_THREAD_LOCATION      = "MintMousseThread",
  THREAD_COMMAND_QUEUE_ID       = "MintMousse",
  READONLY_BUFFER_DICTIONARY_ID = "MintMousseDictionary",
  THREAD_COMPONENT_UPDATES_ID   = "MintMousseUpdate_%s", -- Appended with love.mintmousse._threadID
  READONLY_BASIC_TYPES_ID       = "MintMousseComponentTypes",
  LOCK_LOG_BUFFER_FLUSH         = "MintMousseLogBufferFlush",
  LOCK_LOG_BUFFER_ERR           = "MintMousseLogBufferErr",

  -- IDs used for love.event handlers.
  -- Only change these if they conflict with IDs already in use in your project.
  THREAD_RESPONSE_QUEUE_ID      = "MintMousse",

  -- Enums
  -----------------------------------------------------------------------------------------------------------------
  -- Enum for the thread response event handler (THREAD_RESPONSE_QUEUE_ID)
  EVENT_ENUM_JS_EVENT = "MintMousseJSEvent",

  -- Component Fields
  -----------------------------------------------------------------------------------------------------------------
  -- The field name pattern for component event handler.
  COMPONENT_EVENT_FIELD = "onEvent%s", -- Appended with event type, e.g. "Click" -> "onEventClick"
  COMPONENT_EVENT_FIELD_MATCH = "^onEvent(.+)",
}

-- Setup logging
mintmousse._setupLogging = function()
  local logging = require(PATH .. "logging")
  logging.setupBuffer(mintmousse.LOG_BUFFER_SIZE, mintmousse.LOCK_LOG_BUFFER_FLUSH)
  logging.enableCleanupTraceback(mintmousse.LOG_CLEAR_UP_TRACEBACK)

  local libraryLogger = logging.newLogger("MintMousse", "bright_green")
  local internalLogger
  if love.isMintMousseThread then -- Library's own thread
    internalLogger = libraryLogger:extend("Thread", "magenta")
  elseif love.isThread then       -- Library user's thread
    internalLogger = libraryLogger:extend("Worker", "cyan")
  else                            -- Main thread
    internalLogger = libraryLogger:extend("Main", "white")
  end
  mintmousse._logger = internalLogger
  libraryLogger, internalLogger = nil, nil

  require(PATH .. "loggerSinks")

  if mintmousse.REPLACE_FUNC_PRINT then
    -- Snapshot the default print for users who want to use it
    GLOBAL_print = print

    local stack = require(PATH .. "logging.stack")
    local color = "bright_magenta"
    if love.isMintMousseThread then
      color = "magenta"
    elseif love.isThread then
      color = "cyan"
    end
    local printLogger = logging.newLogger("Print", color)
    -- Overrides global print and redirects it to logger.debug;
    -- global print can still be access via `GLOBAL_print`
    print = function(...)
      stack.push()
      printLogger:debug(...)
      stack.pop()
    end
  end

  mintmousse._logger:info("MintMousse Config loaded")
  mintmousse._setupLogging = nil
end

return mintmousse