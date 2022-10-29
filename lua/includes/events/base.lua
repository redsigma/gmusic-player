local Callbacks = {}

local gmusic = include("includes/modules/setup.lua")


local function on_open_settings_panel()
  dermaBase.musicsheet:ToggleSideBar()
end

local function on_open_client_mode()
  local mediaplayer = gmusic.media()
  local main_window = gmusic.main()
  local main_interface = gmusic.interface()
  local slider_seek = gmusic.derma().sliderseek
  local context_button = gmusic.derma().contextmedia

  main_interface:toggle_normal_ui()
  local is_playing = mediaplayer:cl_mute(false)
  mediaplayer:sv_mute(true)
  mediaplayer:update_ui_highlight()
  slider_seek:ShowSeekBarIndicator(is_playing)


  main_window:SetTitleServerState(false)

  if not context_button then return end
  context_button:SetTSS(false)
end

local function on_open_server_mode()
  local mediaplayer = gmusic.media()
  local main_window = gmusic.main()
  local main_interface = gmusic.interface()
  local slider_seek = gmusic.derma().sliderseek
  local context_button = gmusic.derma().contextmedia

  main_interface:toggle_bottom_ui()
  mediaplayer:cl_mute(true)
  local is_playing = mediaplayer:sv_mute(false)
  mediaplayer:update_ui_highlight()
  slider_seek:ShowSeekBarIndicator(is_playing)


  main_window:SetTitleServerState(true)
  if not context_button then return end
  context_button:SetTSS(true)

  update_server_mode_with_live_song()
end

-- gmusic.main().OnSettingsClick = function(panel)
--   local music_sheet = gmusic.derma().musicsheet
--   music_sheet:ToggleSideBar()
-- end

-------------------------------------------------------------------------------
Callbacks.on_open_settings_panel = on_open_settings_panel
Callbacks.on_open_client_mode    = on_open_client_mode
Callbacks.on_open_server_mode    = on_open_server_mode

return Callbacks