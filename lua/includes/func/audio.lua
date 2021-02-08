-- local cl_PlayingSong = nil
-- local sv_PlayingSong = nil
local local_player = LocalPlayer()
local missingSong = false
--[[
    Used server-side by clients as a muted live-seek indicator
--]]
local client_has_control = false
local sv_song_loaded = false

local prevSelection = 0
local currSelection = 1

local colPlay	= Color(0, 150, 0)
local colAPlay	= Color(70, 190, 180)
local colPause	= Color(255, 150, 0)
local colAPause	= Color(210, 210, 0)
local colLoop	= Color(0, 230, 0)
local colALoop	= Color(45,205,115)
local col404	= Color(240, 0, 0)
local colBlack 	= Color(0, 0, 0)
local colWhite 	= Color(230, 230, 230)
local colWhiteTitle = Color(255, 255, 255)

local dermaBase = {}
local breakOnStop = false
--[[
    Used to prevent realtime hooks from running indefinitely
--]]
local cl_think = false
local sv_think = false
--[[
    Used to prevent autoplayed songs from changing indefinitely
    Used to check if constanting thinking is required on server side
--]]
local think_autoplay = false
-- local title_status = ""
--[[
    Current active song title
--]]
-- local title_song = nil
--[[
    Current song absolute path
--]]
-- local absolute_path = nil
--[[
    Stores the last played song from client and server
--]]
local cl_song = nil
local sv_song = nil

--[[
    Used for highlighting the playing line in the song list
--]]
local cl_song_index = 1
local sv_song_index = 0
local cl_song_prev_index = 0
local sv_song_prev_index = 0



local current_song_index = 0


local cl_seek = 0
local sv_seek = 0

--[[
    Stores the client-side autoplay and loop states
--]]
local cl_isAutoPlaying = false
local cl_isLooped = false

--[[
    Stores the server-side autoplay and loop states
--]]
local sv_isAutoPlaying = false
local sv_isLooped = false

--[[
    Stores client-side pause and stop states
--]]
local cl_isPaused = false
local cl_isStopped = true

--[[
    Stores server-side pause and stop states
--]]
local sv_isPaused = false
local sv_isStopped = true
--[[
    Indicates when the next autoplayed song can start
--]]
local sv_AutoplayNext = false

--[[
    Stores the previous server-side volume. Used as a fake stop
--]]
local sv_prev_volume = 0

GMPL_AUDIO = {}
GMPL_AUDIO.new = function(self)
   local channel = {}
   local methods = {
        attrs = {
            isPaused = false,
            isLooped = false,
            isStopped = true,
            isMissing = false,
            isAutoPlaying = false,
            error = false,
            seek = 0,
            prev_volume = 0,
            title_status = "",
            title_song = 0, -- empty string marks missing
            song = "",
            song_index = 0,
            song_prev_index = 0,
            think = false,
            think_autoplay = false,
            AutoplayNext = false,
            client_has_control = false,
        },
        get = function(self)
            return channel
        end,
        get_song_name = function(self)
            return self.title_song
        end,
        set_song_name = function(self, song_name)
            self.title_song = song_name
        end,
        get_song_path = function(self)
            return self.song
        end,
        get_song_index = function(self)
            return self.song_index
        end,
        get_song_prev_index = function(self)
            return self.song_prev_index
        end,
        get_song_prefix = function(self)
            return self.title_status
        end,
        get_time = function(self)
            return channel:GetTime()
        end,
        is_paused = function(self)
            return self.isPaused
        end,
        is_looped = function(self)
            return self.isLooped
        end,
        is_autoplayed = function(self)
            return self.isAutoPlaying
        end,
        is_stopped = function(self)
            return self.isStopped
        end,
        is_playing = function(self)
            return channel:GetState() == GMOD_CHANNEL_PLAYING
        end,
        is_thinking = function(self)
            return self.think
        end,
        is_missing = function(self)
            return self.isMissing
        end,
        has_error = function(self)
            return self.error
        end,
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

            -- if is_server_mode then
            --     think_autoplay = false
            -- end
        end,
        set_autoplay = function(self, bool)
            if not self:is_playing() then return end
            if bool == nil then
                bool = not self:is_autoplayed()
            end
            channel:EnableLooping(false)
            self.isLooped = false
            self.isAutoPlaying = bool
        end,
        set_missing = function(self, bool)
            self.isMissing = bool
            if bool then
                self:set_song_prefix(" Not On Disk: ")
            end
        end,
        silent_stop = function(self)
            if self.isStopped then return end
            channel:Stop()
            channel = nil
            self.isStopped = true
            self.isPaused = false
            if dermaBase.main.IsServerMode() then
                timer.Stop("gmpl_sv_guard")
            else
                timer.Stop("gmpl_cl_guard")
            end
        end,
        mute = function(self)
            if self.isStopped then return end
            self.prev_volume = channel:GetVolume()
            channel:SetVolume(0)
        end,
        play = function(
            self, song, song_index, is_autoplay, is_loop, seek, callback)
            if isstring(song) then
                self:silent_stop()
                sound.PlayFile(song, "noblock noplay", function(CurrentSong, ErrorID, ErrorName)
                    if IsValid(CurrentSong) then
                        self.song = song
                        self.song_prev_index = self.song_index
                        self.song_index = song_index
                        self.title_song = string.StripExtension(
                            string.GetFileFromFilename(song))

                        CurrentSong:SetTime((seek or 0))
                        CurrentSong:SetVolume(dermaBase.slidervol:GetValue() / 100)

                        if not IsValid(CurrentSong) then return end
                        channel = CurrentSong
                        self.isMissing = false

                        self.isLooped = is_loop or false
                        self.isAutoPlaying = is_autoplay or false
                        channel:EnableLooping(self.isLooped)
                        if self.isLooped then
                            self.isAutoPlaying = false
                            -- channel:EnableLooping(is_loop)
                            -- self.isLooped = is_loop
                            -- self.isAutoPlaying = false
                            -- updateTitleColor(3, song)
                        else
                            -- channel:EnableLooping(false)
                            -- self.isLooped = false
                            -- self.isAutoPlaying = is_autoplay
                            -- updateTitleColor(1, song)
                        end
                        -- print("loop is:", CurrentSong:IsLooping())
                        -- print("autoplay is:", isAutoPlaying)
                        dermaBase.sliderseek:AllowSeek(true)
                        dermaBase.sliderseek:SetMax(CurrentSong:GetLength())
                        dermaBase.contextmedia:SetSeekLength(CurrentSong:GetLength())

                        channel:Play()
                        self.isPaused = false
                        self.isStopped = false
                        self.think = true
                        self.error = false
                        if callback ~= nil then
                            callback(true)
                        end
                    else
                        dermaBase.sliderseek:ResetValue()
                        self.error = true
                        callback(false)
                    end
                end)
            end
        end,

        resume = function(self)
            if self.isStopped then return end
            if self.isPaused then
                channel:Play()
                self.isPaused = false
                self.isStopped = false
            end
        end,
        pause = function(self)
            if channel:GetState() == GMOD_CHANNEL_PLAYING then
                channel:Pause()
                self.isPaused = true
                self.isStopped = false
            elseif channel:GetState() == GMOD_CHANNEL_PAUSED and
                not self.isStopped then
                channel:Play()
                self.isPaused = false
                self.isStopped = false
            end
        end,
        stop = function(self)
            if self.isStopped then return end
            -- reset_ui()
            self.title_song = 0
            self.title_status = ""
            channel:Pause()

            self.song = ""
            self.isStopped = true
            self.isPaused = false
            self.think = false

            self.client_has_control = false
            self.think_autoplay = false
            self.AutoplayNext = true
        end,

        IsValid = function(self)
            return IsValid(channel)
        end,
   }

   local mt = {
      __index = function(self, k)
         local v = rawget(self.attrs, k)
         if v ~= nil then
            return v
         elseif v == nil then
            local_player:PrintMessage(HUD_PRINTCONSOLE,
                "[gMusic Player] Unhandled error code 2 on key", k)
         end

         if k == 'keys' then
            local ks = {}
            for k,v in next, self.attrs, nil do
               ks[k] = 'attr'
            end
            for k,v in next, methods, nil do
               ks[k] = 'func'
            end
            return ks
         end
      end,

      __metatable = {},

      __newindex = function(self, k, v)
        if v == nil then
            local_player:PrintMessage(HUD_PRINTCONSOLE,
                "[gMusic Player] Unhandled error code 2 on key", k)
        elseif rawget(self.attrs, k) ~= nil then
            rawset(self.attrs, k, v)
        end
      end,
   }
   setmetatable(methods, mt)
   return methods
end

-- local cl_PlayingSong = GMPL_AUDIO.new()
-- local sv_PlayingSong = GMPL_AUDIO.new()















local function isCurrentMediaValid(self)
    if dermaBase.main.IsServerMode() then
        return IsValid(self.sv_PlayingSong)
    else
        return IsValid(self.cl_PlayingSong)
    end
end

local function isOtherMediaValid(self)
    if dermaBase.main.IsServerMode() then
        return IsValid(self.cl_PlayingSong)
    else
        return IsValid(self.sv_PlayingSong)
    end
end

local function getMedia(self)
    if dermaBase.main.IsServerMode() then
	    return self.sv_PlayingSong:get()
    else
	    return self.cl_PlayingSong:get()
    end
end

local function get_audio_channel(self)
    if dermaBase.main.IsServerMode() then
        return self.sv_PlayingSong
    else
        return self.cl_PlayingSong
    end
end

local function isThinking(self)
    if dermaBase.main.IsServerMode() then
        return self.sv_PlayingSong:is_thinking()
    else
        return self.cl_PlayingSong:is_thinking()
    end
end

local function enableTSS()
    if not dermaBase.main:IsTSSEnabled() then
		dermaBase.main:SetTSSEnabled(true)
	end
end

local function disableTSS()
	if dermaBase.main:IsTSSEnabled() then
		dermaBase.main:SetTSSEnabled(false)
		dermaBase.contextmedia:SetTSS(false)
	end

    local prev_selection = 0
    local curr_selection = 0
    if dermaBase.main.IsServerMode() then
        prev_selection = sv_song_prev_index
        curr_selection = sv_song_index
    else
        prev_selection = cl_song_prev_index
        curr_selection = cl_song_index
    end
	if IsValid(dermaBase.songlist:GetLines()[prev_selection]) then
		dermaBase.songlist:HighlightLine(curr_selection, false, false)
	end
end

local function updateTitleSong(status, media)
    if media:is_stopped() then
        dermaBase.main:SetTitle(" gMusic Player")
        dermaBase.main:SetTSSEnabled(false)
        dermaBase.contextmedia:SetTextColor(colBlack)
        dermaBase.contextmedia:SetText(false)
        disableTSS()
        return ""
    else
        enableTSS()
        local song_filepath = media:get_song_path()
        -- local media = 0
        -- if dermaBase.main.IsServerMode() then
        --     media = gmpl_audio.sv_PlayingSong
        -- else
        --     media = gmpl_audio.cl_PlayingSong
        -- end
        if status == false then
            media:set_missing(true)
            dermaBase.main:SetTitleBGColor(col404)
            dermaBase.contextmedia:SetTextColor(col404)
            dermaBase.contextmedia:SetMissing(true)
            MsgC(Color(100, 200, 200), "[gMusic Player]",
                Color(255, 255, 255),
                " Song file missing:\n> ", song_filepath, "\n")
        end

        if song_filepath then
            local title_song = media:get_song_name()
            dermaBase.main:SetTitle(media:get_song_prefix() .. title_song)
            dermaBase.contextmedia:SetText(title_song)
            return title_song
        end
        return media:get_song_name()
    end
end

-- Keep for refference until an alternative is made
local function updateListSelection(color, textcolor, gmpl_audio)
    local sv_song_index = gmpl_audio.sv_PlayingSong:get_song_index()
    local cl_song_index = gmpl_audio.cl_PlayingSong:get_song_index()

    if dermaBase.main.IsServerMode() then
        local sv_song_prev_index =
            gmpl_audio.sv_PlayingSong:get_song_prev_index()
        -- if it cant find the song number then better not bother coloring
        if IsValid(dermaBase.songlist:GetLines()[sv_song_index]) then
            dermaBase.songlist:HighlightLine(sv_song_index, color, textcolor)
        end
        if IsValid(dermaBase.songlist:GetLines()[sv_song_prev_index]) and
            sv_song_prev_index ~= sv_song_index then
            dermaBase.songlist:HighlightLine(sv_song_prev_index, false, false)
        end
        if (cl_song_index ~= sv_song_index) then
            dermaBase.songlist:HighlightLine(cl_song_index, false, false)
        end
        sv_song_prev_index = sv_song_index
    else
        local cl_song_prev_index =
            gmpl_audio.cl_PlayingSong:get_song_prev_index()
        -- if it cant find the song number then better not bother coloring
        if IsValid(dermaBase.songlist:GetLines()[cl_song_index]) then
            dermaBase.songlist:HighlightLine(cl_song_index, color, textcolor)
        end
        if IsValid(dermaBase.songlist:GetLines()[cl_song_prev_index]) and
            cl_song_prev_index ~= cl_song_index then
            dermaBase.songlist:HighlightLine(cl_song_prev_index, false, false)
        end
        if (cl_song_index ~= sv_song_index) then
            dermaBase.songlist:HighlightLine(sv_song_index, false, false)
        end
        cl_song_prev_index = cl_song_index
    end
end

-- TODO USE this but adapt so params works as the above one
local function updateListSelection2(media, color, textcolor)
    local song_index = media:get_song_index()
    local prev_song_index = media:get_song_prev_index()

    -- if it cant find the song number then better not bother coloring
    if textcolor == false then
        textcolor = dermaBase.songlist:GetDefaultTextColor()
    end

    if IsValid(dermaBase.songlist:GetLines()[song_index]) then
        dermaBase.songlist:HighlightLine(song_index, color, textcolor)
    end
    if IsValid(dermaBase.songlist:GetLines()[prev_song_index]) then
        dermaBase.songlist:HighlightLine(cl_song_prev_index, false, false)
    end
    -- if (song_index ~= sv_song_index) then
    --     dermaBase.songlist:HighlightLine(sv_song_index, false, false)
    -- end
    -- prev_song_index = song_index

end

local function updateTitleColor(status, channel)
    local is_server_mode = dermaBase.main.IsServerMode()
    local color_bg = Color(150, 150, 150)
    local color_text = colWhite
    local is_auto_playing = channel:is_autoplayed()
    if status == 1 then
        if is_auto_playing then
            channel:set_song_prefix(" Auto Playing: ")
            color_bg = colAPlay
            color_text = colBlack
        else
            channel:set_song_prefix(" Playing: ")
            color_bg = colPlay
            color_text = colWhite
        end
    else
        if status == 2 then
            channel:set_song_prefix(" Paused: ")
            if is_server_mode then
                if shared_settings:get_admin_server_access() then
                    if client_has_control then
                        color_bg = colAPause
                        color_text = colBlack
                    else
                        color_bg = colPause
                        color_text = colBlack
                    end
                else
                    color_bg = colPause
                    color_text = colBlack
                end
            else
                color_bg = colPause
                color_text = colBlack
            end
        elseif status == 3 then
            channel:set_song_prefix(" Looping: ")
            color_bg = colLoop
            color_text = colBlack
        end
    end
    if status == false or (status == 1 and not is_auto_playing) then
        dermaBase.main:SetTitleColor(colWhiteTitle)
    else
        dermaBase.main:SetTitleColor(color_text)
    end
    dermaBase.main:SetTitleBGColor(color_bg)
    dermaBase.contextmedia:SetTextColor(color_bg)
    -- local result = 0
    -- if is_server_mode then
        -- updateListSelection(false, false, is_server_mode)
        -- result = updateTitleSong(status, media)
    -- else
        -- updateListSelection(color_bg, color_text, is_server_mode)
    updateTitleSong(status, channel)
    -- end
    return color_bg, color_text
end

local function forced_loop(self, bool, is_server_mode)
    if not isCurrentMediaValid() then return end
    if not isbool(is_server_mode) then
        is_server_mode = dermaBase.main.IsServerMode()
    end

    local media = getMedia(self)
    media:EnableLooping(bool)
    if is_server_mode then
        sv_isLooped = bool
        sv_isAutoPlaying = false
        think_autoplay = false
    else
        cl_isLooped = bool
        cl_isAutoPlaying = false
    end
end
local function forced_autoplay(self, bool, is_server_mode)
    if not isCurrentMediaValid() then return end
    if not isbool(is_server_mode) then
        is_server_mode = dermaBase.main.IsServerMode()
    end

    local media = getMedia(self)
    media:EnableLooping(false)
    if is_server_mode then
        sv_isLooped = false
        sv_isAutoPlaying = bool
    else
        cl_isLooped = false
        cl_isAutoPlaying = bool
    end
end

--[[
    Kill the client audio object
--]]
local function kill_cl_song(self)
    if not IsValid(cl_PlayingSong) then return end

    self.cl_PlayingSong:get():Stop()
    self.cl_PlayingSong = nil
    cl_isStopped = true
    cl_isPaused = false
    timer.Stop("gmpl_cl_guard")
end
--[[
    Server audio object needs to live for autoplay to work
--]]
local function mute_sv_song(self)
    if not IsValid(self.sv_PlayingSong) then return end
    self.sv_PlayingSong:get():Stop()
    sv_prev_volume = self.sv_PlayingSong:get():GetVolume()
    self.sv_PlayingSong:get():SetVolume(0)
    sv_isPaused = false
    sv_isStopped = true
end
local function kill_song(self)
    if not isCurrentMediaValid() then return end

    if dermaBase.main.IsServerMode() then
        -- print("[core_kill] kill server")
        self.sv_PlayingSong:get():Stop()
        sv_isStopped = true
        sv_isPaused = false
        timer.Stop("gmpl_sv_guard")
    else
        -- print("[core_kill] kill client")
        self.cl_PlayingSong:get():Stop()
        self.cl_PlayingSong = nil
        cl_isStopped = true
        cl_isPaused = false
        timer.Stop("gmpl_cl_guard")
    end
end

local function updateAudioObject(self, CurrentSong, on_server)
	if not IsValid(CurrentSong) then return end

    if on_server then
        self.sv_PlayingSong = CurrentSong
        missingSong = false
    else
        self.cl_PlayingSong = CurrentSong
        missingSong = false
    end
end

-------------------------------------------------------------------------------
local function songLooped(self)
    if dermaBase.main.IsServerMode() then
        return self.sv_PlayingSong:is_looped()
    else
        return self.cl_PlayingSong:is_looped()
    end
end
local function sv_is_autoplay()
    return sv_isAutoPlaying
end
local function cl_is_autoplay()
    return cl_isAutoPlaying
end
local function songAutoPlay()
    if dermaBase.main.IsServerMode() then
        return sv_isAutoPlaying
    else
        return cl_isAutoPlaying
    end
end

local function songMissing(self)
    if dermaBase.main.IsServerMode() then
        return self.sv_PlayingSong:is_missing()
    else
        return self.cl_PlayingSong:is_missing()
    end
end
local function sv_is_stop()
    return sv_isStopped
end
local function cl_is_stop()
    return cl_isStopped
end
local function songStopped(self)
    if dermaBase.main.IsServerMode() then
        return self.sv_PlayingSong:is_stopped()
    else
        return self.cl_PlayingSong:is_stopped()
    end
end
local function sv_is_pause()
    return sv_isPaused
end
local function cl_is_pause()
    return cl_isPaused
end
local function songPaused(self)
    if dermaBase.main.IsServerMode() then
        return self.sv_PlayingSong:is_paused()
    else
        return self.cl_PlayingSong:is_paused()
    end
end
local function songState(self) return getMedia(self):GetState() end
local function songLength(self) return getMedia(self):GetLength() end
local function songTime(self) return getMedia(self):GetTime() end
local function songServerTime(self)
    if IsValid(self.sv_PlayingSong) then
        return self.sv_PlayingSong:get_time()
    end
    return 0
end
local function volumeState(self) return getMedia(self):GetVolume() end
local function songVol(time) getMedia(self):SetVolume(time) end
--[[
    Used to allow clients to pause on server but only on their side
    Server songs will still be updated
--]]
local function clientHasControl() return client_has_control end
local function clientSetControl(bool)
    client_has_control = bool
end

local function uiPlay(self)
    local media = self:get_audio_channel()
	updateTitleColor(1, media)
end
local function uiPause(self)
    local media = self:get_audio_channel()
	updateTitleColor(2, media)
end
local function uiLoop(self)
    local media = self:get_audio_channel()
	updateTitleColor(3, media)
end
local function sv_tss_refresh(self)
    if self.sv_PlayingSong:is_paused() then
        updateTitleColor(2, self.sv_PlayingSong)
    elseif self.sv_PlayingSong:is_looped() then
        updateTitleColor(3, self.sv_PlayingSong)
    else
        updateTitleColor(1, self.sv_PlayingSong)
    end
end
local function uiTitle(self, song_path)
    updateTitleSong(true, self)
end

local function uiAPlay()
    if not isCurrentMediaValid() then return end
    local media = get_audio_channel()

	if media:is_playing() then
		updateTitleColor(1, media)
	elseif media:is_paused() then
		updateTitleColor(2, media)
	end
end


local function playSong(self, song, song_index, is_autoplay, is_loop, seek)
    self.cl_PlayingSong:play(
        song, song_index, is_autoplay, is_loop, seek, function(is_valid)
            local status = false
            if is_valid then
                self.sv_PlayingSong:mute()
                timer.Start("gmpl_cl_guard")
                if self.cl_PlayingSong:is_looped() then
                    status = 3
                else
                    status = 1
                end
            end
            local color_bg, color_text =
                updateTitleColor(status, self.cl_PlayingSong)
            updateListSelection(color_bg, color_text, self)
        end)
    -- print("song_inner:", song)
    -- print("song:", cl_PlayingSong:get_song_name(),
    --     cl_PlayingSong:get_song_path())


    -- if isstring(song) then
    --     kill_song()
    --     sound.PlayFile(song, "noblock noplay", function(CurrentSong, ErrorID, ErrorName)
    --         if IsValid(CurrentSong) then
    --             cl_song = song
    --             cl_song_index = song_index
    --             -- autoplay has priority
    --             -- print("recv loop, autoplay:", is_loop, is_autoplay)
    --             local is_looping = (is_loop or false)
    --             local is_autoplaying = (is_autoplay or false)
    --             if is_looping and is_autoplay then
    --                 is_looping = false
    --             end
    --             -- print("loop, autoplay after:", is_loop, is_autoplay)
    --             -- print("loop, autoplay sanity:", is_looping, is_autoplaying)
    --             CurrentSong:SetTime((seek or 0))
    --             CurrentSong:SetVolume(dermaBase.slidervol:GetValue() / 100)
    --             updateAudioObject(CurrentSong, false)
    --             if is_looping then
    --                 forced_loop(is_looping, false)
    --                 updateTitleColor(3, song)
    --             else
    --                 forced_autoplay(is_autoplaying, false)
    --                 updateTitleColor(1, song)
    --             end
    --             -- print("loop is:", CurrentSong:IsLooping())
    --             -- print("autoplay is:", isAutoPlaying)
    --             dermaBase.sliderseek:AllowSeek(true)
    --             dermaBase.sliderseek:SetMax(CurrentSong:GetLength())
    --             dermaBase.contextmedia:SetSeekLength(CurrentSong:GetLength())

    --             cl_PlayingSong:Play()
    --             cl_isPaused = false
    --             cl_isStopped = false
    --             mute_sv_song()
    --             cl_think = true
    --             timer.Start("gmpl_cl_guard")
    --         else
    --             updateTitleColor(false, song)
    --             dermaBase.sliderseek:ResetValue()
    --         end
    --     end)
    -- end
end
local function playSongServer(song, song_index, is_autoplay, is_loop, seek)
    if isstring(song) then
        kill_song()
        sv_song_loaded = false
        sound.PlayFile(song, "noblock noplay", function(CurrentSong, ErrorID, ErrorName)
            if IsValid(CurrentSong) then
                sv_song = song
                sv_song_index = song_index
                -- autoplay has priority
                local is_looping = (is_loop or false)
                local is_autoplaying = (is_autoplay or false)
                if is_looping and is_autoplay then
                    is_looping = false
                end
                CurrentSong:SetTime((seek or 0))
                CurrentSong:SetVolume(dermaBase.slidervol:GetValue() / 100)
                updateAudioObject(CurrentSong, true)

                dermaBase.sliderseek:AllowSeek(true)
                dermaBase.sliderseek:SetMax(CurrentSong:GetLength())
                dermaBase.contextmedia:SetSeekLength(CurrentSong:GetLength())
                if is_looping then
                    forced_loop(is_looping, true)
                    if client_has_control then
                        updateTitleColor(2, song)
                        mute_sv_song()
                    else
                        updateTitleColor(3, song)
                    end
                else
                    forced_autoplay(is_autoplaying, true)
                    if client_has_control then
                        updateTitleColor(2, song)
                        mute_sv_song()
                    else
                        updateTitleColor(1, song)
                    end
                end
                self.sv_PlayingSong:get():Play()
                sv_isPaused = false
                sv_isStopped = false
                sv_AutoplayNext = false
                sv_prev_volume = 0
                kill_cl_song()
                sv_think = true
                timer.Start("gmpl_sv_guard")
            else
                updateTitleColor(false, song)
                dermaBase.sliderseek:ResetValue()
            end
        end)
        sv_song_loaded = true
    end
end

local function updateSongServer(self, song, song_index, is_autoplay, is_loop, seek)
    if isstring(song) then
        sound.PlayFile(song, "noblock noplay", function(CurrentSong, ErrorID, ErrorName)
            if IsValid(CurrentSong) then
                sv_song = song
                sv_song_index = song_index
                -- autoplay has priority
                local is_looping = (is_loop or false)
                local is_autoplaying = (is_autoplay or false)
                if is_looping and is_autoplay then
                    is_looping = false
                end
                CurrentSong:SetTime((seek or 0))
                CurrentSong:SetVolume(0)
                updateAudioObject(CurrentSong, true)
                if is_looping then
                    forced_loop(is_looping, true)
                else
                    forced_autoplay(is_autoplaying, true)
                end
                if isnumber(seek) then
                    dermaBase.sliderseek:SetTime(seek)
                end
                self.sv_PlayingSong:get():Play()
                sv_isPaused = false
                sv_isStopped = false
                sv_AutoplayNext = false
                kill_cl_song()
                -- sv_think = true
            else
                updateTitleColor(false, song)
                dermaBase.sliderseek:ResetValue()
            end
        end)
    end
end

local function updateSongClient(self, song, song_index, is_autoplay, is_loop, seek)
    if isstring(song) then
        sound.PlayFile(song, "noblock noplay", function(CurrentSong, ErrorID, ErrorName)
            if IsValid(CurrentSong) then
                cl_song = song
                cl_song_index = song_index
                -- autoplay has priority
                local is_looping = (is_loop or false)
                local is_autoplaying = (is_autoplay or false)
                if is_looping and is_autoplay then
                    is_looping = false
                end
                CurrentSong:SetTime((seek or 0))
                CurrentSong:SetVolume(0)
                updateAudioObject(CurrentSong, false)
                if is_looping then
                    forced_loop(is_looping, false)
                else
                    forced_autoplay(is_autoplaying, false)
                end

                self.cl_PlayingSong:get():Play()
                cl_isPaused = false
                cl_isStopped = false
                mute_sv_song()
                -- think = true
            else
                updateTitleColor(false, song)
                dermaBase.sliderseek:ResetValue()
            end
        end)
    end
end
--[[
    Protect against seek burst which causes buffering block
--]]
local function sv_buffer_guard(self)
    if IsValid(self.sv_PlayingSong) then
        if self.sv_PlayingSong:get():GetState() == GMOD_CHANNEL_STALLED then
            dermaBase.sliderseek:ReleaseSeek()
            dermaBase.sliderseek:AllowSeek(true)
            self.sv_PlayingSong:get():SetTime(self.sv_PlayingSong:get():GetTime() - 1)
            print("[sv_stall_stop] play song cuz stalled")
        end
    end
end
--[[
    Protect against seek burst which causes buffering block
--]]
local function cl_buffer_guard(self)
    if IsValid(self.cl_PlayingSong) then
        if self.cl_PlayingSong:get():GetState() == GMOD_CHANNEL_STALLED then
            dermaBase.sliderseek:ReleaseSeek()
            dermaBase.sliderseek:AllowSeek(true)
            self.cl_PlayingSong:get():SetTime(self.cl_PlayingSong:get():GetTime() - 1)
            print("[cl_stall_stop] play song cuz stalled")
        end
    end
end

local function playSongNext()
    local next_selection = cl_song_index + 1
    local song_list = dermaBase.song_data:get_current_list()
    print("[core-line] next selection:", next_selection)
    if next_selection > #song_list then
        next_selection = 1
    end
    if not dermaBase.main.IsServerMode() then
        self:play(song_list[next_selection], next_selection, true)
        cl_think = false
    else
        sv_think = false
    end


    dermaBase.songlist:SetSelectedLine(next_selection)
	-- if it cant find the song number then better not bother coloring
	-- if IsValid(dermaBase.songlist:GetLines()[currSelection]) then
	-- 	dermaBase.songlist:HighlightLine(currSelection, color, textcolor)
	-- 	if textcolor then
	-- 		dermaBase.main:SetTextColor(textcolor)
	-- 	end
end

-- local function playServerSongNext()
--     local next_selection = sv_song_index + 1
--     local song_list = dermaBase.song_data:get_current_list()
--     if next_selection > #song_list then
--         next_selection = 1
--     end
--     net.Start("sv_play_live")
--     net.WriteString(song_list[next_selection])
--     net.WriteUInt(next_selection, 16)
--     net.SendToServer()
--     dermaBase.songlist:SetSelectedLine(next_selection)
--     think = false
-- end

--[[
    Used to keep track when the server song stopped in case autoplay is enabled
    Should no longer run if stopped
--]]
local function checkServerStop(self)
    if sv_think and IsValid(self.sv_PlayingSong) then
        -- print("[think] think aplay is:", sv_think, think_autoplay)
        sv_isStopped = self.sv_PlayingSong:get():GetState() == GMOD_CHANNEL_STOPPED
        if sv_isStopped then
            -- will swap flags because sv_think is set later in cl_play_live
            sv_think = false
            think_autoplay = true
        end
    end
end
--[[
    Check next autoplayed song
    Works together with checkServerStop() in order to play only once
--]]
local function serverAutoPlayThink()
    if shared_settings:get_admin_server_access() then
        if not local_player:IsAdmin() then return end
    end
    if not think_autoplay or not sv_isAutoPlaying then return end

    if sv_isStopped then
        think_autoplay = false
        local next_selection = sv_song_index + 1
        local song_list = dermaBase.song_data:get_current_list()
        if next_selection > #song_list then
            next_selection = 1
        end
        print("[core-svthink] autoplay on so play next", next_selection)
        net.Start("sv_play_live")
        net.WriteString(song_list[next_selection])
        net.WriteUInt(next_selection, 16)
        net.SendToServer()
        dermaBase.songlist:SetSelectedLine(next_selection)
    end
end

local function resumeSong(self, song, song_index)
    local channel = get_audio_channel(self)
    channel:resume()

    local color_bg, color_text = {}, {}
    if channel:is_looped() then
        color_bg, color_text = updateTitleColor(3, channel)
    else
        color_bg, color_text = updateTitleColor(1, channel)
    end
    updateListSelection(color_bg, color_text, self)
	-- if title_song == song and not songStopped() then
	-- 	getMedia(self):Play()
    --     if dermaBase.main.IsServerMode() then
    --         sv_think = true
    --     else
    --         cl_think = true
    --     end
	-- 	if songLooped then
	-- 		updateTitleColor(3, song)
	-- 	else
	-- 		updateTitleColor(1, song)
	-- 	end
	-- else
	-- 	self:play(song, song_index)
	-- end
end

local function reset_ui(self, media)
    dermaBase.sliderseek:ResetValue()
    dermaBase.sliderseek:AllowSeek(false)
    updateTitleColor(false, media)
    updateListSelection2(media, false, false)
end

local function action_sv_pause(bool_pause)
    if sv_isStopped then return end
    if isbool(bool_pause) then
        -- used as a setter
        sv_isPaused = not bool_pause
    end
    if sv_isPaused then
        sv_isPaused = false
        self.sv_PlayingSong:get():Play()
        sv_think = true
    else
        sv_isPaused = true
        self.sv_PlayingSong:get():Pause()
        sv_think = false
    end
end
local function action_cl_pause(self)
    if cl_isStopped then return end
    cl_isPaused = not cl_isPaused
    self.cl_PlayingSong:get():Pause()
    cl_think = false
    print("[cl_pause] song pause:", cl_isPaused)
end
local function action_sv_stop(self)
    self.sv_PlayingSong:stop()
    if self.sv_PlayingSong:is_stopped() then
        reset_ui()
        timer.Stop("gmpl_sv_guard")
    end

    -- if sv_isStopped then return end
    -- print("[sv_stop] stop song")

    -- reset_ui()
    -- title_song = nil
    -- client_has_control = false
    -- if IsValid(sv_PlayingSong) then
    --     sv_PlayingSong:get():Pause()
    -- end
    -- sv_song = nil
    -- sv_isStopped = true
    -- sv_isPaused = false
    -- think_autoplay = false
    -- sv_AutoplayNext = true
    -- sv_think = false
    -- timer.Stop("gmpl_sv_guard")
end
local function action_cl_stop(self)
    self.cl_PlayingSong:stop()
    if self.cl_PlayingSong:is_stopped() then
        self:reset_ui(self.cl_PlayingSong)
        timer.Stop("gmpl_cl_guard")
    end
    -- if cl_PlayingSong:is_stopped() then return end
    -- cl_PlayingSong:set_song_name(nil)
    -- if IsValid(cl_PlayingSong) then
    --     cl_PlayingSong:get():Pause()
    -- end
    -- cl_song = nil
    -- cl_isStopped = true
    -- cl_isPaused = false
    -- cl_think = false
end



local function updateAudioStates(self, in_server_mode)

    if not isbool(in_server_mode) then return end
    print("\n")
    -- print("[core-states] client loop, autoplay:", cl_isLooped, cl_isAutoPlaying)
    -- print("[core-states] server loop, autoplay:", sv_isLooped, sv_isAutoPlaying)
    if in_server_mode then
        -- print("[core_svstates] song:", sv_song)
        if isOtherMediaValid() then
            print("[core_svstates] muting client")
            cl_seek = self.cl_PlayingSong:get():GetTime()
            kill_cl_song()
        end

        if isstring(sv_song) then
            dermaBase.main:SetTitleServerState(true)
            dermaBase.contextmedia:SetTSS(true)
            title_song = sv_song
            -- update server side seek and also live seek from it

            -- if not client_has_control then
                net.Start("sv_play_live_seek")
                net.WriteDouble(songServerTime())
                net.SendToServer()
            -- end
            if sv_prev_volume ~= 0 then
                self.sv_PlayingSong:get():SetVolume(sv_prev_volume)
            end

            if sv_isStopped or client_has_control then return end
            -- print("[core-states] is loop, autoplay:", getMedia():IsLooping(), songAutoPlay())
            if songLooped() then
                updateTitleColor(3, title_song)
            else
                updateTitleColor(1, title_song)
            end
        else
            action_sv_stop()
            reset_ui()
        end
    else
        -- print("[core_clstates] song:", cl_song)
        if isOtherMediaValid() then
            print("[core_clstates] muting server")
            sv_seek = self.sv_PlayingSong:get():GetTime()
            mute_sv_song()
        end

        if isstring(cl_song) then
            dermaBase.main:SetTitleServerState(false)
            dermaBase.contextmedia:SetTSS(false)
            title_song = cl_song
            self:play(
                cl_song, cl_song_index, cl_isAutoPlaying, cl_isLooped, cl_seek)

            if cl_isStopped then return end
            -- print("[core-states] is loop, autoplay:",
                -- getMedia():IsLooping(), songAutoPlay())
            if songLooped() then
                updateTitleColor(3, title_song)
            else
                updateTitleColor(1, title_song)
            end
        else
            action_cl_stop()
            reset_ui()
        end
    end
end

local function pauseOnPlay(self)
    if not isCurrentMediaValid() then return end

    if dermaBase.main.IsServerMode() then
        if self.sv_PlayingSong:get():GetState() == GMOD_CHANNEL_PLAYING then
            self.sv_PlayingSong:get():Pause()
            sv_isPaused = true
            sv_isStopped = false
            sv_AutoplayNext = false
        end
    else
        if self.cl_PlayingSong:get():GetState() == GMOD_CHANNEL_PLAYING then
            self.cl_PlayingSong:get():Pause()
            cl_isPaused = true
            cl_isStopped = false
        end
    end
end

local function forcedPause(self, bool_pause)
	if not isCurrentMediaValid() then return end

    local is_server_mode = dermaBase.main.IsServerMode()
    local media = getMedia(self)

    if bool_pause then
        media:Pause()
        if is_server_mode then
            sv_isPaused = true
            sv_isStopped = false
            sv_AutoplayNext = false
        else
            cl_isPaused = true
            cl_isStopped = false
        end
        updateTitleColor(2, title_song)
    elseif not bool_pause and not cl_isStopped then
        media:Play()
        if is_server_mode then
            sv_isPaused = false
            sv_isStopped = false
            sv_AutoplayNext = false
        else
            cl_isPaused = false
            cl_isStopped = false
        end

        if media:IsLooping() then
            updateTitleColor(3, title_song)
        else
            updateTitleColor(1, title_song)
        end
    end
end

local function forcedStop(bool_stop)
    if not isCurrentMediaValid() then return end

    if dermaBase.main.IsServerMode() then
        sv_isStopped = bool_stop
        sv_AutoplayNext = bool_stop
        timer.Stop("gmpl_sv_guard")
    else
        cl_isStopped = bool_stop
        timer.Stop("gmpl_cl_guard")
    end
end

local function actionPauseL(self)
    if self.cl_PlayingSong:is_stopped() then return end
    self.cl_PlayingSong:pause()

    local color_bg, color_text = {}, {}
    if self.cl_PlayingSong:is_paused() then
        color_bg, color_text = updateTitleColor(2, self.cl_PlayingSong)
    elseif self.cl_PlayingSong:is_looped() then
        color_bg, color_text = updateTitleColor(3, self.cl_PlayingSong)
    else
        color_bg, color_text = updateTitleColor(1, self.cl_PlayingSong)
    end
    updateListSelection(color_bg, color_text, self)
end

local function actionPauseR(self)
    local channel = get_audio_channel(self)
    if channel:is_stopped() then return end
    channel:set_loop()

    local color_bg, color_text = {}, {}
    if channel:is_looped() then
        color_bg, color_text = updateTitleColor(3, channel)
    else
        color_bg, color_text = updateTitleColor(1, channel)
    end
    updateListSelection(color_bg, color_text, self)
end

local function actionAutoPlay(self)
    local channel = get_audio_channel(self)
    if channel:is_stopped() then return end
    channel:set_autoplay()

    local color_bg, color_text = updateTitleColor(1, channel)
    updateListSelection(color_bg, color_text, self)


    -- local media = getMedia(self)
    -- print("[core-autoplay] set auto play to:", media)
	-- if IsValid(media) and media:GetState() == GMOD_CHANNEL_PLAYING then

	-- 	if songAutoPlay() then
    --         forced_autoplay(false)
	-- 	else
    --         forced_autoplay(true)
	-- 	end
    --     updateTitleColor(1, title_song)
    --     updateListSelection(color_bg, color_text, is_server_mode)
	-- end
end

local function actionSeek(self, time)
    if not isCurrentMediaValid() then return end
    local media = getMedia(self)
    if media:GetState() ~= GMOD_CHANNEL_STALLED then
        media:SetTime(time)
    end
end

return function(baseMenu)
	dermaBase = baseMenu
    local action = {}

    action.play			=	playSong
    action.playNext     =   playSongNext
    action.playServer	=	playSongServer
    action.updateClient =   updateSongClient
    action.updateServer =   updateSongServer
    action.resume		=	resumeSong
    action.sv_pause     =   action_sv_pause
    action.cl_pause     =   action_cl_pause
    action.sv_stop		=	action_sv_stop
    action.cl_stop		=	action_cl_stop
    action.sv_buffer_guard = sv_buffer_guard
    action.cl_buffer_guard = cl_buffer_guard

    action.pauseOnPlay  =   pauseOnPlay
    action.pause		=	actionPauseL
    action.loop		    =   actionPauseR
    action.autoplay     =   actionAutoPlay
    action.setpause     =   forcedPause
    action.setstop      =   forcedStop
    action.setloop		=	forced_loop
    action.setautoplay	=	forced_autoplay
    action.seek			=	actionSeek
    action.volume		=	songVol
    action.clientHasControl = clientHasControl
    action.clientControl = clientSetControl
    action.muteServer   =  mute_sv_song

    action.reset_ui		= 	reset_ui
    action.kill			= 	kill
    action.update		=	updateAudioObject
    action.updateStates =   updateAudioStates
    action.getTime		=	songTime
    action.get_song_len =   songLength
    action.getServerTime =	songServerTime
    action.getVolume	=	volumeState

    action.isMissing	=	songMissing
    action.isLooped		=	songLooped
    action.sv_is_autoplay = sv_is_autoplay
    action.cl_is_autoplay = cl_is_autoplay
    action.isAutoPlayed	=	songAutoPlay

    action.hasValidity 	=	isCurrentMediaValid
    action.hasState 	=	songState
    action.sv_is_stop   =   sv_is_stop
    action.cl_is_stop   =   cl_is_stop
    action.isStopped    =   songStopped
    action.sv_is_pause  =   sv_is_pause
    action.cl_is_pause  =   cl_is_pause
    action.is_paused    =   songPaused

    action.uiPlay 		= 	uiPlay
    action.uiPause      =   uiPause
    action.uiAutoPlay 	= 	uiAPlay
    action.uiLoop 		= 	uiLoop
    action.sv_uiRefresh =   sv_tss_refresh
    action.uiTitle      =   uiTitle

    action.colorLoop	= 	colLoop
    action.colorPause	= 	colPause
    action.colorPlay	= 	colPlay
    action.colorMissing =	col404

    action.breakOnStop	=	breakOnStop
    action.isThinking   =	isThinking
    action.checkServerStop = checkServerStop
    action.serverAutoPlayThink = serverAutoPlayThink

    action.cl_PlayingSong = GMPL_AUDIO.new()
    action.sv_PlayingSong = GMPL_AUDIO.new()

	return action
end