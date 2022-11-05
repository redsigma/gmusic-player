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
local model_song = class()

function model_song:ctor()
  self.song_title = "song_title"
  self.song_path = "song_path"

  self.delegate_on_set_song = Delegate:new_one_param()
  self.delegate_on_set_song:add(model_song.set_song)

end

function model_song:set_song(song_path)
  self.song_path = song_path
end

function model_song:set_song_title(title)
  self.song_title = title
end

function model_song:get_song_title()
  return self.song_title
end

function model_song:get_song_path()
  return self.song_path
end


return model_song.new()