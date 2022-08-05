--[[
    Handles server related events such as server-side music
--]]
include("includes/modules/coms.lua")
local sv_util = include("includes/func/server.lua")
-- local server_host.liveSong = ""
-- local server_host.liveSongIndex = 0
-- local server_host.liveSeek = 0
--[[
    Check if looping is enabled
--]]
-- local server_host.isLooped= false
--[[
    Check if auto playing is enabled
--]]
-- local server_host.isAutoPlayed = false
--[[
    Check if song is paused
--]]
-- local server_host.isPaused = false
--[[
    Check if song is stopped
--]]
-- local server_host.isStopped = true
local userWantLive = 0
--[[
    Store the player that is currently playing on server
--]]
local server_host = {}
server_host.player = nil
server_host.liveSong = ""
server_host.liveSongIndex = 0
server_host.liveSeek = 0
server_host.isLooped = false
server_host.isAutoPlayed = false
server_host.isPaused = false
server_host.isStopped = true
--[[-------------------------------------------------------------------------
Tables used for adminAccessDir = true
-------------------------------------------------------------------------]]
--
local song_inactive_folders = {}
local song_active_folders = {}
--[[-------------------------------------------------------------------------
Server Settings
-------------------------------------------------------------------------]]
--
local sv_cvars_synced = false
local shared_settings = nil
local has_first_setup = false

local function has_valid_settings()
  return istable(shared_settings)
end

local function validate_settings()
  if not has_valid_settings() then
    -- NOT SURE if it's a good idea but
    shared_settings = include("includes/func/settings.lua")
    -- print("Settings not set. Setting them")
    -- debug.Trace()
  end
end

local function is_player_valid(player)
  local bool = IsValid(player)

  if not bool then
    print("PLAYER", player, "not valid")
    -- debug.Trace()
  end

  return bool
end

local function is_player_the_current_host(player)
  if not is_player_valid(server_host.player) then return false end
  if server_host.player == player then return true end

  return false
end

local function has_admin_server_access(player)
  if not is_player_valid(player) or not has_valid_settings() then return false end

  if shared_settings:get_admin_server_access() then
    if not player:IsAdmin() then return false end
  end

  return true
end

local function is_valid_server_host_player()
  return isentity(server_host.player) and server_host.player:IsPlayer()
end

local function setup_settings_from_admin(ply)
  net.Start("cl_update_cvars_from_first_admin")
  net.Send(ply)
end

local function play_server_song_to_player(player)
  if not is_player_valid(player) then
    local is_list_of_all_players = istable(player)
    if not is_list_of_all_players then return end
  end

  -- net.Start("cl_play_live_seek_from_host")
  -- net.WriteEntity(player)
  -- net.Send(server_host.player)
  net.Start("cl_play_live_seek")
  -- net.WriteDouble(server_host.liveSeek)
  -- net.WriteString(server_host.liveSong)
  -- net.WriteUInt(server_host.liveSongIndex, 16)
  -- net.WriteBool(server_host.isAutoPlayed)
  -- net.WriteBool(server_host.isLooped)
  --
  net.WriteString(server_host.liveSong)
  net.WriteUInt(server_host.liveSongIndex, 16)
  net.WriteDouble(server_host.liveSeek)
  net.WriteBool(server_host.isLooped)
  net.WriteBool(server_host.isAutoPlayed)
  net.WriteBool(server_host.isPaused)
  net.WriteBool(server_host.isStopped)

  if is_valid_server_host_player() and server_host.player:IsConnected() then
    net.WriteEntity(server_host.player)
  end

  net.Send(player)
end

local function initial_spawn(ply)
  net.Start("cl_gmpl_create")
  net.Send(ply)

  if has_valid_settings() then
    net.Start("cl_update_cvars")
    net.WriteBool(shared_settings:get_admin_server_access())
    net.WriteBool(shared_settings:get_admin_dir_access())
    net.WriteTable(song_inactive_folders)
    net.WriteTable(song_active_folders)
    net.Send(ply)

    return
  else
    validate_settings()
  end

  setup_settings_from_admin(ply)
end

net.Receive("sv_update_cvars_from_first_admin", function(length, ply)
  local settings = net.ReadTable()
  local inactive_dirs = net.ReadTable()
  local active_dirs = net.ReadTable()
  shared_settings = include("includes/func/settings.lua")
  shared_settings:set_admin_server_access(settings.admin_server_access)
  shared_settings:set_admin_dir_access(settings.admin_dir_access)
  sv_cvars_synced = true
  if table.IsEmpty(inactive_dirs) and table.IsEmpty(active_dirs) then return end

  if #song_inactive_folders == 0 and #song_active_folders == 0 then
    song_inactive_folders = inactive_dirs
    song_active_folders = active_dirs
  end
end)

-- print("\n Server]] Inactive songs:")
-- PrintTable(song_inactive_folders)
-- print("\n Server]] Active songs:")
-- PrintTable(song_active_folders)
-- // On Server first start
-- local sql_result = nil
-- sql.Query("DROP TABLE gmpl_music")
-- if sql.TableExists("gmpl_music") then
--     sql_result = sql.Query("DROP TABLE gmpl_music")
--     print("Table exists. Droping...")
--     if (sql.TableExists("gmpl_music")) then
--         PrintMessage(HUD_PRINTCONSOLE,
--             "[gMusic Player] Unhandled error code 2 |",
--             sql.LastError(sql_result))
--     end
-- end
-- sql_result = sql.Query("CREATE TABLE gmpl_music (music_folder varchar(255), active int)")
-- if (sql.TableExists("gmpl_music")) then
--     print("Created table gmpl_music on server")
--     print(song_inactive_folders)
--     for key, folder in pairs(song_inactive_folders) do
--         sql.Query("INSERT INTO gmpl_music (`music_folder`, `active`)VALUES ('" .. sql.SQLStr(folder, true) .."', '0')")
--     end
--     print("Server print table:")
--     PrintTable(sql.Query("SELECT * FROM gmpl_music"))
-- else
--     PrintMessage(HUD_PRINTCONSOLE,
--         "[gMusic Player] Unhandled error code 3 |",
--         sql.LastError(sql_result))
-- end
-- On Player initial spawn
-------------------------------------------------------------------------------
hook.Add("Initialize", "checkUlib", function()
  if istable(hook.GetTable().ULibLocalPlayerReady) then
    print("[gMusic Player] Initializing - via Ulib")

    hook.Add("ULibLocalPlayerReady", "initPlayer", function(ply)
      initial_spawn(ply)
    end)
  else
    print("[gMusic Player] Initializing")

    hook.Add("PlayerInitialSpawn", "initPlayer", function(ply)
      initial_spawn(ply)
    end)
  end
end)

hook.Add("ShowSpare1", "openMenuF3", function(ply)
  net.Start("sv_keypress_F3")
  net.Send(ply)
end)

net.Receive("sv_gmpl_show", function(length, ply)
  if not is_player_valid(ply) then return end
  net.Start("cl_gmpl_show")
  net.WriteType(server_host.player)
  net.Send(ply)
end)

-- Settings Panel Options
-------------------------------------------------------------------------------
local function printMessage(nrMsg, ply, itemVal)
  local str

  if nrMsg == 1 then
    str = "Admin Access"
  elseif nrMsg == 2 then
    str = "Music Dir Access"
  end

  ply:PrintMessage(HUD_PRINTTALK, str .. " changed to " .. tostring(itemVal) .. " by " .. ply:Nick())
end

net.Receive("sv_refresh_song_list", function(length, ply)
  -- if not validate_settings() then return end
  validate_settings()
  if not is_player_valid(ply) then return end
  print("[net] Refreshing song list")

  if shared_settings:get_admin_dir_access() then
    if not ply:IsAdmin() then return end
  end

  -- if ply:IsAdmin() then
  song_inactive_folders = net.ReadTable()
  song_active_folders = net.ReadTable()
  -- print("\nServer changed server songs")
  -- print("inactive:")
  -- PrintTable(song_inactive_folders)
  -- print("active:")
  -- PrintTable(song_active_folders)
  -- print("----------------------------")
  net.Start("cl_refresh_song_list")
  net.WriteTable(song_inactive_folders)
  net.WriteTable(song_active_folders)
  ply:PrintMessage(HUD_PRINTTALK, "[gMusic Player] " .. ply:Nick() .. " has changed the song directories")
  net.Send(player.GetAll())
end)

-- end
-- net.Receive("toServerUpdateSeek", function(length, ply )
-- 	if IsValid(userWantLive) and IsValid(userWantLive) then
-- 		server_host.liveSeek = net.ReadDouble()
-- 		net.Start("playLiveSeek")
-- 		net.WriteBool(isLooped)
-- 		net.WriteBool(isAutoPlayed)
-- 		net.WriteEntity(ply) -- the server_host.player
-- 		net.WriteString(liveSong)
-- 		net.WriteDouble(liveSeek)
-- 		net.Send(userWantLive)
-- 	end
-- end )
net.Receive("sv_set_loop", function(length, ply)
  if not is_player_valid(ply) then return end
  -- COMM_BEFORE_ISOLATE server_host.isLooped = net.ReadBool()
  -- if server_host.isLooped then
  -- COMM_BEFORE_ISOLATE server_host.isAutoPlayed = false
  -- end
  net.Start("cl_set_loop")
  net.WriteBool(server_host.isLooped)
  net.Send(player.GetAll())
end)

net.Receive("sv_set_autoplay", function(length, ply)
  if not is_player_valid(ply) then return end
  -- COMM_BEFORE_ISOLATE server_host.isAutoPlayed = net.ReadBool()
  -- if server_host.isAutoPlayed then
  -- COMM_BEFORE_ISOLATE   server_host.isLooped = false
  -- end
  net.Start("cl_set_autoplay")
  net.WriteBool(server_host.isAutoPlayed)
  net.Send(player.GetAll())
end)

net.Receive("sv_pause_live", function(length, ply)
  -- if not validate_settings() then return end
  validate_settings()
  if not is_player_valid(ply) then return end
  if not has_admin_server_access(ply) then return end
  -- COMM_BEFORE_ISOLATE server_host.isPaused = net.ReadBool()
  -- COMM_BEFORE_ISOLATE server_host.liveSeek = net.ReadDouble()
  -- print("[SERVER] Server pause is:", isPaused)
  local has_player_host = is_valid_server_host_player()
  -- if isPaused then
  net.Start("cl_pause_live")
  net.WriteBool(server_host.isPaused)
  -- net.WriteBool(isAutoPlayed)
  -- net.WriteBool(isLooped)
  -- net.WriteDouble(liveSeek)
  -- net.WriteString(liveSong)
  -- net.WriteUInt(liveSongIndex, 16)
  -- if has_player_host then
  --     net.WriteEntity(server_host.player)
  -- end
  net.Send(player.GetAll())
end)

-- else
--     if has_player_host then
--         net.Start("cl_play_live_seek_from_host")
--         net.WriteEntity(ply)
--         net.Send(server_host.player)
--     end
-- end
-- net.Start("cl_pause_live")
-- net.WriteBool(isPaused)
-- net.Send(ply)
--[[
    Triggered when an admin plays song on server
--]]
net.Receive("sv_play_live", function(length, sender)
  print("Play LIVE FOR ALL")
  local sender_channel = {}
  sender_channel.liveSong = net.ReadString()
  sender_channel.liveSongIndex = net.ReadUInt(16)
  local all_players = player.GetAll()
  sv_util:play_song_for_players(all_players, server_host, sender_channel)
  --[[
  validate_settings()
  if not is_player_valid(sender) then return end
  if not has_admin_server_access(sender) then return end

  if not has_valid_settings() and not has_first_setup then
    -- sender:PrintMessage(
    -- HUD_PRINTCONSOLE, "[gMusic Player] Unhandled error code 1")
    setup_settings_from_admin(sender)
    has_first_setup = true
  end

  -- if not validate_settings() then return end
  -- server_host.player = sender
  -- server_host.liveSong = net.ReadString()
  -- server_host.liveSongIndex = net.ReadUInt(16)
  -- server_host.isPaused = false
  -- server_host.isStopped = false
  play_server_song_to_player(player.GetAll())
  -- net.Start("cl_play_live")
  -- net.WriteString(server_host.liveSong)
  -- net.WriteBool(server_host.isLooped)
  -- net.WriteBool(server_host.isAutoPlayed)
  -- net.WriteUInt(server_host.liveSongIndex, 16)
  -- if is_valid_server_host_player() and server_host.player:IsConnected() then
  --   net.WriteEntity(server_host.player)
  -- end
  -- net.Send(player.GetAll())
  ]]
  local todo_remove_test = 0
end)

--[[
    Triggered when an admin stops song on server
    Note: autoplay and loop is set in another place
--]]
net.Receive("sv_stop_live", function(length, ply)
  if not is_player_valid(ply) then return end

  if server_host.isAutoPlayed then
    net.Start("cl_play_next")
    net.Send(player.GetAll())

    return
  end

  server_host.player = nil
  userWantLive = 0
  -- COMM_BEFORE_ISOLATE server_host.isPaused = false
  -- COMM_BEFORE_ISOLATE server_host.isStopped = true
  net.Start("cl_stop_live")
  -- net.SendOmit(ply)
  net.Send(player.GetAll())
end)

-- Seek related sync
----------------------------------------------------------------------------
net.Receive("sv_set_seek", function(length, ply)
  if not is_player_valid(ply) then return end
  -- COMM_BEFORE_ISOLATE server_host.liveSeek = net.ReadDouble()
  net.Start("cl_set_seek")
  net.WriteDouble(server_host.liveSeek)
  net.Send(player.GetAll())
end)

-- Sanity checks
----------------------------------------------------------------------------
-- --[[
--     Updates the server side paused status
-- --]]
-- net.Receive("updateStatusPauseToServer", function(length, ply)
--     if not IsValid(ply) then return end
--     if shared_settings:get_admin_server_access() then
--         if ply:IsAdmin() then
--             server_host.isPaused = net.ReadBool()
--         end
--     else
--         server_host.isPaused = net.ReadBool()
--     end
--     print("---- [update] isPaused set to:", isPaused)
-- end)
--[[
    Updates the server side seek time by grabing it from the current host
    and sends it back to the user which asked
--]]
net.Receive("sv_play_live_seek_from_host", function(length, sender)
  if not is_player_valid(sender) then return end

  -- print("--- [SERVER] Is paused:", isPaused)
  -- ply:PrintMessage(HUD_PRINTCONSOLE, "--- [SERVER] Is paused:" .. tostring(isPaused) )
  -- if server_host.isPaused then
  --   -- print("[net] sv is paused")
  --   net.Start("cl_pause_live")
  --   -- net.WriteString(liveSong)
  --   net.WriteBool(server_host.isPaused)
  --   net.Send(sender)
  --   return
  -- end
  if is_valid_server_host_player() then
    -- print("[net] play live from host")
    play_server_song_to_player(sender)
    -- Maybe add some OnDisconnect hook so if the playerhost disconnects
    -- then to make it nil
    -- Also if asking for liveSeek but server_host.player is not longer here(it was before), so the text should be updated to no songs on server. HMM the net message when switching to Server Mode should handle this i think, so the problem remains if the admin disconnects while a song is playing or when the song ends hmm
  end
end)

--[[
    Update server seek time from admin and send to user
--]]
net.Receive("sv_play_live_seek_for_user", function(length, sender)
  -- if not validate_settings() then return end
  validate_settings()
  if not is_player_valid(sender) then return end
  if not has_admin_server_access(sender) then return end
  local user_wants_live = net.ReadEntity()
  -- in case admin loses access
  -- COMM_BEFORE_ISOLATE server_host.liveSeek = net.ReadDouble()
  -- sender:PrintMessage(HUD_PRINTCONSOLE, "\n---[SERVER] user wants live:", user_wants_live, IsValid(user_wants_live))
  -- net.WriteEntity(server_host.player)
  if not is_player_valid(user_wants_live) then return end
  net.Start("cl_play_live_seek")
  net.WriteDouble(server_host.liveSeek)
  net.WriteString(server_host.liveSong)
  net.WriteUInt(server_host.liveSongIndex, 16)
  net.WriteBool(server_host.isAutoPlayed)
  net.WriteBool(server_host.isLooped)
  net.Send(user_wants_live)
end)

-- print("---- [update-liveseek] liveSeek set to:", liveSeek)
-- print("---- [update-liveseek] liveSong set to:", liveSong)
--[[
    Used for switching between client and server modes
    Clients can only live seek if only admins can play on server
--]]
net.Receive("sv_play_live_seek", function(length, sender)
  -- if not validate_settings() then return end
  validate_settings()
  if not is_player_valid(sender) then return end
  if not has_admin_server_access(sender) then return end

  if is_valid_server_host_player() then
    net.Start("cl_play_live_seek_from_host")
    net.WriteEntity(sender)
    net.Send(server_host.player)

    return
  end

  if #server_host.liveSong == 0 then return end
  -- COMM_BEFORE_ISOLATE server_host.player = sender
  -- COMM_BEFORE_ISOLATE server_host.liveSeek = net.ReadDouble()
  net.Start("cl_play_live_seek")
  net.WriteDouble(server_host.liveSeek)
  net.WriteString(server_host.liveSong)
  net.WriteUInt(server_host.liveSongIndex, 16)
  net.WriteBool(server_host.isAutoPlayed)
  net.WriteBool(server_host.isLooped)
  net.Send(sender)
end)

net.Receive("sv_refresh_song_state", function(length, ply)
  if not is_player_valid(ply) then return end
  -- ply:PrintMessage(HUD_PRINTCONSOLE, "---[SERVER] Song live:" .. liveSong)
  net.Start("cl_refresh_song_state")
  net.WriteBool(server_host.isPaused)
  net.WriteBool(server_host.isAutoPlayed)
  net.WriteBool(server_host.isLooped)
  net.WriteDouble(server_host.liveSeek)
  net.WriteString(server_host.liveSong)
  net.WriteUInt(server_host.liveSongIndex, 16)

  if isentity(server_host.player) then
    ply:PrintMessage(HUD_PRINTCONSOLE, "---[SERVER] Writing server_host.player")
    net.WriteEntity(server_host.player)
  end

  net.Send(ply)
end)

-- print("\n---- [request] user request song state")
net.Receive("sv_update_song_state", function(length, sender)
  -- if not validate_settings() then return end
  validate_settings()
  if not is_player_valid(sender) then return end
  if not has_admin_server_access(sender) then return end
  -- COMM_BEFORE_ISOLATE server_host.isPaused = net.ReadBool()
  -- COMM_BEFORE_ISOLATE server_host.isAutoPlayed = net.ReadBool()
  -- COMM_BEFORE_ISOLATE server_host.isLooped = net.ReadBool()
  print("[net] update sv states")
end)

--[[
    Update shared settings
--]]
net.Receive("sv_settings_edit_live_access", function(length, ply)
  -- if not validate_settings() then return end
  validate_settings()
  if not is_player_valid(ply) then return end
  local bVal = net.ReadBool()

  if ply:IsAdmin() then
    shared_settings:set_admin_server_access(bVal)
  end

  net.Start("cl_settings_update")
  net.WriteBool(shared_settings:get_admin_server_access())
  net.WriteBool(shared_settings:get_admin_dir_access())
  net.Send(player.GetAll())
  local a = 0
end)

net.Receive("sv_settings_edit_dir_access", function(length, ply)
  -- if not validate_settings() then return end
  validate_settings()
  if not is_player_valid(ply) then return end
  local bVal = net.ReadBool()

  if ply:IsAdmin() then
    shared_settings:set_admin_dir_access(bVal)
  end

  net.Start("cl_settings_update")
  net.WriteBool(shared_settings:get_admin_server_access())
  net.WriteBool(shared_settings:get_admin_dir_access())
  net.Send(player.GetAll())
  local a = 0
end)

-- net.Receive("sv_update_host", function(length, ply)
--     if not IsValid(ply) then return end
--     ply:PrintMessage(HUD_PRINTCONSOLE, "---[SERVER] Request server_host.player")
--     net.Start("cl_update_host")
--     if isentity(server_host.player) then
--         net.WriteEntity(server_host.player)
--     end
--     net.Send(ply)
-- end)
net.Receive("sv_ask_live_channel_data", function(_, sender)
  if not is_player_valid(sender) then return end
  if is_player_the_current_host(sender) then return end
  net.Start("cl_ask_live_channel_data")
  net.WriteString(server_host.liveSong)
  net.WriteUInt(server_host.liveSongIndex, 16)
  net.WriteDouble(server_host.liveSeek)
  net.WriteBool(server_host.isLooped)
  net.WriteBool(server_host.isAutoPlayed)
  net.WriteBool(server_host.isPaused)
  net.WriteBool(server_host.isStopped)

  if is_valid_server_host_player() and server_host.player:IsConnected() then
    net.WriteEntity(server_host.player)
  end

  net.Send(sender)
end)

net.Receive("sv_update_channel_data", function(length, sender)
  if not is_player_valid(sender) then return end
  if not has_admin_server_access(sender) then return end
  local channel_data = net.ReadTable()
  server_host.player = sender
  server_host.liveSong = channel_data.song
  server_host.liveSongIndex = channel_data.song_index
  server_host.liveSeek = channel_data.seek
  server_host.isLooped = channel_data.isLooped
  server_host.isAutoPlayed = channel_data.isAutoPlaying
  server_host.isPaused = channel_data.isPaused
  server_host.isStopped = channel_data.isStopped
end)

net.Receive("sv_reset_audio", function(length, ply)
  server_host.player = nil
  server_host.liveSong = ""
  server_host.liveSongIndex = 0
  server_host.liveSeek = 0
  server_host.isLooped = false
  server_host.isAutoPlayed = false
  server_host.isPaused = false
  server_host.isStopped = true
end)