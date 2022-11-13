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
local view_model_main_frame = class()

function view_model_main_frame:ctor(view)
  self.model = include("includes/modules/model/main_frame.lua")
  self.view = view
end

function view_model_main_frame:show_interface()
  gui.EnableScreenClicker(true)
end


return view_model_main_frame.new