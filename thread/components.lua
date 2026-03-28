-- Performance ideas:
-- Could we move some of the early processing to the main thread while this thread is spinning up?
-- The main thread could just do our main loops; so searching directories, reading files, and then dumping
-- it into a channel for our thread to then pick up and continue with. OR just let the main thread handle 
-- everything. Let it parse all the strings too - but then we would need to pass both the parsed data,
-- and the raw file data to the thread so it can be used by the server to deliver the files. I guess we
-- could even do the lustache/mustache render on the main thread too - which means just sending the finished
-- file to the thread for it to be delivered to connected clients.

--[[ Performance gains: Note time is reported by logStats func
Time taken for thread/components.lua
16.64
16.96
16.87
16.85
16.94
17.04
16.84
(16.64 + 16.96 + 16.87 + 16.85 + 16.94 + 17.04 + 16.84)/7 = 16.877ms

Time taken after adding preferred JS/CSS, thread/components.lua
16.38
16.27
16.32
16.21
16.19
16.17
16.33
(16.38 + 16.27 + 16.32 + 16.21 + 16.19 + 16.17 + 16.33) / 7 = 16.267ms

Time taken after adding `sub(1,1) == '_'` and dropped one of the arrow func gmatches
11.54
11.52
11.37
11.34
11.36
11.74
11.40
(11.54 + 11.52 + 11.37 + 11.34 + 11.36 + 11.74 + 11.40) / 7 = 11.467ms
]]

-- TODO replace `name` with `.typeName` field we extract from the files
-- my only issue with the above TODO is that we decide which directory to load a file if it can be found in a different one
-- So while it is true that we should be using `.typeName` than the file name to recognise the actual name of the component
-- This breaks when we have the file name system - so while we have moved away more from the file name
-- We can't easily break it without parsing every single JS file we find, and then reason what to load
-- So, perhaps looking at this clash of two systems - type names and multiple-directory support needs more judgement

local lfs = love.filesystem

local codec = require(PATH .. "codec")

local store = require(PATH .. "thread.store")

local loggerComponents = love.mintmousse._loggerComponents

local components = {
  componentTypes = { }
}

local processComponentKey = function(key, componentTypeObject)
  -- Check for core lifecycle functions
  if key == "create" then
    componentTypeObject.hasCreateFunction = true
    return
  elseif key == "insert" then
    componentTypeObject.hasInsertFunction = true
    return
  elseif key == "remove" then
    componentTypeObject.hasRemoveFunction = true
    return
  elseif key == "remove_child" then
    componentTypeObject.hasRemoveChildFunction = true
    return
  end

  if key:sub(1, 1) == "_" then
    return -- skip private methods
  end
  
  -- Extract variable/event names based on prefix
  local prop = key:match("^update_child_(.+)")
  if prop then
    componentTypeObject.childUpdates[prop] = true
    return
  end

  local prop = key:match("^update_(.+)")
  if prop then
    if componentTypeObject.pushes[prop] then
      loggerComponents:warning(componentTypeObject.typeName or componentTypeObject.name, ": Detected duel update_" .. tostring(prop) .. " and push_" .. tostring(prop)..". Prioritizing push, ignoring update.")
      return
    end
    componentTypeObject.updates[prop] = true
    return
  end

  local prop = key:match("^event_(.+)")
  if prop then
    prop = prop:gsub("^%l", string.upper)
    componentTypeObject.events[prop] = true
    return
  end

  local prop = key:match("^push_(.+)")
  if prop then
    if componentTypeObject.updates[prop] then
      loggerComponents:warning(componentTypeObject.typeName or componentTypeObject.name, ": Detected duel update_" .. tostring(prop) .. " and push_" .. tostring(prop)..". Prioritizing push, ignoring update.")
      componentTypeObject.updates[prop] = nil
    end
    componentTypeObject.pushes[prop] = true
    return
  end
end

local extractEventPayload = function(script, componentTypeObject)
  componentTypeObject.eventPayload = componentTypeObject.eventPayload or { }

  for rawEvent, allowedStr in script:gmatch("%s*eventPayload_([%w_]+)%s*:%s*[\"']([^\"']+)[\"']") do
    local eventName = rawEvent:gsub("^%l", string.upper)
    componentTypeObject.eventPayload[eventName] = { }

    for field in allowedStr:gmatch("([^,]+)") do
      local trimmed = field:match("^s*(.-)%s*$")
      if trimmed and trimmed ~= "" then
        componentTypeObject.eventPayload[eventName][trimmed] = true
      end
    end
  end
end

local extractComponentMetadata = function(script, componentTypeObject)
  local typeName = script:match('typeName%s*:%s*["\'`]([^"\'`]+)["\'`]')
  if typeName then
    componentTypeObject.typeName = typeName
  end

  -- Find functions| `keyName: function(...)`
  for key in script:gmatch("%s*([%w_]+)%s*:%s*function%s*%([^%)]*%)") do
    processComponentKey(key, componentTypeObject)
  end

  -- Find Arrow functions| `keyName: (...) =>`
  for key in script:gmatch("%s*([%w_]+)%s*:%s*%([^%)]*%)%s*=>") do
    processComponentKey(key, componentTypeObject)
  end

-- This was dropped for performance: Removing this; saved 4.8ms of time
-- Re-enable if functions aren't being picked up.
  -- Find Arrow functions without parens| `keyName: payload =>`
  -- for key in script:gmatch("%s*([%w_]+)%s*:%s*[%w_]+%s*=>") do
  --   processComponentKey(key, componentTypeObject)
  -- end

  extractEventPayload(script, componentTypeObject)
end

components.init = function()
  local start = love.timer.getTime()

  local preferredJS  = { }
  local preferredCSS = { }

  for _, directory in ipairs(love.mintmousse.COMPONENTS_PATHS) do
    directory = directory:gsub("\\", "/")
    if not directory:find("/$") then directory = directory .. "/" end

    local directoryComponentTypes = components.parseComponentTypes(directory, preferredJS, preferredCSS)
    if directoryComponentTypes then
      for _, directoryComponentType in ipairs(directoryComponentTypes) do
        if directoryComponentType.name ~= "unknown" then
          local componentType = components.componentTypes[directoryComponentType.name]
          if not componentType then
            components.componentTypes[directoryComponentType.name] = {
              directories = { directory },
              hasComponentLogic = directoryComponentType.hasComponentLogic,
            }
          else
            table.insert(componentType.directories, directory)
            componentType.hasComponentLogic = componentType.hasComponentLogic or directoryComponentType.hasComponentLogic
          end
        else
          loggerComponents:warning("Found a component type named 'unknown'. This is a protected keyword within MintMousse. Directory:", directory)
        end
      end
    end
  end

  local scripts = components.parseComponentsJavascript(components.componentTypes, preferredJS)

  local channel = love.thread.getChannel(love.mintmousse.READONLY_BASIC_TYPES_ID)
  channel:performAtomic(function()
    channel:clear()
    channel:push(codec.encode(components.componentTypes))
  end)
  components.logStats(components.componentTypes, love.timer.getTime() - start)

  local styles = components.parseComponentsStyling(components.componentTypes, preferredCSS)

  store.registerComponentTypes(components.componentTypes, scripts, styles)
end

components.parseComponentTypes = function(directory, preferredJS, preferredCSS)
  local info = lfs.getInfo(directory)
  if info.type ~= "directory" and info.type ~= "symlink" then
    loggerComponents:warning("Given directory does not exist:", directory)
    return
  end

  local componentTypes, lookup = { }, { }

  -- Symlink may not be a directory; but lfs.getDirectoryItems doesn't care and will return an empty table
  for _, item in ipairs(lfs.getDirectoryItems(directory)) do
    if lfs.getInfo(directory .. item, "file") then -- Must be file, not symlink to a file
      local name, extension = item:match("^(.+)%.(.+)$")
      if type(name) == "string" and type(extension) == "string" then
        local name = name:gsub("^(.)", function(c) return c:upper() end, 1) -- component names must be Pascal case
        local extension = extension:lower()
        if not lookup[name] then
          table.insert(componentTypes, {
            name = name,
            hasComponentLogic = (extension == "lua"),
          })
          lookup[name] = #componentTypes
        else
          local componentType = componentTypes[lookup[name]]
          componentType.hasComponentLogic = componentType.hasComponentLogic or (extension == "lua")
        end

        -- Record last seen path
        if extension == "js" then
          preferredJS[name] = directory .. item
        elseif extension == "css" then
          preferredCSS[name] = directory .. item
        end
      end
    end
  end

  return #componentTypes ~= 0 and componentTypes or nil
end

components.parseComponentsJavascript = function(comps, preferredJS)
  local scripts = { }
  for componentTypeName, componentType in pairs(comps) do
    local path = preferredJS[componentTypeName]
    if path then
      local script, errorMessage = lfs.read(path)
      if type(script) ~= "string" then
        loggerComponents:warning("Unable to read JS file:", path, ". Reason:", errorMessage)
      elseif script:find("%S") then
        table.insert(scripts, script)

        componentType.updates      = componentType.updates      or { }
        componentType.childUpdates = componentType.childUpdates or { }
        componentType.events       = componentType.events       or { }
        componentType.eventPayload = componentType.eventPayload or { }
        componentType.pushes       = componentType.pushes       or { }

        extractComponentMetadata(script, componentType)

        if not next(componentType.updates)      then componentType.updates      = nil end
        if not next(componentType.childUpdates) then componentType.childUpdates = nil end
        if not next(componentType.events)       then componentType.events       = nil end
        if not next(componentType.eventPayload) then componentType.eventPayload = nil end
        if not next(componentType.pushes)       then componentType.pushes       = nil end
      else
        loggerComponents:warning("Read JS file:", path, ", but it appears to be empty. Ignoring file!")
      end
    end
  end
  return scripts
end

components.parseComponentsStyling = function(comps, preferredCSS)
  local styles = { }
  for componentTypeName, componentType in pairs(comps) do
    local path = preferredCSS[componentTypeName]
    if path then
      local styling, errorMessage = lfs.read(path)
      if not styling then
        loggerComponents:warning("Unable to read CSS file:", path, ". Reason:", errorMessage)
      else
        table.insert(styles, styling)
      end
    end
  end
  return styles
end

components.logStats = function(comps, duration)
  local count, updatableCount = 0, 0
  for _, componentType in pairs(comps) do
    count = count + 1
    if componentType.updates then
      for _ in pairs(componentType.updates) do
        updatableCount = updatableCount + 1
      end
    end
    if componentType.childUpdates then
      for _ in pairs(componentType.childUpdates) do
        updatableCount = updatableCount + 1
      end
    end
  end
  loggerComponents:info("Found", count, "component types, with a total of", updatableCount, "values that can be updated live.",
                       ("Took %.2fms to load on thread."):format(duration * 1000))
end

return components 