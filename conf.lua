-- Configuration for MintMousse Web Console Library.
-- These settings are primarily loaded at startup and should not be changed at runtime.
-- Expect runtime changes to not affect threads unless explicitly noted in the documentation.
-- Access these options via `love.mintmousse.<NAME>`, e.g. `love.mintmousse.SUBSCRIPTION_MAX_QUEUE_READ`.

return function(_, directoryPath)
  return {
    -- File paths and locations
    -----------------------------------------------------------------------------------------------------------------
    -- Component paths. Later directories in the list will override same-named components from earlier directories.
    COMPONENTS_PATHS = { directoryPath .. "components/" },
    -- Default paths for base web page files.
    DEFAULT_INDEX_HTML = directoryPath .. "thread/index.html", -- Location of the webpage's HTML file.
    DEFAULT_INDEX_JS   = directoryPath .. "thread/index.js",     -- Location of the webpage's JavaScript file.
    DEFAULT_INDEX_CSS  = directoryPath .. "thread/index.css",   -- Location of the webpage's CSS file.

    -- General settings
    -----------------------------------------------------------------------------------------------------------------
    -- Maximum allowed size (in bytes) for incoming HTTP request bodies. Requests exceeding this limit will be rejected.
    MAX_DATA_RECEIVE_SIZE = 50000,

    TEMP_MOUNT_LOCATION = ".MintMousse/", -- Directory for temporary zip file mounting.

    -- The Cache-Control HTTP header for static assets.
    -- Use "no-store" for active development. For production, consider using a public cache with a long max-age.
    -- For more information, see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cache-Control
    CACHE_CONTROL_HEADER = "no-store",

    -- The maximum number of updates to read from the subscription queue in a single poll.
    -- This is a runtime-editable (per thread) setting to ensure non-blocking behaviour.
    SUBSCRIPTION_MAX_QUEUE_READ = 6,

    -- The maximum time (seconds) a thread will actively poll and block for the MintMousse thread
    -- to complete mandatory component type parsing. This synchronous wait can be significantly reduced
    -- or eliminated by calling the preload script from your project's conf.lua, giving the
    -- MintMousse thread a background head start.
    COMPONENT_PARSE_TIMEOUT = 3,

    -- Logging settings
    -----------------------------------------------------------------------------------------------------------------
    -- If true, prefixes all log messages with a timestamp
    LOG_ENABLE_TIMESTAMP = true,

    -- The format string for the timestamp, based on Lua's os.date() format codes.
    -- The non-standard '%f' placeholder is supported for milliseconds, and will
    -- be replaced by a 3-digit padding number. (E.g. '042')
    LOG_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S.%f",

    -- If true, enabled the standard sink that calls the global 'print' function for output
    -- (messages sent to the console).
    LOG_ENABLE_PRINT = true,

    -- If true, ERROR level logs will call the global 'error' function, causing the application to
    -- halt and display a traceback. Setting this to false prevents fatal crashes on errors, but may result
    -- in unexpected code flow states.
    LOG_ENABLE_ERROR = true,

    -- If true, all WARNING level logs will be promoted to ERRORS, causing the application to halt
    -- and traceback (assuming LOG_ENABLED_ERROR is also true). Useful for strict enforcement.
    LOG_WARNINGS_CAUSE_ERRORS = false,

    -- If true, replaces the global 'print' function with a wrapper that directs output to `logger.debug`.
    -- The original function can still be access via `GLOBAL_print` global variable created by logger.lua
    REPLACE_FUNC_PRINT = true,

    -- If true, traceback cleanup function is applied to taceback in MintMousse's internal logging sink
    -- and the default errorhandler that MintMousse implements. The function `_cleanUpTraceback` can
    -- still be used elsewhere. The Clean Up function removes internal logging calls, and various love noise from the callstack

    -- If true, MintMousse's traceback cleanup function is applied to tracebacks processed by its internal
    -- logging sink (FATAL level) and the custom `love.errorhandler`. This removes internal library calls and
    -- Love framework noise from the callstack. Note: This does not affect user-added sinks.
    LOG_CLEAR_UP_TRACEBACK = true,

    -- Thread communication settings
    -----------------------------------------------------------------------------------------------------------------
    -- IDs used for love.thread Channels.
    -- Only change these if they conflict with IDs already in use in your project.
    READONLY_THREAD_LOCATION      = "MintMousseThread",
    THREAD_COMMAND_QUEUE_ID       = "MintMousse",
    READONLY_BUFFER_DICTIONARY_ID = "MintMousseDictionary",
    THREAD_COMPONENT_UPDATES_ID   = "MintMousseUpdate_%s", -- Appended with love.mintmousse._threadID
    READONLY_BASIC_TYPES_ID       = "MintMousseComponentTypes",

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
end