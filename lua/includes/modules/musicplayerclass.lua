local dermaBase = {}
local Media = {}

-- dermaBase.mediaplayer:__index = Media
--[[
    List of audio files in the song list
--]]
-- local populatedSongs = {}
local function init(coreBase, callbacks)
  dermaBase = coreBase
  local MediaPlayer = {}
  -- local MediaPlayer = setmetatable({}, Media)
  local action = include("includes/func/audio.lua")(dermaBase, callbacks)

  for k, v in pairs(action) do
    MediaPlayer[k] = v
  end

  for k, v in pairs(Media) do
    MediaPlayer[k] = v
  end

  return MediaPlayer
end

-- setmetatable(Media, {  __call = init })
local function realtime_seek(self)
  if not self:hasValidity() then return end

  -- if dermaBase.mediaplayer:is_autoplaying() then
  --   dermaBase.mediaplayer:play_next()
  if dermaBase.main:IsVisible() or dermaBase.mediaplayer:is_autoplaying() then
    if not self:isThinking() then return end -- think_indicator:Hide()
    -- think_indicator:Show()
    -- if self:hasState() == GMOD_CHANNEL_STALLED then
    -- print("[think] stalled retry")
    -- dermaBase.mediaplayer:retry()
    -- print("stalled so return")
    -- return
    -- end
    -- allow seek at depressed pos
    if dermaBase.sliderseek:IsCursorMoved() then return end

    if not self:is_stopped() then
      dermaBase.sliderseek:AllowSeek(true)
      dermaBase.sliderseek:SetTime(self:get_time(), self:get_time(true))
    elseif self:is_looped() then
      dermaBase.sliderseek:AllowSeek(true)
      dermaBase.sliderseek:SetTime(dermaBase.sliderseek:GetMin(), dermaBase.sliderseek:GetMin())
    end
  end
end

-----------------------------------------------------------------------------
Media.realtime_seek = realtime_seek

-----------------------------------------------------------------------------
--[[
    In case host disconnects or loses admin role
--]]
local function song_host_disconnected(ply)
  dermaBase.labelswap:SetText("Unavailable: " .. dermaBase.interface.get_song_host())
  ply:PrintMessage(HUD_PRINTCONSOLE, "[gMusic Player] Cannot get Live Song. The host is unavailable.")
end

-----------------------------------------------------------------------------
-- ingame-debugging
-- local think_indicator = vgui.Create("Panel")
-- think_indicator:SetSize(50,50)
-- think_indicator:AlignTop()
-- think_indicator:SetPos(10,0)
-- think_indicator.Paint = function(self, w, h)
--     surface.SetDrawColor(255,0,0,255)
--     surface.DrawRect(0,0,w,h)
-- end
-- net.Receive("askAdminForLiveSeek", function(length, ply)
-- 	local user = net.ReadEntity()
-- 	if LocalPlayer():IsAdmin() then
-- 		local seekTime = 0
-- 		if dermaBase.mediaplayer:hasValidity() then
-- 			seekTime = dermaBase.mediaplayer:getServerTime()
-- 			songIndex = dermaBase.songlist:GetSelectedLine()
-- 			net.Start("toServerUpdateSeek")
-- 			net.WriteDouble(seekTime)
-- 			net.SendToServer()
-- 		else
-- 			user:PrintMessage(HUD_PRINTTALK, "[gMusic Player] No song is playing on the server")
-- 		end
-- 	else
-- 		song_host_disconnected(user)
-- 	end
-- end)
function Media:net_init()
  net.Receive("cl_stop_live", function(length, ply)
    print("cl_net - cl_stop_live")
    print("is autoplay", dermaBase.mediaplayer:sv_is_autoplay())

    -- timer.Pause("gmpl_seek_end")
    if dermaBase.mediaplayer:sv_is_loop() then
      dermaBase.sliderseek:AllowSeek(true)
      -- set time to audio channel not to the slider
      dermaBase.sliderseek:SetTime(dermaBase.sliderseek:GetMin(), dermaBase.sliderseek:GetMin())
    elseif dermaBase.mediaplayer:sv_is_autoplay() then
      print("is autopalying")
      dermaBase.mediaplayer:sv_play_next()
    else
      dermaBase.mediaplayer:sv_stop()
      dermaBase.labelswap:SetText("No song currently playing")
    end
  end)

  -- timer.UnPause("gmpl_seek_end")
  net.Receive("cl_play_live", function(length, sender)
    local live_song = net.ReadString()
    if live_song == nil or #live_song == 0 then return end
    local is_looped = net.ReadBool()
    local is_autoplayed = net.ReadBool()
    local index_song = net.ReadUInt(16)
    local live_host = net.ReadEntity()
    dermaBase.interface.set_song_host(live_host)
    print("[ cl_play_live ] Sender", sender)
    print("[ cl_play_live ] LocalPlayer", LocalPlayer())

    if dermaBase.main:IsServerMode() then
      -- dermaBase.set_server_TSS(true)
      -- dermaBase.mediaplayer:uiTitle(live_song)
      -- if not dermaBase.mediaplayer:clientHasControl() then
      -- print("[net] play sv song", index_song, live_song, "| loop:", is_looped, "| autoplay:", is_autoplayed)
      dermaBase.mediaplayer:play(live_song, index_song, is_autoplayed, is_looped)
      -- else
      --     print("[net] update ui seek")
      --     dermaBase.interface.refresh_seek()
      -- end
    else
    end
  end)

  -- print("[net] update sv song", index_song, live_song, "| loop:", is_looped, "| autoplay:", is_autoplayed)
  -- dermaBase.mediaplayer:updateServer(live_song, index_song, is_autoplayed, is_looped)
  -- this should be more like play song but muted
  -- if not dermaBase.mediaplayer:clientHasControl() then
  -- end
  net.Receive("cl_set_loop", function(length, ply)
    if not dermaBase.mediaplayer:hasValidity() or not dermaBase.main:IsServerMode() then return end
    local is_looped = net.ReadBool()
    dermaBase.mediaplayer:sv_loop(is_looped)
  end)

  -- if dermaBase.mediaplayer:is_playing() then
  --     if is_looped then
  --         dermaBase.mediaplayer:uiLoop()
  --     elseif dermaBase.mediaplayer:is_autoplaying() then
  --         dermaBase.mediaplayer:uiAutoPlay()
  --     else
  --         dermaBase.mediaplayer:uiPlay()
  --     end
  -- end
  net.Receive("cl_set_autoplay", function(length, ply)
    if not dermaBase.mediaplayer:hasValidity() or not dermaBase.main:IsServerMode() then return end
    local is_autoplayed = net.ReadBool()
    dermaBase.mediaplayer:autoplay(is_autoplayed)
  end)

  -- if dermaBase.mediaplayer:clientHasControl() then return end
  -- if dermaBase.mediaplayer:hasState() == GMOD_CHANNEL_PLAYING then
  --     if is_autoplayed then
  --         dermaBase.mediaplayer:uiAutoPlay()
  --     elseif dermaBase.mediaplayer:is_looped() then
  --         dermaBase.mediaplayer:uiLoop()
  --     else
  --         dermaBase.mediaplayer:uiPlay()
  --     end
  -- end
  net.Receive("cl_pause_live", function(length, sender)
    if not dermaBase.main:IsServerMode() then return end
    -- local live_song = net.ReadString()
    -- dermaBase.mediaplayer:uiTitle(live_song)
    -- if dermaBase.mediaplayer:clientHasControl() then return end
    local is_server_paused = net.ReadBool()

    -- print("[net] sv pause:",is_server_pause)
    -- if LocalPlayer():IsAdmin() then
    --   dermaBase.mediaplayer:sv_pause(is_server_pause)
    --   dermaBase.mediaplayer:sv_uiRefresh()
    --   net.Start("sv_update_song_state")
    --   net.WriteBool(dermaBase.mediaplayer:is_paused())
    --   net.WriteBool(dermaBase.mediaplayer:is_autoplaying())
    --   net.WriteBool(dermaBase.mediaplayer:is_looped())
    --   net.SendToServer()
    --   return
    -- end
    if is_server_paused then
      dermaBase.mediaplayer:sv_pause(is_server_pause)
      dermaBase.mediaplayer:sv_uiRefresh()
    else
      net.Start("sv_play_live_seek_from_host")
      net.SendToServer()
    end
  end)

  -- if is_server_pause then
  --     dermaBase.mediaplayer:uiPause()
  -- else
  --     dermaBase.mediaplayer:uiP
  -- end
  -- if is_server_paused then
  --     -- if dermaBase.mediaplayer:hasValidity() then
  --     -- else
  --     net.Start("sv_refresh_song_state")
  --     net.SendToServer()
  --     -- end
  -- else
  --     net.Start("sv_play_live_seek_from_host")
  --     net.SendToServer()
  -- end
  net.Receive("cl_play_live_seek_from_host", function(length, sender)
    local user = net.ReadEntity()

    if not IsValid(sender) or not sender:IsAdmin() then
      song_host_disconnected(user)

      return
    end

    -- grab audio from first admin
    -- print("[net] play live for user:", user)
    if not dermaBase.mediaplayer:hasValidity() then
      user:PrintMessage(HUD_PRINTTALK, "[gMusic Player] No song is playing on the server")

      return
    end

    net.Start("sv_play_live_seek_for_user")
    net.WriteEntity(user)
    net.WriteDouble(dermaBase.mediaplayer:getServerTime())
    net.SendToServer()
  end)

  net.Receive("cl_play_live_seek", function(length, ply)
    if not dermaBase.main:IsServerMode() then return end
    -- dermaBase.set_server_TSS(true)
    local live_seek = net.ReadDouble()
    local live_song = net.ReadString()
    local live_song_index = net.ReadUInt(16)
    local is_autoplayed = net.ReadBool()
    local is_looped = net.ReadBool()
    -- print("[net] seek sv song:", live_song_index, live_seek, "| loop:", is_looped, "| autoplay:", is_autoplayed)
    -- dermaBase.mediaplayer:clientControl(false)
    -- might change it with simple play and pass the PlayingServer obj
    dermaBase.mediaplayer:play_server(live_song, live_song_index, is_autoplayed, is_looped, live_seek)
  end)

  net.Receive("cl_refresh_song_state", function(length, ply)
    local is_paused = net.ReadBool()
    local is_autoplayed = net.ReadBool()
    local is_looped = net.ReadBool()
    local live_seek = net.ReadDouble()
    local live_song = net.ReadString()
    local live_song_index = net.ReadUInt(16)
    local live_host = net.ReadEntity()

    -- print("[net] update state| loop:", is_looped, "| autoplay:", is_autoplayed, "| pause:", is_paused)
    -- sync with server only if needed
    -- if is_paused then
    -- elseif is_autoplayed then
    --     dermaBase.mediaplayer:setautoplay(is_autoplayed)
    --     dermaBase.mediaplayer:uiAutoPlay()
    -- elseif is_looped then
    --     dermaBase.mediaplayer:setloop(is_looped)
    --     dermaBase.mediaplayer:uiLoop()
    -- end
    if #live_song == 0 then
      if not dermaBase.main.playingFromAnotherMode() then
        dermaBase.mediaplayer:uiTitle(false)
      end

      dermaBase.mediaplayer:clientControl(false)
      dermaBase.labelswap:SetText("No song currently playing")

      return
    end

    print("[net] update sv song", live_song_index, live_song, "| loop:", is_looped, "| autoplay:", is_autoplayed)

    -- dermaBase.mediaplayer:updateServer(live_song, live_song_index, is_autoplayed, is_looped, live_seek)
    if is_paused then
      dermaBase.mediaplayer:sv_pause()
      dermaBase.mediaplayer:uiPause()
    end

    dermaBase.interface.set_song_host(live_host)
  end)

  -- net.Receive("cl_update_host", function(length, ply)
  --     local live_host = net.ReadEntity()
  --     print("[net] update host:", live_host)
  --     dermaBase.interface.set_song_host(live_host)
  -- end)
  -- TODO WORK ON adding the song table of the admin host on the server and tehn you just
  --increment from that table the next song.
  --If the same admin host tries to change the song check if it is the same admin and if not
  --check if the song basename is the one he wants to play(the key probably wont be a good idea)
  -- net.Receive( "cl_ansAutoPlaySong", function(length, ply)
  -- 	local nextAutoPlayedSong = net.ReadString()
  -- 	-- local currSong = populatedSongs[dermaBase.mediaplayer:songIndex(1, true)] or ""
  -- 	dermaBase.mediaplayer:uiAutoPlay()
  -- 	dermaBase.mediaplayer:playServer(nextAutoPlayedSong)
  -- end)
  net.Receive("cl_set_seek", function(length, ply)
    if not dermaBase.main:IsServerMode() then return end
    local seekTime = net.ReadDouble()
    dermaBase.mediaplayer:seek(seekTime)
  end)
end

return init