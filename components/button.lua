local mintmousse = ... -- passed in since this file is loaded with `lfs.load`. Instead of typical require args

-- Can we make this easier? It's hard since custom components would have their own dedicated newLogger;
-- Only way I can think that custom component libraries to add their own "simple" logger would be via globals - not the worst.
local loggerButton = mintmousse._loggerComponents:extend("Button")

local button = { }

-- Ran on the thread of creation
button.onCreate = function(component)

end

return button