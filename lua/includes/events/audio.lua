local Callbacks = {}

local gmusic = include("includes/modules/setup.lua")



local function on_begin_play(channel, is_audio_valid)

  local main_window = gmusic.main()
  local mediaplayer = gmusic.media()
  local slider_seek = gmusic.derma().sliderseek
  local context_button = gmusic.derma().contextmedia

  local is_server_mode =
    channel:is_server_channel() and main_window:IsServerMode()

  local is_client_mode =
    not channel:is_server_channel() and not main_window:IsServerMode()

  if not main_window:IsServerMode() then
    mediaplayer:sv_mute(true)
  end

  if is_server_mode or is_client_mode then
    if not is_audio_valid then
      slider_seek:ResetValue()

      return
    end

    slider_seek:AllowSeek(true)
    slider_seek:SetMax(channel.seek_len)
    slider_seek:ShowSeekBarHandle(true)
    if context_button then
      context_button:SetSeekLength(channel.seek_len)
    end
  end
end

Callbacks.on_begin_play = on_begin_play

return Callbacks