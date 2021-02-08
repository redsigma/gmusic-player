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
	for k,v in pairs(action) do
        MediaPlayer[k] = v
    end
    for k,v in pairs(Media) do
        MediaPlayer[k] = v
    end
    hook.Add("Tick", "gmpl_RealTimePost", function()
        MediaPlayer:checkServerStop()
    end)
	return MediaPlayer
end
-- setmetatable(Media, {  __call = init })

local function ToggleNormalUI(self)
    dermaBase.buttonplay:SetText("Play / AutoPlay")
    dermaBase.buttonpause:SetText("Pause / Loop")
    dermaBase.buttonstop:SetVisible(true)
    dermaBase.buttonswap:SetVisible(false)
end

local function ToggleListenUI(self)
    dermaBase.buttonplay:SetText("Resume Live")
    dermaBase.buttonpause:SetText("Pause")
    dermaBase.buttonstop:SetVisible(false)
    dermaBase.buttonswap:SetVisible(true)
end

local function real_time_seek(self)
    -- i moved the populatedSongs to meth_songs so change this
    self:serverAutoPlayThink()

    if not self:hasValidity() then return end

    -- client side
	if dermaBase.main:IsVisible() then
        if not self:isThinking() then
            -- think_indicator:Hide()
            return
        end

        -- think_indicator:Show()
        -- if self:hasState() == GMOD_CHANNEL_STALLED then
            -- print("[think] stalled retry")
            -- dermaBase.mediaplayer:retry()
            -- print("stalled so return")
            -- return
        -- end


        -- allow seek at depressed pos
        if dermaBase.sliderseek:IsCursorMoved() then
            return
        end

        -- if not self:is_stopped() or self:clientHasControl() then
        if not self:is_stopped() then
            -- if self:hasState() == GMOD_CHANNEL_STOPPED then
            --     self:setstop(true)



            -- if self:hasState() == GMOD_CHANNEL_PLAYING then
                dermaBase.sliderseek:AllowSeek(true)
                dermaBase.sliderseek:SetTime(self:getTime())
            -- end
        elseif self:is_looped() then
            -- restart if
            dermaBase.sliderseek:AllowSeek(true)
            dermaBase.sliderseek:SetTime(dermaBase.sliderseek:GetMin())
        elseif dermaBase.mediaplayer:is_autoplaying() then
            print("Media is autoplayed so play next song")

            self:playNext()
        -- else
        --     print("AUDIO STOPPED v2")
        --     if dermaBase.main:IsServerMode() then
        --         self:sv_stop()
        --         net.Start("sv_stop_live")
        --         net.SendToServer()
        --     else
        --         self:cl_stop()
        --     end
        end
	end
end
-----------------------------------------------------------------------------
Media.ToggleListenUI = ToggleListenUI
Media.ToggleNormalUI = ToggleNormalUI
Media.real_time_seek = real_time_seek
-----------------------------------------------------------------------------
--[[
    In case host disconnects or loses admin role
--]]
local function song_host_disconnected(ply)
  dermaBase.labelswap:SetText(
    "Unavailable: " .. dermaBase.interface.get_song_host())
  ply:PrintMessage(HUD_PRINTCONSOLE,
    "[gMusic Player] Cannot get Live Song. The host is unavailable.")
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






-- net.Receive("askAdminForLiveSeek", function(length, sender)
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
    net.Receive("cl_stop_live", function(length, sender)
        dermaBase.mediaplayer:sv_stop()
        dermaBase.labelswap:SetText("No song currently playing")
    end)

    net.Receive("cl_play_live", function(length, sender)
        local live_song = net.ReadString()
        if live_song == nil or #live_song == 0 then return end
        chat.AddText(Color(0,220,220), "[gMusic Player] Playing: " ..
          string.StripExtension(string.GetFileFromFilename(live_song)))

        local is_looped = net.ReadBool()
        local is_autoplayed = net.ReadBool()
        local index_song = net.ReadUInt(16)
        local live_host = net.ReadEntity()
        dermaBase.interface.set_song_host(live_host)

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
          -- print("[net] update sv song", index_song, live_song, "| loop:", is_looped, "| autoplay:", is_autoplayed)
          dermaBase.mediaplayer:updateServer(live_song, index_song, is_autoplayed, is_looped)
        end

        -- this should be more like play song but muted
        -- if not dermaBase.mediaplayer:clientHasControl() then
        --     dermaBase.mediaplayer:playServer(live_song, index_song, is_autoplayed, is_looped)
        -- end
    end)

    net.Receive("cl_set_loop", function(length, sender)
        if not dermaBase.mediaplayer:hasValidity() or not dermaBase.main:IsServerMode() then return end

        local is_looped = net.ReadBool()
        dermaBase.mediaplayer:setloop(is_looped)
        if dermaBase.mediaplayer:hasState() == GMOD_CHANNEL_PLAYING then
            if is_looped then
                dermaBase.mediaplayer:uiLoop()
            elseif dermaBase.mediaplayer:is_autoplaying() then
                dermaBase.mediaplayer:uiAutoPlay()
            else
                dermaBase.mediaplayer:uiPlay()
            end
        end
    end)

    net.Receive("cl_set_autoplay", function(length, sender)
        if not dermaBase.mediaplayer:hasValidity() or not dermaBase.main:IsServerMode() then return end

        local is_autoplayed = net.ReadBool()
        print("[net] sv autoplay:", is_autoplayed)
        dermaBase.mediaplayer:setautoplay(is_autoplayed)
        if dermaBase.mediaplayer:clientHasControl() then return end

        if dermaBase.mediaplayer:hasState() == GMOD_CHANNEL_PLAYING then
            if is_autoplayed then
                dermaBase.mediaplayer:uiAutoPlay()
            elseif dermaBase.mediaplayer:is_looped() then
                dermaBase.mediaplayer:uiLoop()
            else
                dermaBase.mediaplayer:uiPlay()
            end
        end
    end)

    net.Receive("cl_pause_live", function(length, sender)
      if not dermaBase.main:IsServerMode() then return end
      -- local live_song = net.ReadString()
      -- dermaBase.mediaplayer:uiTitle(live_song)

      -- if dermaBase.mediaplayer:clientHasControl() then return end
      local is_server_pause = net.ReadBool()
      -- print("[net] sv pause:",is_server_pause)
      if LocalPlayer():IsAdmin() then
        print("[net] pause sv:", is_server_pause)
        dermaBase.mediaplayer:sv_pause(is_server_pause)
        dermaBase.mediaplayer:sv_uiRefresh()
        net.Start("sv_update_song_state")
        net.WriteBool(dermaBase.mediaplayer:is_paused())
        net.WriteBool(dermaBase.mediaplayer:is_autoplaying())
        net.WriteBool(dermaBase.mediaplayer:is_looped())
        net.SendToServer()
        return
      end

      if is_server_pause then
        dermaBase.mediaplayer:sv_pause(is_server_pause)
        dermaBase.mediaplayer:sv_uiRefresh()
      else
        net.Start("sv_play_live_seek_from_host")
        net.SendToServer()
      end

      -- if is_server_pause then
      --     dermaBase.mediaplayer:uiPause()
      -- else
      --     dermaBase.mediaplayer:uiP
      -- end



      -- if is_server_paused then
      --     -- if dermaBase.mediaplayer:hasValidity() then
      --     --     dermaBase.mediaplayer:setpause(is_server_paused)
      --     -- else
      --     net.Start("sv_refresh_song_state")
      --     net.SendToServer()
      --     -- end
      -- else
      --     net.Start("sv_play_live_seek_from_host")
      --     net.SendToServer()
      -- end
    end)


    net.Receive("cl_play_live_seek_from_host", function(length, sender)
      local user = net.ReadEntity()
      if not IsValid(sender) or not sender:IsAdmin() then
        song_host_disconnected(user)
        return
      end

      -- grab audio from first admin
      print("[net] play live for user:", user)
      if dermaBase.mediaplayer:hasValidity() then
        net.Start("sv_play_live_seek_for_user")
        net.WriteEntity(user)
        net.WriteDouble(dermaBase.mediaplayer:getServerTime())
        net.SendToServer()
      else
        user:PrintMessage(HUD_PRINTTALK,
          "[gMusic Player] No song is playing on the server")
      end
    end)
    net.Receive("cl_play_live_seek", function(length, sender)
        if not dermaBase.main:IsServerMode() then return end
        -- dermaBase.set_server_TSS(true)
        local live_seek = net.ReadDouble()
        local live_song = net.ReadString()
        local live_song_index = net.ReadUInt(16)
        local is_autoplayed = net.ReadBool()
        local is_looped = net.ReadBool()

        print("[net] seek sv song:", live_song_index, live_seek, "| loop:", is_looped, "| autoplay:", is_autoplayed)
        -- dermaBase.mediaplayer:clientControl(false)
        -- might change it with simple play and pass the PlayingServer obj
        dermaBase.mediaplayer:playServer(
            live_song, live_song_index, is_autoplayed, is_looped, live_seek)
    end)

    net.Receive("cl_refresh_song_state", function(length, sender)
        local is_paused = net.ReadBool()
        local is_autoplayed = net.ReadBool()
        local is_looped = net.ReadBool()
        local live_seek = net.ReadDouble()
        local live_song = net.ReadString()
        local live_song_index = net.ReadUInt(16)
        local live_host = net.ReadEntity()

        print("[net] update state| loop:", is_looped, "| autoplay:", is_autoplayed, "| pause:", is_paused)

        -- sync with server only if needed
        -- if is_paused then
        --     dermaBase.mediaplayer:setpause(is_paused)
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
        dermaBase.mediaplayer:updateServer(live_song, live_song_index, is_autoplayed, is_looped, live_seek)
        if is_paused then
            dermaBase.mediaplayer:sv_pause()
            dermaBase.mediaplayer:uiPause()
            -- dermaBase.mediaplayer:setpause(is_paused)
        end
        dermaBase.interface.set_song_host(live_host)
    end)

    -- net.Receive("cl_update_host", function(length, sender)
    --     local live_host = net.ReadEntity()
    --     print("[net] update host:", live_host)
    --     dermaBase.interface.set_song_host(live_host)
    -- end)



    -- TODO WORK ON adding the song table of the admin host on the server and tehn you just
    --increment from that table the next song.
    --If the same admin host tries to change the song check if it is the same admin and if not
    --check if the song basename is the one he wants to play(the key probably wont be a good idea)
    -- net.Receive( "cl_ansAutoPlaySong", function(length, sender)
    -- 	local nextAutoPlayedSong = net.ReadString()
    -- 	-- local currSong = populatedSongs[dermaBase.mediaplayer:songIndex(1, true)] or ""
    -- 	dermaBase.mediaplayer:uiAutoPlay()
    -- 	dermaBase.mediaplayer:playServer(nextAutoPlayedSong)
    -- end)

    net.Receive("cl_set_seek", function(length, sender)
        if dermaBase.main:IsServerMode() then
            local seekTime = net.ReadDouble()
            if dermaBase.mediaplayer:hasValidity() then
                dermaBase.mediaplayer:seek(seekTime)
            end
        end
    end)
end

return init