local controller = { }
controller.__index = controller

controller.new = function()
  
end

controller.setSVGFavicon = function(self, icon)
  self.icon = love.mintmousse.require("core.svg_icon")(icon)
end

return controller