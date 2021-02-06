/*
    Convars stored server side for updating each client
*/
local serverSettings = {}

serverSettings.admin_server_access = true      -- cbAdminAccess to other players
serverSettings.admin_dir_access = false  -- cbAdminAccessDir to other players

function init()
    return serverSettings
end
-------------------------------------------------------------------------------
local function printMessage(nrMsg, sender, bVal)
	local str
    str = "[gMusic Player] " .. sender:Nick()
	if nrMsg == 1 then
        if bVal then
            str = str .. " restricted clients from playing on server";
        else
            str = str .. " allowed clients to play on server";
        end
	elseif nrMsg == 2 then
        if bVal then
            str = str .. " restricted clients from editing the song list";
        else
            str = str .. " allowed clients to edit the song list";
        end
	end
	PrintMessage(HUD_PRINTTALK, str)
end
local function update_options( netMsg, itemOption )
	net.Start(netMsg)
	net.WriteBool(itemOption)
	net.Send(player.GetAll())
end
-------------------------------------------------------------------------------
/*
    Update Music Dir Access for each client
*/
net.Receive("toServerRefreshAccessDir_msg", function(length, sender )
	if sender:IsValid() then
		local tmpBool = net.ReadBool()
		printMessage(2, sender, tmpBool)
	end
end )
net.Receive("toServerRefreshAccessDir", function(length, sender )
	if sender:IsValid() and sender:IsAdmin() then
		serverSettings.admin_dir_access = net.ReadBool()
		update_options("refreshAdminAccessDir", serverSettings.admin_dir_access)
	end
end )

/*
    Update Admin Access for each client
*/
net.Receive("toServerRefreshAccess", function(length, sender )
	if sender:IsValid() and sender:IsAdmin() then
		serverSettings.admin_server_access = net.ReadBool()
		update_options("refreshAdminAccess", serverSettings.admin_server_access)
	end
end )
net.Receive("toServerRefreshAccess_msg", function(length, sender )
	if sender:IsValid() then
		local tmpBool = net.ReadBool()
		printMessage(1, sender, tmpBool)
	end
end )

return init