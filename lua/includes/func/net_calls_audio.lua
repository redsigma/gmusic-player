local dermaBase = {}
local logger = {}

local function init(baseMenu)
  dermaBase = baseMenu
  logger = include("includes/func/messages.lua")(dermaBase)
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

local function update_server_channel()
  local server_channel_attributes = dermaBase.mediaplayer.sv_PlayingSong.attrs
  net.Start("sv_update_channel_data")
  net.WriteTable(server_channel_attributes)
  net.SendToServer()
end

net.Receive("cl_play_live_seek", function(length)
  if not dermaBase.main:IsServerMode() then return end
  print("PLAY LIVE SEEK -- EVERYBODY")
  -- local live_song = net.ReadString()
  -- local live_song_index = net.ReadUInt(16)
  -- local live_seek = net.ReadDouble()
  -- local is_looped = net.ReadBool()
  -- local is_autoplayed = net.ReadBool()
  -- local is_paused = net.ReadBool()
  -- local is_stopped = net.ReadBool()
  -- local live_host = net.ReadEntity()
  local states = net_get_channel_data()
  dermaBase.interface.set_song_host(states.live_host)

  -- print("[net] seek sv song:", live_song_index, live_seek, "| loop:", is_looped, "| autoplay:", is_autoplayed)
  -- dermaBase.mediaplayer:clientControl(false)
  -- might change it with simple play and pass the PlayingServer obj
  if states.is_stopped then
    dermaBase.mediaplayer:sv_stop()
    dermaBase.labelswap:SetText("No song currently playing")

    return
  end

  dermaBase.mediaplayer:play_server(states.live_song, states.live_song_index, states.is_autoplayed, states.is_looped, states.live_seek)
  logger.show_sv_status_playing()
  -- if states.is_paused then
  --   dermaBase.mediaplayer:sv_pause(states.is_paused)
  --   dermaBase.mediaplayer:sv_uiRefresh()
  -- end
  local a = 0
end)

net.Receive("cl_play_next", function(_, _)
  local sv_channel = dermaBase.mediaplayer.sv_PlayingSong
  dermaBase.mediaplayer:sv_play_next(sv_channel)
  update_server_channel()
  logger.show_sv_status_playing()
end)

return init