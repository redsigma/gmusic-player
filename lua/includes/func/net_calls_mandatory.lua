local dermaBase = {}

local function init(baseMenu)
  dermaBase = baseMenu
end

local function net_get_channel_data()
  local live_song = net.ReadString()
  local live_song_index = net.ReadUInt(16)
  local live_seek = net.ReadDouble()
  local is_looped = net.ReadBool()
  local is_autoplayed = net.ReadBool()
  local is_paused = net.ReadBool()
  local is_stopped = net.ReadBool()
  local live_host = net.ReadEntity()
  local channel_data = {}
  channel_data.live_song = live_song
  channel_data.live_song_index = live_song_index
  channel_data.live_seek = live_seek
  channel_data.is_looped = is_looped
  channel_data.is_autoplayed = is_autoplayed
  channel_data.is_paused = is_paused
  channel_data.is_stopped = is_stopped
  channel_data.live_host = live_host

  return channel_data
end

net.Receive("cl_ask_live_channel_data", function()
  if not dermaBase.main:IsServerMode() then return end
  print("Update live song")
  -- local live_song = net.ReadString()
  -- local live_song_index = net.ReadUInt(16)
  -- local live_seek = net.ReadDouble()
  -- local is_looped = net.ReadBool()
  -- local is_autoplayed = net.ReadBool()
  -- local is_paused = net.ReadBool()
  -- local is_stopped = net.ReadBool()
  -- local live_host = net.ReadEntity()
  local data = net_get_channel_data()
  dermaBase.interface.set_song_host(data.live_host)

  if data.is_stopped then
    dermaBase.mediaplayer:sv_stop()
    dermaBase.labelswap:SetText("No song currently playing")

    return
  end

  dermaBase.mediaplayer:play_server(data.live_song, data.live_song_index, data.is_autoplayed, data.is_looped, data.live_seek)

  if data.is_paused then
    dermaBase.mediaplayer:sv_pause(data.is_paused)
    dermaBase.mediaplayer:sv_uiRefresh()
  end
end)

return init