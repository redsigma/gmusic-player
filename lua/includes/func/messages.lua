if not _G.gmusic_cl then return {} end

local function instance()
  return _G.gmusic_cl.interface_messages
end

if _G.gmusic_cl.interface_messages then return instance end
local dermaBase = {}
local interface_messages = {}

local function show_info(text)
  chat.AddText(Color(0, 220, 220), text)
end

local function show_sv_status_playing()
  local channel_info = dermaBase.mediaplayer.sv_PlayingSong.attrs
  show_info("[gMusic Player] Playing: " .. channel_info.title_song)
end

local function init(baseMenu)
  if _G.gmusic_cl.interface_messages then return _G.gmusic_cl.interface_messages end
  dermaBase = baseMenu
  interface_messages.show_sv_status_playing = show_sv_status_playing
  _G.gmusic_cl.interface_messages = interface_messages

  return _G.gmusic_cl.interface_messages
end

return init