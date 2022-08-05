if not _G.gmusic_sv then return {} end
local Settings = {}

local function init_network()
  if not _G.gmusic_sv.shared_settings then return end

  net.Receive("sv_ask_server_settings", function(_, sender)
    local settings = _G.gmusic_sv.shared_settings
    local server_access = settings:get_admin_server_access()
    local dir_access = settings:get_admin_dir_access()
    print("On server", server_access, dir_access, sender)
    net.Start("cl_ask_server_settings")
    net.WriteBool(server_access)
    net.WriteBool(dir_access)
    net.Send(sender)
  end)
end

local function init()
  if _G.gmusic_sv.shared_settings then return _G.gmusic_sv.shared_settings end
  print("[gmpl] Init settings")
  Settings.admin_server_access = true
  Settings.admin_dir_access = false
  _G.gmusic_sv.shared_settings = Settings
  init_network()

  return _G.gmusic_sv.shared_settings
end

function Settings:set_admin_server_access(bVal)
  self.admin_server_access = bVal
end

function Settings:set_admin_dir_access(bVal)
  self.admin_dir_access = bVal
end

function Settings:get_admin_server_access()
  return self.admin_server_access
end

function Settings:get_admin_dir_access()
  return self.admin_dir_access
end

return init()