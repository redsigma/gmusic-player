local server_func = {}

local function get_players(players)
  if istable(players) then return players end

  if isentity(players) then
    return {players}
  end

  return {}
end

local function is_valid_player(player)
  return isentity(player) and player:IsPlayer() and player:IsConnected()
end

local function has_admin_server_access(player)
  local shared_settings = include("includes/func/settings.lua")

  if shared_settings:get_admin_server_access() then
    if not player:IsAdmin() then return false end
  end

  return true
end

function server_func:play_song_for_players(list_of_players, server_audio, sender_audio)
  local players = get_players(list_of_players)
  local skip_next = false

  for _, player in pairs(players) do
    if not is_valid_player(player) then
      skip_next = true
    end

    if not has_admin_server_access(player) then
      skip_next = true
    else
      server_audio.liveSong = sender_audio.liveSong
      server_audio.liveSongIndex = sender_audio.liveSongIndex
      server_audio.isStopped = false
    end

    if not skip_next then
      print("Playing for", player)
      net.Start("cl_play_live_seek")
      net.WriteString(server_audio.liveSong)
      net.WriteUInt(server_audio.liveSongIndex, 16)
      net.WriteDouble(server_audio.liveSeek)
      net.WriteBool(server_audio.isLooped)
      net.WriteBool(server_audio.isAutoPlayed)
      net.WriteBool(server_audio.isPaused)
      net.WriteBool(server_audio.isStopped)

      if is_valid_player(server_audio.player) then
        net.WriteEntity(server_audio.player)
      end

      net.Send(player)
      skip_next = false
    end
  end
end

return server_func