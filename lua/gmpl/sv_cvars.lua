--[[
    Convars stored server side for updating each client
--]]

-------------------------------------------------------------------------------
local function printMessage(nrMsg, sender, is_admin_only)
	local str
    str = "[gMusic Player][" .. sender:Nick() .. "] "
	if nrMsg == 1 then
    if is_admin_only then
      str = str .. "Only admins can play audio on server";
    else
      str = str .. "Everybody can now play audio on server";
    end
	elseif nrMsg == 2 then
    if is_admin_only then
      str = str .. "Only admins can edit the song list";
    else
      str = str .. "Everybody can now edit the song list";
    end
	end
	PrintMessage(HUD_PRINTTALK, str)

    -- print("\nshared settings sv_cvars:", shared_settings)
    -- PrintTable(shared_settings)
    -- print("admin_server_access = ", shared_settings:get_admin_server_access())
    -- print("admin_dir_access = ", shared_settings:get_admin_dir_access())
end
-------------------------------------------------------------------------------
--[[
    Update Music Dir Access for each client
--]]
net.Receive("toServerRefreshAccessDir", function(length, sender)
	if not IsValid(sender) then return end

    local bVal = net.ReadBool()
    if sender:IsAdmin() then
        shared_settings:set_admin_dir_access(bVal)
    end
    net.Start("refreshAdminAccessDir")
    net.WriteBool(shared_settings:get_admin_dir_access())
    printMessage(2, sender, bVal)
    net.Send(player.GetAll())
end)

-- --[[
--     Update shared settings for each client
-- --]]
-- net.Receive("sv_refresh_access", function(data, length, sender)
--     if not IsValid(sender) then return end

--     local bVal = net.ReadBool()
--     if sender:IsAdmin() then
--         shared_settings:set_admin_server_access(bVal)
--     end
--     net.Start("cl_refresh_access")
--     net.WriteBool(shared_settings:get_admin_server_access())
--     printMessage(1, sender, bVal)
--     net.Send(player.GetAll())
-- end)