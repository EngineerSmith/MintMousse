# Config
As MintMousse is a threaded library, a lot of what can be configured, can only be done before run-time. Therefore it's recommended you edit the file `conf.lua` directly - you can always grab the default from git again if you break something badly.
As MintMousse is a threaded library, almost all configuration must be done before the library is first required. The easiest way is to edit the values directly in the library's `conf.lua` (you can always restore the default version from the GitHub repo if needed.)

!!! warning "Validation"
    None of the values are type-checked or validated at runtime. Incorrect values will cause crashes or unexpected behaviour.

---

## File Paths and Locations

### `mintmousse.COMPONENT_PATHS` 
**Type**: _table_(array of strings)
**Default**: `{ DIRECTORY_PATH .. "components/" }`

Directories to search for components. Later entries override earlier ones on a per-file basis. Use this to add your own components or to include a git repo that provides extra components. See [Components]() to see how to create your own. -- TODO link

### `mintmousse.DEFAULT_INDEX_HTML`
**Type**: _string_
**Default**: `DIRECTORY_PATH .. "thread/index.html"`

Path to the base HTML file severed to connecting clients. This is a [Mustache](https://github.com/Olivine-Labs/lustache) template.

### `mintmousse.DEFAULT_INDEX_JS`
**Type**: _string_
**Default**: `DIRECTORY_PATH .. "thread/index.js"`

Path to the base JavaScript file served to clients. This is a [Mustache](https://github.com/Olivine-Labs/lustache) template.

### `mintmousse.DEFAULT_INDEX_CSS`
**Type**: _string_
**Default**: `DIRECTORY_PATH .. "thread/index.css"`
Path to base CSS file served to clients. This is a [Mustache](https://github.com/Olivine-Labs/lustache) template.

### RFG Icons
These two settings are only relevant if you use [RFG](controller/setIconRFG.md) icons.

#### `mintmousse.ZIP_MOUNT_LOCATION
**Type**: _string_
**Default**: `".MintMousse/"

Directory used by `love.filesystem.mount()` when mounting ZIP archieves that contain RFG icons.

#### `mintmousse.FAVICON_PATH`
**Type**: _string_
**Default**: `"/favicon"`

HTTP endpoint where the favicon assets are served. This must match the "favicon path" you set when generating icons on the RFG website.

---

## Network and Server Settings

### `mintmousse.SOCKET_BACKLOG`
**Type**: _number_
**Default**: `32`

Maximum number of pending connections the OS will queue before refusing new ones.

### `mintmousse.MAX_HTTP_RECEIVE_SIZE`
**Type**: _number_
**Default**: `2^16` (65KB)

The maximum allowed size of an incoming HTTP request body. Larger requests are rejected and the limit is included in the response headers.

### `mintmousse.MAX_WEBSOCKET_FRAME_SIZE`
**Type**: _number_
**Default**: `2^19` (512KB)

Maximum size of a single WebSocket Frame (both incoming and outgoing).

### `mintmousse.MAX_WEBSOCKET_MESSAGE_SIZE`
**Type**: _number_
**Default**: `2^21` (2MB)

Maximum size of a complete WebSocket message (after reassembling fragmented frames).

### `mintmousseCACHE_CONTROL_HEADER`
**Type**: _string_
**Default**: `"no-store"`

Value of the `Cache-Control` header sent for static assets. Change to something like `"public, max-age=3600"` for production.

### `mintmousse.MAX_PORT_ATTEMPTS`
**Type**: _number_
**Default**: `100`

Maximum number of sequential port increments tried when `autoIncrement = true` is passed to [`mintmousse.start`](controller/start.md).

### `mintmousse.TIMEOUT_HTTP`
**Type**: _number_
**Default**: `30`

Idle timeout for HTTP connections. A `408 Request Timeout` is sent if exceeded.

### `mintmousse.TIMEOUT_WEBSOCKET`
**Type**: _number_ (seconds)  
**Default**: `60`

Idle timeout for WebSocket connections (includes the internal heartbeat mechanism).

### `mintmousse.PING_WEBSOCKET`
**Type**: _number_ (seconds)  
**Default**: `30`

Interval between WebSocket ping frames (used for keep-alive).

### `mintmousse.COMPONENT_PARSE_TIMEOUT`
**Type**: _number_ (seconds)
**Default**: `3`

Maximum time to wait for component type parsing. If you see a timeout warning, increase this value or use the preload script.

### `mintmousse.REPLACE_DEFAULT_ERROR_HANDLER`
**Type**: _boolean_
**Default**: `true`

If `true`, MintMousse replaces Love’s default error handler with its own (adds better logging and cleaned-up stack traces).

---

## Logging Settings

### `mintmousse.LOG_ENABLED_TIMESTAMP`
**Type**: _boolean_
**Default**: `true`

Prefix every log with a timestamp.

### `mintmousse.LOG_TIMESTAMP_FORMAT`
**Type**: _string_
**Default**: `"%Y-%m-%d %H:%M:%S.%f"`

Format passed to `os.date`. MintMousse adds the custom `%f` specifier (milliseconds, 3 digits padded). Performance is best when `%f` appears at the very end of the string.

### `mintmousse.LOG_ENABLE_STREAM_OUT`
**Type**: _boolean_
**Default**: `true`

Enable logging to `io.stdout` / `io.stderr` (behaves like the global `print`). Automatically strips ANSI colours when the stream is redirected to a file.

### `mintmousse.LOG_ENABLE_ERROR`
**Type**: _boolean_
**Default**: `true`

When `logger:error()` is called, also call the global `error()` function.

### `mintmousse.LOG_INCLUDE_TRACE`
**Type**: _boolean_
**Default**: `false`

Include debug info (`function@file:line`) in all log message levels. Has a noticeable performance cost with each lookup.

### `mintmousse.LOG_WARNINGS_CAUSE_ERRORS`
**Type**: _boolean_
**Default**: `false`

If `true`, warning logs are promoted to error logs.

### `mintmousse.LOG_WARNINGS_INCLUDE_TRACE`
**Type**: _boolean_
**Default**: `false`

Include trace information on warning logs (does not effect other log levels).

### `mintmousse.REPLACE_FUNC_PRINT`
**Type**: _boolean_
**Default**: `true`

Replaces the global function `print` with `logger:debug`. The original `print` is still available as `GLOBAL_print` (but it isn't considered thread-safe).

### `mintmousse.LOG_CLEAR_UP_TRACEBACK`
**Type**: _boolean_
**Default**: `true`

Clean internal MintMousse and Love calls from the traceback shown by [`MintMousse.logUncaughtError`](logging/logUncaughtError.md). It doesn't effect the public [`MintMousse.cleanupTraceback`](logging/cleanupTraceback.md) function.


### `mintmousse.LOG_BUFFER_SIZE`
**Type**: _number_
**Default**: `2^20` (1MB)

Size of the stdout buffer. Increase if you see garbled/interleaved output, or call [`mintmousse.flushLogs`](logging/flushLogs.md) more often.

### `mintmousse.LOG_MAX_PENDING_LOGS_PER_FLUSH`
**Type**: _number_
**Default**: `512`

Maximum number of logs the global sinks will process in a single call to [`mintmousse.flushLogs`](logging/flushLogs.md) (only runs on the main thread).

---

## MintMousse Thread Settings
You probably won't need to change these unless you have very specific performance requirements.

### `mintmousse.MAX_THREAD_MESSAGES`
**Type**: _number_
**Default**: `100`

Maximum commands the MintMousse thread will process in one loop iteration.

### `mintmousse.THREAD_SLEEP`
**Type**: _number_ (seconds)
**Default**: `1e-4` (0.0001s)

sleep time between thread loop iterations. Increase to reduce CPU usage, decrease if the thread feels sluggish.

---

## Channel / Event IDs
Only change these if they conflict with IDs already used elsewhere in your project.

### Channels

|Channel ID|Description|
|---|---|
|`READONLY_THREAD_LOCATION`|Holds the MintMousse thread Object (read-only)|
|`THREAD_COMMAND_QUEUE_ID`|Queue for commands sent to the MintMousse thread|
|`READONLY_BUFFER_DICTIONARY_ID`|Internal string.buffer dictionary|
|`THREAD_ID_COUNTER`|Counter for assigning unique thread IDs|
|`READONLY_BASIC_TYPES_ID`|Parsed component types used by proxy tables|
|`LOCK_LOG_BUFFER_FLUSH`|Mutex lock for stdout buffer|
|`LOCK_LOG_BUFFER_ERR`|Mutex lock for stderr|
|`LOG_EVENT_CHANNEL`|Used to queue global sink logs|

### Events

|Event ID|Description|
|---|---|
|`errBufferLockChannel`|`love.event` used by the MintMousse thread to communicate back to the main thread|

---
