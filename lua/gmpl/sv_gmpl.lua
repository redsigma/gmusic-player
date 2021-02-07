include("includes/modules/coms.lua")

local liveSong = ""
local liveSeek = 0
local isLooped = false
local isAutoPlayed = false

local userWantLive = 0
local playerHost = 0

local songAutoPlayed = ""


--[[-------------------------------------------------------------------------
Tables used for adminAccessDir = true
---------------------------------------------------------------------------]]--
local songInactiveTable = {}
local songActiveTable = {}

--[[-------------------------------------------------------------------------
Server Options identifiers
---------------------------------------------------------------------------]]--
local serverJustStarted = true
local serverSettings =  include("gmpl/sv_cvars.lua")()
---------------------------------------------------------------------------]]--

local function sendType_ToClient(ply , netMsg )
	net.Start(netMsg)
	net.WriteType(playerHost)
	net.Send(ply)
end

local function initMenu(ply)
	net.Start("createMenu")
	net.WriteBool(ply:IsAdmin())
	net.Send(ply)

	net.Start("persistClientSettings")
	net.Send(ply)
end

--[[-------------------------------------------------------------------------
On Player initial spawn update settings.
---------------------------------------------------------------------------]]--
hook.Add("Initialize", "checkUlib", function()
	if istable(hook.GetTable().ULibLocalPlayerReady) then
		print("[gMusic Player] Initializing - via Ulib")
		hook.Add("ULibLocalPlayerReady", "initPlayer", function(ply)
			initMenu(ply)
		end)
	else
		print("[gMusic Player] Initializing")
		hook.Add("PlayerInitialSpawn", "initPlayer", function(ply)
			initMenu(ply)
		end)
	end
end)
hook.Add("ShowSpare1", "openMenuF3", function( ply )
	net.Start("press_Key_F3FromServer")
	net.Send(ply)
end)
net.Receive("toServerKey_F3", function(length, sender)
	if sender:IsValid() then
		sendType_ToClient(sender,"openmenu")
	end
end)

net.Receive("toServerContextMenu", function(length, sender)
	if sender:IsValid() then
		sendType_ToClient(sender, "openmenucontext")
	end
end)
---------------------------------------------------------------------------]]--

net.Receive( "serverFirstMade", function(length, sender )
	if sender:IsValid() then
		if serverJustStarted then
			net.Start("getSettingsFromFirstAdmin")
			net.Send(player.GetAll())
		else
			net.Start("sendServerSettings")
			net.WriteTable(serverSettings)
			net.Send(sender)

			if serverSettings.admin_dir_access then
				net.Start("refreshSongListFromServer")
				net.WriteTable(songInactiveTable)
				net.WriteTable(songActiveTable)
				net.Send(sender)
			end
		end
	end
end )

net.Receive("updateSettingsFromFirstAdmin", function(length, sender )
	local tmpSettingsTable = net.ReadTable()

	serverSettings.admin_server_access  = tmpSettingsTable.admin_server_access
	serverSettings.admin_dir_access = tmpSettingsTable.admin_dir_access

	serverJustStarted = false

	if serverSettings.admin_dir_access then
		songInactiveTable = net.ReadTable()
		songActiveTable = net.ReadTable()
	end
end )

--[[-------------------------------------------------------------------------
Settings Panel Options
---------------------------------------------------------------------------]]--
local function printMessage(nrMsg, sender, itemVal)
	local str
	if nrMsg == 1 then
		str = "Admin Access"
	elseif nrMsg == 2 then
		str = "Music Dir Access"
	end

	PrintMessage(HUD_PRINTTALK, str .. " changed to " .. tostring(itemVal) .. " by " .. sender:Nick() )
end

net.Receive( "toServerRefreshSongList", function(length, sender )
	if sender:IsValid() and sender:IsAdmin() then
		songInactiveTable = net.ReadTable()
		songActiveTable = net.ReadTable()

		net.Start("refreshSongListFromServer")
		net.WriteTable(songInactiveTable)
		net.WriteTable(songActiveTable)

		PrintMessage(HUD_PRINTTALK, "Song List has been refresh by " .. sender:Nick() )
		net.Send(player.GetAll())
	end
end )

net.Receive( "toServerUpdateSeek", function(length, sender )
	if userWantLive:IsValid() and sender:IsValid() then
		liveSeek = net.ReadDouble()
		net.Start("playLiveSeek")

		net.WriteBool(isLooped)
		net.WriteBool(isAutoPlayed)
		net.WriteEntity(sender) -- the playerHost
		net.WriteString(liveSong)
		net.WriteDouble(liveSeek)

		net.Send(userWantLive)
	end
end )


net.Receive( "toServerAdminPlay", function(length, sender )
	if IsValid(sender) then
		if serverSettings.admin_server_access then
			if sender:IsAdmin() then
				liveSong = net.ReadString()
				playerHost = sender
				isLooped = false
				net.Start( "playFromServer_adminAccess" )
				net.WriteString( liveSong )
				net.WriteEntity( playerHost )
				net.Send(player.GetAll())
			else
				userWantLive = sender
				if TypeID(playerHost) == TYPE_ENTITY and playerHost:IsPlayer()
				and playerHost:IsConnected()  then
						net.Start("askAdminForLiveSeek")
						net.WriteEntity(sender)
						net.Send(playerHost)
				end
			end
		else
			local strFilePath = net.ReadString()
			isLooped = false
			net.Start( "playFromServer" )
			net.WriteString( strFilePath )
			net.Send(player.GetAll())
		end
	end
end )
net.Receive( "toServerUpdateLoop", function(length, sender )
	if sender:IsValid() then
		isLooped = net.ReadBool()
		net.Start( "loopFromServer" )
		net.WriteBool(isLooped)
		net.Send(player.GetAll())
	end
end )

net.Receive( "sv_autoPlay", function(length, sender )
	if sender:IsValid() then
		isAutoPlayed = net.ReadBool()
		net.Start( "cl_autoPlay" )
		net.WriteBool(isAutoPlayed)
		net.Send(player.GetAll())
	end
end )

net.Receive( "sv_getAutoPlaySong", function(length, sender )
	if !isnumber(playerHost) and playerHost:IsPlayer() then
		net.Start( "cl_ansAutoPlaySong" )
		net.WriteString(liveSong)
		net.Send(playerHost)
	elseif sender:IsValid() then
		net.Start( "cl_errAutoPlaySong" )
		net.Send(sender)
	end
end )

net.Receive( "toServerAdminStop", function(length, sender )
	if sender:IsValid() then
		liveSong = ""
		liveSeek = 0
		playerHost = 0
		isLooped = false
		isAutoPlayed = false
		net.Start( "stopFromServerAdmin" )
		net.Send(player.GetAll())
	end
end )


net.Receive( "toServerStop", function(length, sender )
	if sender:IsValid() then
		net.Start( "stopFromServer" )
		net.Send(player.GetAll())
	end
end )

net.Receive( "toServerSeek", function(length, sender )
	local seekTime = net.ReadDouble()
	if sender:IsValid() then
		net.Start( "seekFromServer" )
		net.WriteDouble(seekTime)
		net.Send(player.GetAll())
	end
end )