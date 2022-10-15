--[[
    Convars that update at client side
--]]
local gmusic = include("includes/modules/setup.lua")

-------------------------------------------------------------------------------
--[[
    Use gm_showspare1 to toggle the music player
    note: won't apply if the key is binded directly to F3
--]]
net.Receive("sv_keypress_F3", function(length, sender)
  local derma = gmusic.derma()
  if not IsValid(derma.hotkey) then return end

  if not derma.hotkey:GetChecked() then
    net.Start("sv_gmpl_show")
    net.SendToServer()
  elseif input.LookupKeyBinding(KEY_F3) == "gmplshow" then
    return
  end
end)

--[[
    Used to update the server settings from first admin that it's connected
    Must run only once for the first admin to grab the values from him
--]]
net.Receive("cl_update_cvars_from_first_admin", function(length, sender)
  if not IsValid(sender) or not sender:IsAdmin() then return end

  local derma = gmusic.derma()
  local settings = {}

  settings.admin_server_access = GetConVar("gmpl_svadminplay"):GetBool()
  settings.admin_dir_access = GetConVar("gmpl_svadmindir"):GetBool()
  net.Start("sv_update_cvars_from_first_admin")
  net.WriteTable(settings)
  net.WriteTable(derma.song_data:get_left_song_list())
  net.WriteTable(derma.song_data:get_right_song_list())
  net.SendToServer()
end)

--[[
    Used for each client to update the server cvars
--]]
net.Receive("cl_update_cvars", function()
  local derma = gmusic.derma()

  local admin_server_access = net.ReadBool()
  local admin_dir_access = net.ReadBool()
  local songs_inactive = net.ReadTable()
  local songs_active = net.ReadTable()
  derma.cbadminaccess:SetChecked(admin_server_access)
  derma.cbadminaccess:RefreshConVar()
  derma.cbadmindir:SetChecked(admin_dir_access)
  derma.cbadmindir:RefreshConVar()
  shared_settings:set_admin_server_access(admin_server_access)
  shared_settings:set_admin_dir_access(admin_dir_access)
  -- print("Settings settings from server")
  -- PrintTable(songs_inactive)
  -- PrintTable(songs_active)
  derma.foldersearch:UpdateMusicDir(songs_inactive, songs_active)
end)

--[[
    Triggered after an admin changes the shared settings
--]]
-- net.Receive("refreshAdminAccessDir", function(length, sender)
--   local admin_only = net.ReadBool()
--   -- print("Received music dir:", admin_only)
--   dermaBase.cbadmindir:SetChecked(admin_only)
--   dermaBase.cbadmindir:RefreshConVar()
--   shared_settings:set_admin_dir_access(bVal)
-- end)
net.Receive("cl_settings_update", function(length, sender)
  local derma = gmusic.derma()

  print("--------[GMPL] Updating settings")
  local setting_live_admin_only = net.ReadBool()
  local setting_dir_change_admin_only = net.ReadBool()
  derma.cbadminaccess:SetChecked(setting_live_admin_only)
  derma.cbadminaccess:RefreshConVar()
  derma.cbadmindir:SetChecked(setting_dir_change_admin_only)
  derma.cbadmindir:RefreshConVar()
end)

