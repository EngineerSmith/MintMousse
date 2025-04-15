-- Do not change these at run time they won't affect threads! Change the file
  -- They can be accessed at run time via `love.mintmousse.<NAME>` e.g. `love.mintmousse.SUBSCRIPTION_MAX_QUEUE_READ`
-- Equally, some ARE editable at runtime for thread-based settings, like the above `love.mintmousse.SUBSCRIPTION_MAX_QUEUE_READ`
  -- See the documentation for details
return function(_, directoryPath)
  return {
    COMPONENTS_PATHS = { directoryPath.."components/" }, -- Where components are stored, later directories override same named components (file by file)
    -- Paths to the base files that make up the webpage
    DEFAULT_INDEX_HTML = directoryPath.."thread/index.html", -- File location of the webpage's HTML
    DEFAULT_INDEX_JS = directoryPath.."thread/index.js", -- File location of the webpage's JavaScript
    DEFAULT_INDEX_CSS = directoryPath.."thread/index.css", -- File location of the webpage's Styling

    MAX_DATA_RECEIVE_SIZE = 50000, -- Maximum body byte limit of incoming HTTP requests 
    TEMP_MOUNT_LOCATION = ".MintMousse/", -- File location for temporary zip mounting
      -- https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cache-Control
    -- CACHE_CONTROL_HEADER = "public, max-age=604800", -- cache-control header response for unchanging static assets
    CACHE_CONTROL_HEADER = "no-store", -- use for active development of the MintMousse library
    SUBSCRIPTION_MAX_QUEUE_READ = 6, -- The maximum number of updates to retrieve from the subscription queue in a single poll, ensuring non-blocking behaviour.

  -- Thread Communication:
    -- You shouldn't need to change these unless they somehow conflict with channels and events you're already using
    READONLY_THREAD_LOCATION = "MintMousseThread", -- id for a love.thread Channel
    THREAD_COMMAND_QUEUE_ID = "MintMousse", -- id for a love.thread Channel
    THREAD_RESPONSE_QUEUE_ID = "MintMousse", -- id for the love.event handler
    READONLY_BUFFER_DICTIONARY_ID = "MintMousseDictionary", -- id for a love.thread Channel
    THREAD_COMPONENT_UPDATES_ID = "MintMousseUpdate_%s", -- id for love.thread Channel (appended with threadID)
    READONLY_BASIC_TYPES_ID = "MintMousseComponentTypes", -- id for love.thread Channel
  }
end