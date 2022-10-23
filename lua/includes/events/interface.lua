local Callbacks = {}

local gmusic = include("includes/modules/setup.lua")


----------------------------------------------------------------
-- TODO this is a duplicate from audio.lua, refactor this
local SIDE_CLIENT = 0
local SIDE_SERVER = 1
local songlist_highlights = {}
songlist_highlights[SIDE_CLIENT] = 0
songlist_highlights[SIDE_SERVER] = 0
----------------------------------------------------------------

local color = {}
color.play = Color(0, 150, 0)
color.autoplay = Color(70, 190, 180)
color.pause = Color(255, 150, 0)
color.live_pause = Color(210, 210, 0)
color.loop = Color(0, 230, 0)
color.missing = Color(240, 0, 0)
color.black = Color(0, 0, 0)
color.white = Color(230, 230, 230)


-- local function ui_update_title_color(status, channel)
--   local main_window = gmusic.main()
--   local context_button = gmusic.derma().contextmedia

--   local is_server_mode = main_window:IsServerMode()
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
--     main_window:SetTitleColor(colWhiteTitle)
--   else
--     main_window:SetTitleColor(color_text)
--   end

--   main_window:SetTitleBGColor(color_bg)
--   if context_button then
--     context_button:SetTextColor(color_bg)
--   end
--   updateTitleSong(status, channel)

--   return color_bg, color_text
-- end

local function ui_clear_previous_mode_highlight(channel)
  local song_list = gmusic.derma().songlist
  local previous_mode = SIDE_CLIENT

  if channel.mode == SIDE_CLIENT then
    previous_mode = SIDE_SERVER
  end

  -- song_list:HighlightReset(songlist_highlights[previous_mode])
end



-- local function update_ui_selection(self, channel)
--   if channel == nil then
--     -- channel = get_audio_channel(self)
--     error("10 - Unhandled nil channel")
--     return
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

local function enableTSS()
  local main_window = gmusic.main()
  if not main_window:IsTSSEnabled() then
    main_window:SetTSSEnabled(true)
  end
end

local function disableTSS()
  local main_window = gmusic.main()
  local context_button = gmusic.derma().contextmedia

  if not main_window:IsTSSEnabled() then return end
  main_window:SetTSSEnabled(false)

  if not context_button then return end
  context_button:SetTSS(false)
end

-- local function reset_ui(channel)
--   local slider_seek = gmusic.derma().sliderseek
--   slider_seek:ResetValue()
--   slider_seek:AllowSeek(false)

--   ui_update_title_color(false, channel)
--   ui_update_list_selection(channel, false, false)
-- end


local function get_color_audio_status(channel)
  --[[
    TODO REFACTOR
    - i wonder if i should check for these color states when i also switch from server to client modes otherwise inconsistencies will happen. Ofc i could also change them in the bg and have some logic that when you switch the mode, it updates everything (title, list and song; IMO this does sound better)
  ]]
  local color_bg = Color(150, 150, 150)
  local color_text = Color(230, 230, 230)

  if channel:is_autoplayed() then
    color_bg = color.autoplay
    color_text = color.black
  elseif channel:is_playing() then
    color_bg = color.play
    color_text = color.white
  elseif channel:is_paused() then
    color_bg = color.pause
    color_text = color.black
  elseif channel:is_looped() then
    color_bg = color.loop
    color_text = color.black
  elseif channel:is_paused_live() then
    color_bg = color.live_pause
    color_text = color.black
  end

  return color_bg, color_text
end

local function update_title_song(channel)
  local song_filepath = channel:get_song_path()
  if not song_filepath then return end

  local main_window = gmusic.main()
  local context_button = gmusic.derma().contextmedia

  local title_song = channel:get_song_name()
  main_window:SetTitle(channel:get_song_prefix() .. title_song)

  if context_button then
    context_button:SetText(title_song)
  end
end

local function update_title_color(color_bg, color_text)
  local main_window = gmusic.main()
  local context_button = gmusic.derma().contextmedia

  main_window:SetTitleBGColor(color_bg)
  main_window:SetTitleColor(color_text)

  if context_button then
    context_button:SetTextColor(color_bg)
  end
end


local function update_selected_row_color(channel, color_bg, color_text)
  local song_list = gmusic.derma().songlist

  local song_index = channel:get_song_index()
  local prev_song_index = channel:get_song_prev_index()

  ui_clear_previous_mode_highlight(channel)

  -- if it cant find the song number then better not bother coloring
  if color_text == false or color_bg == false then
    color_text = song_list:GetDefaultTextColor()
  end

  local songs = song_list:GetLines()

  if IsValid(songs[song_index]) then
    song_list:HighlightLine(song_index, color_bg, color_text)
    songlist_highlights[channel.mode] = song_index
  end

  if IsValid(songs[prev_song_index]) then
    song_list:HighlightReset(prev_song_index)
  end
end



-------------------------------------------------------------------------------
local function on_autoplay_ui_update(channel)
  if not channel then return end

  local main_window = gmusic.main()
  channel:set_song_prefix(" Auto Playing: ")

  if not main_window:IsTSSEnabled() then
    main_window:SetTSSEnabled(true)
  end

  local color_bg = color.autoplay
  local color_text = color.black
  update_title_color(color_bg, color_text)
  update_title_song(channel)

  update_selected_row_color(channel, color_bg, color_text)
end

local function on_play_ui_update(channel)
  if not channel then return end

  local main_window = gmusic.main()
  channel:set_song_prefix(" Playing: ")

  if not main_window:IsTSSEnabled() then
    main_window:SetTSSEnabled(true)
  end

  local color_bg = color.play
  local color_text = color.white
  update_title_color(color_bg, color_text)
  update_title_song(channel)

  update_selected_row_color(channel, color_bg, color_text)
end

local function on_pause_ui_update(channel)
  if not channel then return end

  local main_window = gmusic.main()
  channel:set_song_prefix(" Paused: ")

  if not main_window:IsTSSEnabled() then
    main_window:SetTSSEnabled(true)
  end

  local color_bg = color.pause
  local color_text = color.black
  update_title_color(color_bg, color_text)
  update_title_song(channel)

  update_selected_row_color(channel, color_bg, color_text)
end

local function on_loop_ui_update(channel)
  if not channel then return end

  local main_window = gmusic.main()
  channel:set_song_prefix(" Looping: ")

  if not main_window:IsTSSEnabled() then
    main_window:SetTSSEnabled(true)
  end

  local color_bg = color.loop
  local color_text = color.black
  update_title_color(color_bg, color_text)
  update_title_song(channel)

  update_selected_row_color(channel, color_bg, color_text)
end

local function on_revert_ui_update(channel)
  -- TODO use this for unpausing
  -- - needs to detect if it's either looping, autoplaying or playing
  -- - do not check for `live_pause`, you'l do another delegate for that

  if not channel then return end

  if channel:is_looped() then
    on_loop_ui_update(channel)
  elseif channel:is_autoplayed() then
    on_autoplay_ui_update(channel)
  elseif channel:is_playing() then
    on_play_ui_update(channel)
  end

end

local function on_stop_ui_update(channel)
  local main_window = gmusic.main()
  local slider_seek = gmusic.derma().sliderseek
  local context_button = gmusic.derma().contextmedia

  slider_seek:ResetValue()
  slider_seek:AllowSeek(false)

  local colWhiteTitle = Color(255, 255, 255)
  local colWhite = Color(230, 230, 230)
  local colBlack = Color(0, 0, 0)
  local col404 = Color(240, 0, 0)

  local color_bg = Color(150, 150, 150)
  local color_text = colWhite
  local color_text_context_button = colBlack


  update_title_color(color_bg, colWhiteTitle)


  main_window:SetTitle(" gMusic Player")
  main_window:SetTSSEnabled(false)

  if context_button then
    context_button:SetText(false)
  end
  disableTSS()


  if context_button then
    context_button:SetTextColor(color_text_context_button)
  end

  update_selected_row_color(channel, false, false)
end

local function on_missing_ui_update(channel)
end


-------------------------------------------------------------------------------
Callbacks.on_play_ui_update     = on_play_ui_update
Callbacks.on_pause_ui_update    = on_pause_ui_update
Callbacks.on_loop_ui_update     = on_loop_ui_update
Callbacks.on_autoplay_ui_update = on_autoplay_ui_update
Callbacks.on_revert_ui_update   = on_revert_ui_update
Callbacks.on_stop_ui_update     = on_stop_ui_update
Callbacks.on_missing_ui_update  = on_missing_ui_update

return Callbacks