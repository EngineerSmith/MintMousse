local PATH = ... .. "."
local dirPATH = PATH:gsub("%.", "/")
require(PATH .. "mintmousse")(PATH, dirPATH)

