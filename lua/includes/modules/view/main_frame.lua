function class(super)
  local obj = {}
  obj.__index = obj
  setmetatable(obj, super)

  function obj.new(...)
      local instance = setmetatable({}, obj)
      if instance.ctor then
          instance:ctor(...)
      end
      return instance
  end

  return obj
end


require("delegate")
local view_main_frame = class()


function view_main_frame:ctor()
  self.viewmodel = include("includes/modules/viewmodel/main_frame.lua")(self)

  self.derma = {}
  self.derma.main = vgui.Create("DgMPlayerFrame")

  -- self.derma.top = vgui.Create("DHBox", self.derma.main)

end

function view_main_frame:show()
  self.derma.main:SetVisible(true)
  self.viewmodel:show_interface()
end

function view_main_frame:get_panel()
  return self.derma.main
end


return view_main_frame.new()