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
local model_song_list = class()

function model_song_list:ctor()
  self.derma = {}
  self.song_data = include("includes/modules/meth_song_wip_mvvm.lua")(self.derma)

  local active_folders = self.song_data:read_active_folders_from_config_file()
  local audio_files = self.song_data:get_files_from_folders(active_folders)
  self.song_list = audio_files

end

function model_song_list:get_songs()
  return self.song_list
end


return model_song_list.new()