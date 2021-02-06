local mediaplayer = nil
local base_panel_colors = nil

local dermaBase = {}
local contextMenu
local contextMenuMargin = ScrW() / 5
local ingameView

surface.CreateFont( "arialDefault", {
	font = "Arial",
	extended = false,
	size = 16,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

local function createMPlayer(ply)
	mediaplayer:SyncSettings(ply)
	mediaplayer:create()

	-- dermaBase.main:MoveToFront() -- prevents conflcits from other addons that are using the ScreenClicker
	-- ingameView = dermaBase.main:GetParent() -- must do this else the freking half invisible window appears
											-- still don't hav a clue what could cause it
end

local function showMPlayer( newHost )
	if dermaBase.main:IsVisible() then

		-- if dermaBase.main:HasParents(g_ContextMenu) then --  moving while in context with hotkey
		-- 	dermaBase.main:SetParent(ingameView)
		-- 	dermaBase.main:SetVisible(false)
		-- else
			RememberCursorPosition()
			dermaBase.main:SetVisible(false)
            -- dermaBase.main:SetWorldClicker(false)
			gui.EnableScreenClicker(false)
		-- end
	else
		-- if LocalPlayer():IsWorldClicking() then -- focus if context already opened
			-- dermaBase.main:SetParent(contextMenu)
		-- elseif dermaBase.main:HasParents(ingameView) then
			gui.EnableScreenClicker(true)
            -- dermaBase.main:SetWorldClicker(true)
		-- end

		mediaplayer:SetSongHost(newHost)
		dermaBase.main:SetVisible(true)
		mediaplayer:SyncSettings(nil) -- will sync using LocalPlayer()
		RestoreCursorPosition()
	end
end

hook.Add("ContextMenuCreated", "create_context", function(g_ContextMenu)
	-- print("Context created")
    PrintTable(debug.getmetatable(g_ContextMenu))
    contextMenu = g_ContextMenu
end)

-- hook.Add("PopulateMenuBar", "getContext", function( menubar )
-- 	contextMenu = menubar
-- end)

--[[-------------------------------------------------------------------------
Runs if server not just Created
---------------------------------------------------------------------------]]--
net.Receive( "sendServerSettings", function()
	local serverSettings = net.ReadTable()

	dermaBase.cbadminaccess:SetChecked(serverSettings.admin_server_access)
	dermaBase.cbadmindir:SetChecked(serverSettings.admin_dir_access)
end )


--[[-------------------------------------------------------------------------
First Run on server start
---------------------------------------------------------------------------]]--
net.Receive("createMenu", function()
    dermaBase = include("includes/modules/meth_base.lua")(
        contextMenu, contextMenuMargin)
	-- hook.Remove("PopulateMenuBar", "getContext")

	while !isfunction(dermaBase.main.IsVisible) do
		MsgC(Color( 144, 219, 232 ), "[gMusic Player]", Color(255, 0, 0),
            " Failed to initialize - retrying\n" )
		dermaBase = include("includes/modules/meth_base.lua")(
            contextMenu, contextMenuMargin)
	end

    include("gmpl/cl_cvars.lua")(dermaBase)

	require("musicplayerclass")
	mediaplayer = Media(dermaBase)

	net.Start("serverFirstMade")
	net.SendToServer()

	local currentPlyIsAdmin = net.ReadBool()
	mediaplayer:readFileSongs()
	createMPlayer(currentPlyIsAdmin)

    -- print("Creating base panel:")
    -- base_panel_colors = vgui.Create("DBasePanel")
    -- base_panel_colors:say()
end )

net.Receive( "getSettingsFromFirstAdmin", function()
    if IsValid(LocalPlayer()) and LocalPlayer():IsAdmin() then
		local storeCurrentSettings = {}
		storeCurrentSettings.admin_server_access =
            GetConVar("gmpl_svadminplay"):GetBool()
		storeCurrentSettings.admin_dir_access =
            GetConVar("gmpl_svadmindir"):GetBool()

		net.Start("updateSettingsFromFirstAdmin")
		net.WriteTable(storeCurrentSettings)

		if storeCurrentSettings.admin_dir_access then
			net.WriteTable(mediaplayer:getLeftSongList())
			net.WriteTable(mediaplayer:getRightSongList())
		end
		net.SendToServer()
	end
end )
---------------------------------------------------------------------------]]--


--[[-------------------------------------------------------------------------
Server convars
---------------------------------------------------------------------------]]--
net.Receive( "refreshAdminAccess", function(length, sender)
	local tmpVal = net.ReadBool()
	dermaBase.cbadminaccess:SetChecked(tmpVal)
end )

net.Receive( "refreshAdminAccessDir", function(length, sender)
	local tmpVal = net.ReadBool()
	dermaBase.cbadmindir:SetChecked(tmpVal)
end )
---------------------------------------------------------------------------]]--



net.Receive("openmenu", function()
	local adminHost = net.ReadType()
	mediaplayer:SetSongHost(adminHost)
	showMPlayer(adminHost)
end )

net.Receive("openmenucontext", function()
	local adminHost = net.ReadType()
	mediaplayer:SetSongHost(adminHost)

	-- dermaBase.main:SetParent(g_ContextMenu)
	showMPlayer(adminHost)
	-- gui.EnableScreenClicker(false)
end )

concommand.Add("gmplshow", function()
	showMPlayer()
end)


cvars.AddChangeCallback( "gmpl_vol", function( convar , oldValue , newValue  )
	if !istable(mediaplayer) then return end
	if (isnumber(util.StringToType( newValue, "Float" ))) then
		-- if istable(mediaplayer) then
			mediaplayer:SetVolume(newValue)
		-- end
	elseif (isnumber(util.StringToType( oldValue, "Float" ))) then
		-- if istable(mediaplayer) then
			mediaplayer:SetVolume(oldValue)
			MsgC(Color(255,0,0),"Only 0 - 100 value is allowed. Keeping value " .. oldValue .. "\n")
		-- end
	end
end )