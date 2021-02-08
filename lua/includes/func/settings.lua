local Settings = {}
print("[gmpl] Init settings")

Settings.admin_server_access = true
Settings.admin_dir_access = false

function init()
    return _G.shared_settings
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

_G.shared_settings = Settings

return _G.shared_settings