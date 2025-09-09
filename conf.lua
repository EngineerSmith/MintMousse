-- Configuration for MintMousse Web Console Library.
-- These settings are primarily loaded at startup and should not be changed at runtime.
-- Any runtime changes will not affect threads unless specified otherwise in the documentation.
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
    MAX_DATA_RECEIVE_SIZE = 50000, -- Maximum body byte limit of incoming HTTP request bodies.
    TEMP_MOUNT_LOCATION = ".MintMousse/", -- Directory for temporary zip file mounting.

    -- The Cache-Control HTTP header for static assets.
    -- Use "no-store" for active development. For production, consider using a public cache with a long max-age.
    -- For more information, see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cache-Control
    CACHE_CONTROL_HEADER = "no-store",

    -- The maximum number of updates to read from the subscription queue in a single poll.
    -- This is a runtime-editable (per thread) setting to ensure non-blocking behaviour.
    SUBSCRIPTION_MAX_QUEUE_READ = 6,

    -- Thread communication settings
    -----------------------------------------------------------------------------------------------------------------
    -- IDs used for love.thread Channels.
    -- Only change these if they conflict with IDs already in use in your project.
    READONLY_THREAD_LOCATION      = "MintMousseThread",
    THREAD_COMMAND_QUEUE_ID       = "MintMousse",
    READONLY_BUFFER_DICTIONARY_ID = "MintMousseDictionary",
    THREAD_COMPONENT_UPDATES_ID   = "MintMousseUpdate_%s", -- Appended with love.mintmousse.threadID
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
    COMPONENT_EVENT_FIELD_MATCH = "^onEvent(.+)"
  }
end