local callbacks = include("includes/events/audio.lua")
local callbacks_interface = include("includes/events/interface.lua")
require("delegate")

local colPlay = Color(0, 150, 0)
local colAPlay = Color(70, 190, 180)
local colPause = Color(255, 150, 0)
local colAPause = Color(210, 210, 0)
local colLoop = Color(0, 230, 0)
local colALoop = Color(45, 205, 115)
local col404 = Color(240, 0, 0)
local colBlack = Color(0, 0, 0)
local colWhite = Color(230, 230, 230)
local colWhiteTitle = Color(255, 255, 255)
local dermaBase = {}
--[[
    Used for highlighting the playing line in the song list
--]]
local cl_song_index = 1
local sv_song_index = 0
local cl_song_prev_index = 0
local sv_song_prev_index = 0
local SIDE_CLIENT = 0
local SIDE_SERVER = 1
--[[
  Contains the last highlighted index for each mode.
  Easier way to clear highlights between different modes
]]
local songlist_highlights = {}
songlist_highlights[SIDE_CLIENT] = 0
songlist_highlights[SIDE_SERVER] = 0

local function RemapTo(val, min, max, output_min, output_max)
  val = tonumber(val)

  if (val < min) then
    val = min
  elseif (val > max) then
    val = max
  end

  local remapped_val = math.Remap(val, min, max, output_min, output_max)

  return remapped_val or min
end

GMPL_AUDIO = {}

GMPL_AUDIO.new = function(self, channel_mode)
  local channel = {}



  local methods = {
    attrs = {
      -- 0 client, 1 server
      mode = channel_mode,
      isPlaying = false,
      isPaused = false,
      isLooped = false,
      isStopped = true,
      isMissing = false,
      isAutoPlaying = false,
      -- non admin can mute server audio
      isLivePaused = false,
      error = false,
      -- use for the seek end by comparing the current -- and previous slider values
      prev_seek = 0,
      seek = 0,
      seek_len = 0,
      volume = 0,
      prev_volume = 0,
      title_status = "",
      -- empty string marks missing
      title_song = "",
      song = "",
      song_index = 0,
      song_prev_index = 0,
      think = false,
      think_autoplay = false,
      AutoplayNext = false,
      -- seeking when autoplaying on server
      keep_seek_alive = false,
    },
    delegate = {
      on_begin_play = Delegate:new(),
      on_play_ui_update = Delegate:new(),
      on_pause_ui_update = Delegate:new(),
      on_loop_ui_update = Delegate:new(),
      on_autoplay_ui_update = Delegate:new(),
      on_revert_ui_update = Delegate:new(),
      on_stop_ui_update = Delegate:new(),
      on_missing_ui_update = Delegate:new(),
    },




    get = function(self) return channel end,
    get_song_name = function(self) return self.title_song end,
    set_song_name = function(self, song_name)
      self.title_song = song_name
    end,
    get_song_path = function(self) return self.song end,
    get_song_index = function(self) return self.song_index end,
    get_song_prev_index = function(self) return self.song_prev_index end,
    get_song_prefix = function(self) return self.title_status end,
    get_time = function(self) return channel:GetTime() end,
    get_volume_raw = function(self)
      if self.isStopped or not self:IsValid() then return end

      return channel:GetVolume()
    end,
    get_length = function(self) return self.seek_len end,
    is_playing = function(self) return self.isPlaying end,
    is_paused = function(self) return self.isPaused end,
    is_paused_live = function(self) return self.isLivePaused end,
    is_looped = function(self) return self.isLooped end,
    is_autoplayed = function(self) return self.isAutoPlaying end,
    is_stopped = function(self) return self.isStopped end,
    is_thinking = function(self) return self.think end,
    is_missing = function(self) return self.isMissing end,
    is_server_channel = function(self) return self.mode == SIDE_SERVER end,
    has_error = function(self) return self.error end,
    set_song_prefix = function(self, prefix)
      self.title_status = prefix
    end,
    set_loop = function(self, bool)
      if not self:is_playing() then return end

      if bool == nil then
        bool = not self:is_looped()
      end

      channel:EnableLooping(bool)
      self.isLooped = bool
      self.isAutoPlaying = false
    end,
    -- if is_server_mode then --     think_autoplay = false -- end
    set_seek = function(self, number)
      if not self:is_playing() then return end
      if not self:IsValid() then return end

      if number == nil or not isnumber(number) then
        number = 0
      end

      if channel:GetState() ~= GMOD_CHANNEL_STALLED then
        channel:SetTime(number)
        self.prev_seek = self.seek
        self.seek = RemapTo(number, 0, self.seek_len, 0, 1)
      end
    end,
    set_play = function(self, bool)
      if not self:is_playing() then return end

      if bool == nil then
        bool = not self:is_playing()
      end

      self.isPlaying = bool
      self.isStopped = false
      self.isPaused = false
      self.isMissing = false
    end,
    set_pause = function(self, bool)
      if bool == nil then return end
      local state = channel:GetState()

      if bool then
        if state == GMOD_CHANNEL_PAUSED then return end

        if not self.isStopped and state == GMOD_CHANNEL_PLAYING then
          channel:Pause()
          self.isPaused = true
          self.isStopped = false
          -- audio is still valid
          self.isPlaying = true
        end
      else
        if state == GMOD_CHANNEL_PLAYING then return end

        if not self.isStopped and state == GMOD_CHANNEL_PAUSED then
          channel:Play()
          self.isPlaying = true
          self.isPaused = false
          self.isStopped = false
        end
      end
    end,
    set_autoplay = function(self, bool)
      if not self:is_playing() then return end

      if bool == nil then
        bool = not self:is_autoplayed()
      end

      print("auto play set to", bool)
      channel:EnableLooping(false)
      self.isLooped = false
      self.isAutoPlaying = bool
    end,
    set_missing = function(self, bool)
      self.isMissing = bool
      self.isPlaying = false

      if bool then
        self:set_song_prefix(" Not On Disk: ")
      end
    end,
    set_volume = function(self, number)
      if not (self:IsValid() and number ~= nil) then return end
      self.prev_volume = self.volume
      self.volume = number
      if self.isLivePaused then return end
      channel:SetVolume(number)
    end,
    silent_stop = function(self)
      if self.isStopped then return end

      if self:IsValid() then
        channel:Stop()
        channel = nil
      end

      self.isStopped = true
      self.isPaused = false
      self.isPlaying = false
    end,
    mute = function(self)
      if self.isStopped then return end
      -- print("Muting curr vol:", self.volume, self.prev_volume)
      self.prev_volume = channel:GetVolume()
      self.volume = 0
      channel:SetVolume(0)
    end,
    unmute = function(self)
      if self.isStopped then return end

      -- print("Unmuting curr vol:", self.volume, self.prev_volume)
      if self.volume == 0 then
        self.volume = dermaBase.slidervol:GetVolume() / 100
        self.prev_volume = 0

        if not self.isLivePaused then
          channel:SetVolume(self.volume)
        end
      end
    end,
    state = function(self)
      if self:IsValid() then return channel:GetState() end

      return -1
    end,
    play = function(self, song, song_index, is_autoplay, is_loop, seek)
      if not isstring(song) then return end
      self:silent_stop()
      if not self.isStopped then return end
      self.title_song = string.StripExtension(string.GetFileFromFilename(song))

      sound.PlayFile(song, "noblock noplay", function(CurrentSong, ErrorID, ErrorName)
        local is_audio_valid = IsValid(CurrentSong)

        if not is_audio_valid then
          self.error = true
          self.delegate.on_begin_play(self, is_audio_valid)
          self.delegate.on_missing_ui_update(channel)
          return
        end

        self.song = song

        if song_index ~= self.song_index then
          self.song_prev_index = self.song_index
          self.song_index = song_index
        end

        channel = CurrentSong
        CurrentSong:SetTime((seek or 0))
        self:set_volume(dermaBase.slidervol:GetVolume() / 100)
        self.isMissing = false
        self.isLooped = is_loop or false
        self.isAutoPlaying = is_autoplay or false
        channel:EnableLooping(self.isLooped)

        if self.isLooped then
          self.isAutoPlaying = false
          -- channel:EnableLooping(is_loop)
          -- self.isLooped = is_loop
          -- self.isAutoPlaying = false
          -- ui_update_title_color(3, song)
        elseif self.isAutoPlaying then
          self.isLooped = false
          channel:EnableLooping(false)
        end

        -- channel:EnableLooping(false)
        -- self.isLooped = false
        -- self.isAutoPlaying = is_autoplay
        -- ui_update_title_color(1, song)
        -- hope this wont break if commented
        -- dermaBase.sliderseek:AllowSeek(true)
        self.seek_len = CurrentSong:GetLength()
        -- dermaBase.sliderseek:SetMax(self.seek_len)
        -- dermaBase.contextmedia:SetSeekLength(self.seek_len)
        channel:Play()
        self.isPlaying = true
        self.isPaused = false
        self.isStopped = false
        self.think = true
        self.error = false

        self.delegate.on_begin_play(self, is_audio_valid)

        if self.isAutoPlaying then
          self.delegate.on_autoplay_ui_update(self)
        elseif self.isLooped then
          self.delegate.on_loop_ui_update(self)
        else
          self.delegate.on_play_ui_update(self)
        end
      end)
    end,
    resume = function(self)
      if self.isStopped then return end

      if self.isPaused then
        channel:Play()
        self.isPlaying = true
        self.isPaused = false
        self.isStopped = false
      end
    end,
    silent_pause = function(self, bool)
      if self.isStopped or not self:IsValid() then return end
      if self.isPaused or self.isLivePaused then return end

      if bool then
        channel:Pause()
      else
        channel:Play()
      end
    end,
    mute_live = function(self, bool)
      if self.isStopped or not self:IsValid() then return end
      self.isLivePaused = not self.isLivePaused

      if self.isLivePaused then
        -- self.prev_volume = channel:GetVolume()
        -- self.volume = 0
        channel:SetVolume(0)
      else
        -- print("Setting volume to ", self.prev_volume)
        -- channel:SetVolume(self.prev_volume)
        channel:SetVolume(self.volume)
      end
    end,
    pause = function(self, bool)
      if bool ~= nil then
        self:set_pause(bool)

        return
      end

      if channel:GetState() == GMOD_CHANNEL_PLAYING then
        channel:Pause()
        self.isPaused = true
        self.isStopped = false
        -- audio is still valid
        self.isPlaying = true
      elseif channel:GetState() == GMOD_CHANNEL_PAUSED and not self.isStopped then
        channel:Play()
        self.isPlaying = true
        self.isPaused = false
        self.isStopped = false
      end
    end,
    -- if self.isStopped then return end -- if isbool(bool_pause) then --     -- used as a setter --     sv_isPaused = not bool_pause -- end -- if self.isPaused then --     self.isPaused = false --     self.sv_PlayingSong:get():Play() -- else --     self.isPaused = true --     self.sv_PlayingSong:get():Pause() -- end
    stop = function(self)
      if self.isStopped then return end
      -- reset_ui()
      self.title_song = ""
      self.title_status = ""
      channel:Pause()
      self.song = ""
      self.prev_seek = 0
      self.seek = 0
      self.seek_len = 0
      self.song_prev_index = self.song_index
      self.song_index = 0
      self.isStopped = true
      self.isPaused = false
      self.isPlaying = false
      self.think = false
      self.isLivePaused = false
      self.think_autoplay = false
      self.AutoplayNext = true
    end,
    IsValid = function(self) return channel ~= nil and IsValid(channel) end,
  }

  local mt = {
    __index = function(self, k)
      local v = rawget(self.attrs, k)

      if v ~= nil then
        return v
      elseif v == nil then
        LocalPlayer():PrintMessage(HUD_PRINTCONSOLE, "[gMusic Player] Unhandled error code 2 on key ", k)
      end

      if k == 'keys' then
        local ks = {}

        for k, v in next, self.attrs, nil do
          ks[k] = 'attr'
        end

        for k, v in next, methods, nil do
          ks[k] = 'func'
        end

        return ks
      end
    end,
    __metatable = {},
    __newindex = function(self, k, v)
      if v == nil then
        LocalPlayer():PrintMessage(HUD_PRINTCONSOLE, "[gMusic Player] Unhandled error code 2 on key ", k)
      elseif rawget(self.attrs, k) ~= nil then
        rawset(self.attrs, k, v)
      end
    end,
  }


  methods.delegate.on_begin_play:add(callbacks.on_begin_play)
  methods.delegate.on_play_ui_update:add(callbacks_interface.on_play_ui_update)

  methods.delegate.on_pause_ui_update:add(
    callbacks_interface.on_pause_ui_update)

  methods.delegate.on_loop_ui_update:add(callbacks_interface.on_loop_ui_update)

  methods.delegate.on_autoplay_ui_update:add(
    callbacks_interface.on_autoplay_ui_update)

  methods.delegate.on_revert_ui_update:add(
    callbacks_interface.on_revert_ui_update)

  methods.delegate.on_stop_ui_update:add(callbacks_interface.on_stop_ui_update)

  setmetatable(methods, mt)

  return methods
end

-- local cl_PlayingSong = GMPL_AUDIO.new()
-- local sv_PlayingSong = GMPL_AUDIO.new()
-- Callbacks to be used outside
local function OnClientAudioChange(media)
end

--override
-- local function monitor_channel_seek(self)
--   if IsValid(self.sv_PlayingSong) and not
--     (self.sv_PlayingSong:is_stopped() or self.sv_PlayingSong:is_paused()) then
--     local max = self.sv_PlayingSong.seek_len
--     local time = self.sv_PlayingSong:get_time()
--     self.sv_PlayingSong.seek = RemapTo(time, 0, max, 0, 1)
--   end
--   if IsValid(self.cl_PlayingSong) and not
--     (self.cl_PlayingSong:is_stopped() or self.cl_PlayingSong:is_paused()) then
--     local max = self.cl_PlayingSong.seek_len
--     local time = self.cl_PlayingSong:get_time()
--     self.cl_PlayingSong.seek = RemapTo(time, 0, max, 0, 1)
--   end
-- end
-- Keep track of channel seek distance
local function monitor_channel_seek(self)
  if IsValid(self.sv_PlayingSong) and not (self.sv_PlayingSong:is_stopped() or self.sv_PlayingSong:is_paused()) then
    local time = self.sv_PlayingSong:get_time()
    local time_max = self.sv_PlayingSong.seek_len
    self.sv_PlayingSong.prev_seek = self.sv_PlayingSong.seek
    self.sv_PlayingSong.seek = RemapTo(time, 0, time_max, 0, 1)
  end

  if IsValid(self.cl_PlayingSong) and not (self.cl_PlayingSong:is_stopped() or self.cl_PlayingSong:is_paused()) then
    local time = self.cl_PlayingSong:get_time()
    local time_max = self.cl_PlayingSong.seek_len
    self.cl_PlayingSong.prev_seek = self.cl_PlayingSong.seek
    self.cl_PlayingSong.seek = RemapTo(time, 0, time_max, 0, 1)
  end
end

local function isCurrentMediaValid(self)
  if dermaBase.main:IsServerMode() then
    return IsValid(self.sv_PlayingSong)
  else
    return IsValid(self.cl_PlayingSong)
  end
end

local function isOtherMediaValid(self)
  if dermaBase.main:IsServerMode() then
    return IsValid(self.cl_PlayingSong)
  else
    return IsValid(self.sv_PlayingSong)
  end
end

local function getMedia(self)
  if dermaBase.main:IsServerMode() then
    return self.sv_PlayingSong:get()
  else
    return self.cl_PlayingSong:get()
  end
end

local function get_audio_channel(self)
  if dermaBase.main:IsServerMode() then
    return self.sv_PlayingSong
  else
    return self.cl_PlayingSong
  end
end

local function isThinking(self)
  if dermaBase.main:IsServerMode() then
    return self.sv_PlayingSong:is_thinking()
  else
    return self.cl_PlayingSong:is_thinking()
  end
end

-- local function enableTSS()
--   if not dermaBase.main:IsTSSEnabled() then
--     dermaBase.main:SetTSSEnabled(true)
--   end
-- end

-- local function disableTSS()
--   if dermaBase.main:IsTSSEnabled() then
--     dermaBase.main:SetTSSEnabled(false)

--     if not dermaBase.contextmedia then return end
--     dermaBase.contextmedia:SetTSS(false)
--   end
-- end

-- local function updateTitleSong(status, media)
--   if media:is_stopped() then
--     dermaBase.main:SetTitle(" gMusic Player")
--     dermaBase.main:SetTSSEnabled(false)

--     if dermaBase.contextmedia then
--       dermaBase.contextmedia:SetTextColor(colBlack)
--       dermaBase.contextmedia:SetText(false)
--     end
--     disableTSS()

--     return ""
--   else
--     enableTSS()
--     local song_filepath = media:get_song_path()

--     -- local media = 0
--     -- if dermaBase.main:IsServerMode() then
--     --     media = gmpl_audio.sv_PlayingSong
--     -- else
--     --     media = gmpl_audio.cl_PlayingSong
--     -- end
--     if status == false then
--       media:set_missing(true)
--       dermaBase.main:SetTitleBGColor(col404)
--       if dermaBase.contextmedia then
--         dermaBase.contextmedia:SetTextColor(col404)
--         dermaBase.contextmedia:SetMissing(true)
--       end
--       MsgC(Color(100, 200, 200), "[gMusic Player]", Color(255, 255, 255), " Song file missing:\n> ", song_filepath, "\n")
--     end

--     if song_filepath then
--       local title_song = media:get_song_name()
--       dermaBase.main:SetTitle(media:get_song_prefix() .. title_song)
--       if dermaBase.contextmedia then
--         dermaBase.contextmedia:SetText(title_song)
--       end

--       return title_song
--     end

--     return media:get_song_name()
--   end
-- end

-- REMOVE it WHEN sure there is no problem with highlight selection
-- local function updateListSelection(color, textcolor, media)
--   local sv_song_index = media.sv_PlayingSong:get_song_index()
--   local cl_song_index = media.cl_PlayingSong:get_song_index()
--   if dermaBase.main:IsServerMode() then
--     if color == false then
--       -- manual reset
--       print("manual reset")
--       dermaBase.songlist:HighlightReset(sv_song_index)
--     end
--     local sv_song_prev_index = media.sv_PlayingSong:get_song_prev_index()
--     -- if it cant find the song number then better not bother coloring
--     if IsValid(dermaBase.songlist:GetLines()[sv_song_index]) then
--       dermaBase.songlist:HighlightLine(sv_song_index, color, textcolor)
--     end
--     if IsValid(dermaBase.songlist:GetLines()[sv_song_prev_index]) and
--       sv_song_prev_index ~= sv_song_index then
--       dermaBase.songlist:HighlightReset(sv_song_prev_index)
--     end
--     if (cl_song_index ~= sv_song_index) then
--       dermaBase.songlist:HighlightReset(cl_song_index)
--     end
--     sv_song_prev_index = sv_song_index
--   else
--     if color == false then
--       dermaBase.songlist:HighlightReset(cl_song_index)
--     end
--     local cl_song_prev_index = media.cl_PlayingSong:get_song_prev_index()
--     -- if it cant find the song number then better not bother coloring
--     if IsValid(dermaBase.songlist:GetLines()[cl_song_index]) then
--       dermaBase.songlist:HighlightLine(cl_song_index, color, textcolor)
--     end
--     if IsValid(dermaBase.songlist:GetLines()[cl_song_prev_index]) and
--       cl_song_prev_index ~= cl_song_index then
--       dermaBase.songlist:HighlightReset(cl_song_prev_index)
--     end
--     if (cl_song_index ~= sv_song_index) then
--       dermaBase.songlist:HighlightReset(sv_song_index)
--     end
--     cl_song_prev_index = cl_song_index
--   end
-- end
local function ui_clear_previous_mode_highlight(channel)
  local previous_mode = SIDE_CLIENT

  if channel.mode == SIDE_CLIENT then
    previous_mode = SIDE_SERVER
  end

  dermaBase.songlist:HighlightReset(songlist_highlights[previous_mode])
end

-- local function ui_update_list_selection(channel, color, textcolor)
--   local song_index = channel:get_song_index()
--   local prev_song_index = channel:get_song_prev_index()
--   ui_clear_previous_mode_highlight(channel)

--   -- if it cant find the song number then better not bother coloring
--   if textcolor == false or color == false then
--     textcolor = dermaBase.songlist:GetDefaultTextColor()
--   end

--   local song_list = dermaBase.songlist:GetLines()

--   if IsValid(song_list[song_index]) then
--     dermaBase.songlist:HighlightLine(song_index, color, textcolor)
--     songlist_highlights[channel.mode] = song_index
--   end

--   if IsValid(song_list[prev_song_index]) then
--     dermaBase.songlist:HighlightReset(prev_song_index)
--   end
-- end




-- local function ui_update_title_color(status, channel)
--   local is_server_mode = dermaBase.main:IsServerMode()
--   local color_bg = Color(150, 150, 150)
--   local color_text = colWhite
--   local is_auto_playing = channel:is_autoplayed()

--   if status == 1 then
--     if is_auto_playing then
--       channel:set_song_prefix(" Auto Playing: ")
--       color_bg = colAPlay
--       color_text = colBlack
--     else
--       channel:set_song_prefix(" Playing: ")
--       color_bg = colPlay
--       color_text = colWhite
--     end
--   else
--     if status == 2 then
--       channel:set_song_prefix(" Paused: ")
--       color_bg = colPause
--       color_text = colBlack
--     elseif status == 3 then
--       channel:set_song_prefix(" Looping: ")
--       color_bg = colLoop
--       color_text = colBlack
--     elseif status == 4 then
--       channel:set_song_prefix(" Muted: ")
--       color_bg = colAPause
--       color_text = colBlack
--     end
--   end

--   if status == false or (status == 1 and not is_auto_playing) then
--     dermaBase.main:SetTitleColor(colWhiteTitle)
--   else
--     dermaBase.main:SetTitleColor(color_text)
--   end

--   dermaBase.main:SetTitleBGColor(color_bg)
--   if dermaBase.contextmedia then
--     dermaBase.contextmedia:SetTextColor(color_bg)
--   end
--   updateTitleSong(status, channel)

--   return color_bg, color_text
-- end

--[[
    Server audio object needs to live for autoplay to work
--]]
-- local function mute_sv_song(self)
--     if not IsValid(self.sv_PlayingSong) then return end
--     self.sv_PlayingSong:get():Stop()
--     sv_prev_volume = self.sv_PlayingSong:get():GetVolume()
--     self.sv_PlayingSong:set_volume(0)
--     sv_isPaused = false
--     sv_isStopped = true
-- end
local function updateAudioObject(self, CurrentSong, on_server)
  if not IsValid(CurrentSong) then return end

  if on_server then
    self.sv_PlayingSong = CurrentSong
    -- missingSong = false
  else
    self.cl_PlayingSong = CurrentSong
    -- missingSong = false
  end
end

-------------------------------------------------------------------------------
local function is_looped(self)
  if dermaBase.main:IsServerMode() then
    return self.sv_PlayingSong:is_looped()
  else
    return self.cl_PlayingSong:is_looped()
  end
end

local function sv_is_loop(self)
  return self.sv_PlayingSong:is_looped()
end

local function sv_is_play(self)
  -- return sv_isStopped
  return self.sv_PlayingSong:is_playing()
end

local function cl_is_play(self)
  return self.cl_PlayingSong:is_playing()
end

local function is_playing(self)
  if dermaBase.main:IsServerMode() then
    return self.sv_PlayingSong:is_playing()
  else
    return self.cl_PlayingSong:is_playing()
  end
end

local function sv_is_autoplay(self)
  return self.sv_PlayingSong:is_autoplayed()
end

local function cl_is_autoplay(self)
  return self.cl_PlayingSong:is_autoplayed()
end

local function is_autoplaying(self)
  if dermaBase.main:IsServerMode() then
    return self.sv_PlayingSong:is_autoplayed()
  else
    return self.cl_PlayingSong:is_autoplayed()
  end
end

local function songMissing(self)
  if dermaBase.main:IsServerMode() then
    return self.sv_PlayingSong:is_missing()
  else
    return self.cl_PlayingSong:is_missing()
  end
end

local function sv_is_stop(self)
  -- return sv_isStopped
  return self.sv_PlayingSong:is_stopped()
end

local function cl_is_stop(self)
  return self.cl_PlayingSong:is_stopped()
end

local function songStopped(self)
  if dermaBase.main:IsServerMode() then
    return self.sv_PlayingSong:is_stopped()
  else
    return self.cl_PlayingSong:is_stopped()
  end
end

local function sv_is_pause(self)
  return self.sv_PlayingSong:is_paused()
end

local function cl_is_pause(self)
  return self.cl_PlayingSong:is_paused()
end

local function songPaused(self)
  if dermaBase.main:IsServerMode() then
    return self.sv_PlayingSong:is_paused()
  else
    return self.cl_PlayingSong:is_paused()
  end
end

local function is_paused_live(self)
  return self.sv_PlayingSong:is_paused_live()
end

local function songState(self)
  return getMedia(self):GetState()
end

local function songClientTime(self)
  return getMedia(self):GetTime()
end

local function songServerTime(self)
  if IsValid(self.sv_PlayingSong) then return self.sv_PlayingSong:get_time() end

  return 0
end

local function songServer(self)
  if IsValid(self.sv_PlayingSong) then return self.sv_PlayingSong:get_song_name() end

  return ""
end

local function get_time(self, is_normalized)
  local channel = get_audio_channel(self)
  if not IsValid(channel) then return 0 end

  if is_normalized then
    return channel.seek
  else
    -- works only for active channel
    return channel:get_time()
  end
end

local function has_reached_seek_end(self, channel)
  if not IsValid(channel) then return false end
  -- print("----------------------------")
  -- print(channel.mode, ":", channel.seek , " | ", channel.prev_seek)
  -- print("\n\n\n")
  local end_reached = channel.seek == channel.prev_seek

  if end_reached then
    channel.prev_seek = -1
  end

  return end_reached
end

local function get_length(self)
  local channel = get_audio_channel(self)

  return channel:get_length()
end

local function get_volume(self, real_volume)
  local channel = get_audio_channel(self)

  if real_volume then
    return channel:get_volume_raw()
  else
    return channel.volume
  end
end

local function set_volume(self, number)
  local channel = get_audio_channel(self)
  channel:set_volume(number)
end

local function cl_mute(self, bool)
  if bool then
    self.cl_PlayingSong:mute()
    self.cl_PlayingSong:silent_pause(true)
  else
    self.cl_PlayingSong:unmute()
    self.cl_PlayingSong:silent_pause(false)
  end

  return self.cl_PlayingSong:is_playing()
end

local function sv_mute(self, bool)
  if bool then
    self.sv_PlayingSong:mute()
  else
    self.sv_PlayingSong:unmute()
  end

  return self.sv_PlayingSong:is_playing()
end

-- TODO might need to change where this is used to remove unneeded code
-- local function update_ui_selection(self, channel)
--   if channel == nil then
--     channel = get_audio_channel(self)
--   end

--   local color_bg, color_text = {}, {}
--   local color_state = 0

--   if channel:is_paused() then
--     color_state = 2
--   elseif channel:is_paused_live() then
--     color_state = 4
--   elseif channel:is_looped() then
--     color_state = 3
--   elseif channel:is_playing() then
--     color_state = 1
--   elseif channel:is_stopped() then
--     color_bg, color_text = ui_update_title_color(false, channel)
--     ui_update_list_selection(channel, false, false)

--     return
--   end

--   color_bg, color_text = ui_update_title_color(color_state, channel)
--   ui_update_list_selection(channel, color_bg, color_text)
-- end

local function playSong(self, song, song_index, is_autoplay, is_loop, seek, channel)
  if channel == nil then
    channel = get_audio_channel(self)
  end

  if channel == nil then return end

  channel:play(song, song_index, is_autoplay, is_loop, seek)

  -- channel:play(song, song_index, is_autoplay, is_loop, seek, function(_channel, is_valid)
  --   local on_server_mode = _channel:is_server_channel() and dermaBase.main:IsServerMode()
  --   local on_client_mode = not _channel:is_server_channel() and not dermaBase.main:IsServerMode()

  --   -- if _channel:is_server_channel() then
  --   -- if _channel.title_song ~= nil or #_channel.title_song > 0 then
  --   -- chat.AddText(Color(0, 220, 220), "[gMusic Player] Playing: " .. _channel.title_song)
  --   -- end
  --   -- end
  --   if not dermaBase.main:IsServerMode() then
  --     dermaBase.mediaplayer:sv_mute(true)
  --   end

  --   if on_server_mode or on_client_mode then
  --     if not is_valid then
  --       dermaBase.sliderseek:ResetValue()

  --       return
  --     end

  --     dermaBase.sliderseek:AllowSeek(true)
  --     dermaBase.sliderseek:SetMax(_channel.seek_len)
  --     dermaBase.sliderseek:ShowSeekBarIndicator(true)
  --     if dermaBase.contextmedia then
  --       dermaBase.contextmedia:SetSeekLength(_channel.seek_len)
  --     end
  --     if is_autoplay then
  --       _channel.delegate.on_autoplay_ui_update(_channel)
  --     elseif is_loop then
  --       _channel.delegate.on_loop_ui_update(_channel)
  --     else
  --       _channel.delegate.on_play_ui_update(_channel)
  --     end
  --   end
  -- end)

  return song_name
end

local function play_next_song(self, channel)
  if channel == nil then
    channel = get_audio_channel(self)
  end

  if not IsValid(channel) then return end

  if dermaBase.songlist:IsEmpty() then
    channel:stop()

    return
  end

  local next_song_index = channel:get_song_index() + 1
  local next_song, index = dermaBase.song_data:get_song(next_song_index)
  playSong(self, next_song, index, true, false, 0, channel)
end

local function sv_play_next_song(self)
  play_next_song(self, self.sv_PlayingSong)
end

local function playSongServer(self, song, song_index, is_autoplay, is_loop, seek)
  playSong(self, song, song_index, is_autoplay, is_loop, seek, self.sv_PlayingSong)
end

local function resumeSong(self)
  local channel = get_audio_channel(self)
  channel:resume()
  channel.delegate.on_revert_ui_update(channel)
  -- update_ui_selection(self, channel)
end

-- TODO EDIT to simplify reset_ui , update_ui_selection,  updateListSelection2
-- and updateListSelection. ALSO might move them to interface file
-- local function reset_ui(self, channel)
--   dermaBase.sliderseek:ResetValue()
--   dermaBase.sliderseek:AllowSeek(false)
--   ui_update_title_color(false, channel)
--   ui_update_list_selection(channel, false, false)
-- end

local function action_sv_pause(self, explicit_pause)
  local channel = self.sv_PlayingSong
  if not IsValid(channel) then return end
  if channel:is_stopped() then return end
  channel:pause(explicit_pause)

  if not dermaBase.main:IsServerMode() then return end

  if channel:is_paused() then
    channel.delegate.on_pause_ui_update(channel)
  else
    channel.delegate.on_revert_ui_update(channel)
  end
end

local function action_cl_pause(self, explicit_pause)
  local channel = self.cl_PlayingSong
  if not IsValid(channel) then return end
  if channel:is_stopped() then return end
  channel:pause(explicit_pause)

  if dermaBase.main:IsServerMode() then return end

  if channel:is_paused() then
    channel.delegate.on_pause_ui_update(channel)
  else
    channel.delegate.on_revert_ui_update(channel)
  end
    -- update_ui_selection(self, channel)
    -- OnClientAudioChange(channel)

end

local function action_sv_loop(self, explicit_loop)
  local channel = self.sv_PlayingSong
  if not IsValid(channel) then return end
  if channel:is_stopped() then return end
  channel:set_loop(explicit_loop)

  if not dermaBase.main:IsServerMode() then return end

  if channel:is_looped() then
    channel.delegate.on_loop_ui_update(channel)
  else
    channel.delegate.on_revert_ui_update(channel)
  end
end

local function action_cl_loop(self, explicit_loop)
  local channel = self.cl_PlayingSong
  if not IsValid(channel) then return end
  if channel:is_stopped() then return end
  channel:set_loop(explicit_loop)

  if dermaBase.main:IsServerMode() then return end

  if channel:is_looped() then
    channel.delegate.on_loop_ui_update(channel)
  else
    channel.delegate.on_revert_ui_update(channel)
  end
end

local function actionPauseL(self)
  local channel = get_audio_channel(self)
  if not IsValid(channel) then return end
  if channel:is_stopped() then return end
  channel:pause()
  channel.delegate.on_pause_ui_update(channel)
  -- update_ui_selection(self, channel)
  -- OnClientAudioChange(channel)
end

local function pause_live(self)
  local channel = self.sv_PlayingSong
  if not IsValid(channel) then return end
  self.sv_PlayingSong:mute_live()
  channel.delegate.on_pause_ui_update(channel)
  -- update_ui_selection(self, self.sv_PlayingSong)
end

local function action_sv_autoplay(self, explicit_autoplay)
  local channel = self.sv_PlayingSong
  if not IsValid(channel) then return end
  if channel:is_stopped() then return end
  channel:set_autoplay(explicit_autoplay)

  if not dermaBase.main:IsServerMode() then return end

  if channel:is_autoplayed() then
    channel.delegate.on_autoplay_ui_update(channel)
  else
    channel.delegate.on_revert_ui_update(channel)
  end
end

local function action_cl_autoplay(self, explicit_autoplay)
  local channel = self.cl_PlayingSong
  if not IsValid(channel) then return end
  if channel:is_stopped() then return end
  channel:set_autoplay(explicit_autoplay)

  if dermaBase.main:IsServerMode() then return end

  if channel:is_autoplayed() then
    channel.delegate.on_autoplay_ui_update(channel)
  else
    channel.delegate.on_revert_ui_update(channel)
  end
end

local function action_sv_stop(self)
  local channel = self.sv_PlayingSong
  local is_server = dermaBase.main:IsServerMode()
  channel:stop()


  if channel:is_stopped() and is_server then
    channel.delegate.on_stop_ui_update(channel)
    -- reset_ui(self, self.sv_PlayingSong)
  end
end

local function action_cl_stop(self)
  local channel = self.cl_PlayingSong
  local is_client = not dermaBase.main:IsServerMode()

  channel:stop()
  if channel:is_stopped() and is_client then
    channel.delegate.on_stop_ui_update(channel)
    -- reset_ui(self, self.cl_PlayingSong)
  end
end

local function actionPauseR(self)
  local channel = get_audio_channel(self)
  if channel:is_stopped() then return end
  channel:set_loop()
  channel.delegate.on_pause_ui_update(channel)
  -- update_ui_selection(self, channel)
  -- OnClientAudioChange(self.cl_PlayingSong)
end

local function autoplay(self, bool)
  local channel = get_audio_channel(self)
  if channel:is_stopped() then return end
  channel:set_autoplay(bool)
  channel.delegate.on_autoplay_ui_update(channel)
  -- update_ui_selection(self, channel)
  -- OnClientAudioChange(channel)
end

local function actionSeek(self, time)
  if not isCurrentMediaValid(self) then return end
  local channel = get_audio_channel(self)
  channel:set_seek(time)
end

return function(baseMenu, media_callbacks)
  -- TODO think if i could use this for some kind of after action
  -- Not sure for what to use now. The current OnServerMode and OnClientMode
  -- does the job pretty good
  OnClientAudioChange = media_callbacks.OnClientAudioChange
  dermaBase = baseMenu
  local action = {}
  action.play = playSong
  action.play_server = playSongServer
  action.get_channel = get_audio_channel
  action.resume = resumeSong
  action.sv_pause = action_sv_pause
  action.cl_pause = action_cl_pause
  action.sv_loop = action_sv_loop
  action.cl_loop = action_cl_loop
  action.sv_stop = action_sv_stop
  action.cl_stop = action_cl_stop
  action.sv_autoplay = action_sv_autoplay
  action.cl_autoplay = action_cl_autoplay
  action.play_next = play_next_song
  action.sv_play_next = sv_play_next_song
  action.pause_live = pause_live
  action.pause = actionPauseL
  action.loop = actionPauseR
  action.autoplay = autoplay
  action.seek = actionSeek
  action.cl_mute = cl_mute
  action.sv_mute = sv_mute
  action.volume = set_volume
  action.get_volume = get_volume
  action.get_length = get_length
  action.update_ui_highlight = update_ui_selection
  action.kill = kill
  action.update = updateAudioObject
  -- action.getClientTime = songClientTime
  action.get_time = get_time
  action.getServerTime = songServerTime
  action.get_server_song = songServer
  action.has_reached_seek_end = has_reached_seek_end
  action.isMissing = songMissing
  action.is_looped = is_looped
  action.sv_is_loop = sv_is_loop
  action.sv_is_autoplay = sv_is_autoplay
  action.cl_is_autoplay = cl_is_autoplay
  action.is_autoplaying = is_autoplaying
  action.hasValidity = isCurrentMediaValid
  action.hasState = songState
  -- action.sv_is_play   =   sv_is_play
  -- action.cl_is_play   =   cl_is_play
  action.is_playing = is_playing
  action.sv_is_stop = sv_is_stop
  action.cl_is_stop = cl_is_stop
  action.is_stopped = songStopped
  action.sv_is_pause = sv_is_pause
  action.cl_is_pause = cl_is_pause
  action.is_paused = songPaused
  action.is_paused_live = is_paused_live

  action.isThinking = isThinking
  action.monitor_channel_seek = monitor_channel_seek
  action.cl_PlayingSong = GMPL_AUDIO:new(SIDE_CLIENT)
  action.sv_PlayingSong = GMPL_AUDIO:new(SIDE_SERVER)

  return action
end