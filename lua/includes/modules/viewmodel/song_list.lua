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
local view_model_song_list = class()

function view_model_song_list:ctor(view)
  self.model = include("includes/modules/model/song_list.lua")
  self.view = view
end

function view_model_song_list:show_interface()
  gui.EnableScreenClicker(true)
  self.view.derma.songlist:SetVisible(true)
end

function view_model_song_list:populate_song_list()
  local ui_song_list = self.view.derma.songlist
  local song_list = self.model:get_songs()

  ui_song_list:Clear()
  if table.IsEmpty(song_list) then
    ui_song_list:InvalidateLayout(true)
    ui_song_list:InvalidateLayout()
    return
  end

  for _, song in SortedPairsByMemberValue(song_list, "file") do
    ui_song_list:AddLine(song.file, song.path)
  end
end


return view_model_song_list.new