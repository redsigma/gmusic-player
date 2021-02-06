
local mediaplayer = nil
local ObjPaint = nil

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

local function paintMediaPlayer()
	ObjPaint.paintNone({
		dermaBase.buttonrefresh, dermaBase.buttonstop, dermaBase.buttonpause,
		dermaBase.buttonplay, dermaBase.buttonaplay,
		dermaBase.musicsheet.Navigation, dermaBase.foldersearch, 
		dermaBase.musicsheet,
		dermaBase.foldersearch.btnRebuildMid, dermaBase.foldersearch.btnAddMid,
		dermaBase.foldersearch.btnRemMid
	})
	local white = Color(255, 255, 255)
	local hoverWhite = Color(230, 230, 230, 50)

	dermaBase.buttonrefresh:SetTextColor(white)
	dermaBase.buttonstop:SetTextColor(white)
	dermaBase.buttonpause:SetTextColor(white)
	dermaBase.buttonplay:SetTextColor(white)

	ObjPaint.paintSlider(dermaBase.sliderseek)
	ObjPaint.paintSlider(dermaBase.slidervol)

	ObjPaint.paintBG(dermaBase.main)

	ObjPaint.paintBG(dermaBase.musicsheet.Navigation, Color(120, 120, 120))
	for k, sideItem in pairs(dermaBase.musicsheet.Items) do
		if (!sideItem.Button) then continue end
		ObjPaint.paintBG(sideItem.Button, Color(255, 255 ,255))
		ObjPaint.paintHoverBG(sideItem.Button, Color(0, 0, 0, 50))
		sideItem.Button:SetTextColor(Color(0, 0, 0))
	end

	ObjPaint.paintHoverBG(dermaBase.buttonrefresh, hoverWhite)
	ObjPaint.paintHoverBG(dermaBase.buttonstop, hoverWhite)
	ObjPaint.paintHoverBG(dermaBase.buttonpause, hoverWhite)
	ObjPaint.paintHoverBG(dermaBase.buttonplay, hoverWhite)

	ObjPaint.paintList(dermaBase.songlist)
	ObjPaint.paintHoverList(dermaBase.songlist)

	ObjPaint.paintScroll(dermaBase.songlist, Color(120, 120, 120))
	ObjPaint.paintText(dermaBase.songlist)

	ObjPaint.paintText(dermaBase.foldersearch)
	ObjPaint.paintList(dermaBase.foldersearch)
	ObjPaint.paintColumn(dermaBase.foldersearch)
	ObjPaint.paintHoverColumn(dermaBase.foldersearch, hoverWhite)
	ObjPaint.paintScroll(dermaBase.foldersearch, Color(120, 120, 120))

	ObjPaint.paintHoverBG(dermaBase.foldersearch.btnRebuildMid, hoverWhite)
	ObjPaint.paintHoverBG(dermaBase.foldersearch.btnAddMid, hoverWhite)
	ObjPaint.paintHoverBG(dermaBase.foldersearch.btnRemMid, hoverWhite)

	ObjPaint.paintThemeBG(dermaBase.settingsheet)
	ObjPaint.paintScroll(dermaBase.settingPage)
	ObjPaint.paintText(dermaBase.settingPage)
	for _, category in pairs(dermaBase.settingPage.Categories ) do
		ObjPaint.paintBG(category)
		category:SetTextColor(white)
	end
end

local function createMPlayer(ply)
	mediaplayer:SyncSettings(ply)
	mediaplayer:create()

	dermaBase.main:MoveToFront() -- prevents conflcits from other addons that are using the ScreenClicker
	ingameView = dermaBase.main:GetParent() -- must do this else the freking half invisible window appears
											-- still don't hav a clue what could cause it
end

local function showMPlayer( newHost )
	if dermaBase.main:IsVisible() then

		if dermaBase.main:HasParents(g_ContextMenu) then --  moving while in context with hotkey
			dermaBase.main:SetParent(ingameView)
			dermaBase.main:SetVisible(false)
		else
			RememberCursorPosition()
			dermaBase.main:SetVisible(false)
			gui.EnableScreenClicker(false)
		end
	else
		if LocalPlayer():IsWorldClicking() then -- focus if context already opened
			dermaBase.main:SetParent(g_ContextMenu)
		elseif dermaBase.main:HasParents(ingameView) then
			gui.EnableScreenClicker(true)
		end

		mediaplayer:SetSongHost(newHost)
		dermaBase.main:SetVisible(true)
		mediaplayer:SyncSettings(nil) -- will sync using LocalPlayer()
		RestoreCursorPosition()
	end
end

hook.Add( "PopulateMenuBar", "getContext", function( menubar )
	contextMenu = menubar
end)

--[[-------------------------------------------------------------------------
Runs if server not just Created
---------------------------------------------------------------------------]]--
net.Receive( "sendServerSettings", function()
	local serverSettings = net.ReadTable()

	dermaBase.cbadminaccess:SetChecked(serverSettings.aa)
	dermaBase.cbadmindir:SetChecked(serverSettings.aadir)
end )


--[[-------------------------------------------------------------------------
First Run on server start
---------------------------------------------------------------------------]]--
net.Receive( "createMenu", function()
	dermaBase = include("includes/modules/meth_base.lua")(contextMenu, contextMenuMargin)
	hook.Remove("PopulateMenuBar", "getContext")

	while !isfunction(dermaBase.main.IsVisible) do
		MsgC( Color( 144, 219, 232 ), "[gMusic Player]", Color( 255, 0, 0 ), " Failed to initialize - retrying\n" )
		dermaBase = include("includes/modules/meth_base.lua")(contextMenu, contextMenuMargin)
	end

	require("musicplayerclass")
	mediaplayer = Media(dermaBase)

	net.Start("serverFirstMade")
	net.SendToServer()

	local currentPlyIsAdmin = net.ReadBool()
	mediaplayer:readFileSongs()

	ObjPaint = include("includes/modules/meth_paint.lua")()
	createMPlayer(currentPlyIsAdmin)
end )

net.Receive( "getSettingsFromFirstAdmin", function()
	if IsValid(LocalPlayer()) and LocalPlayer():IsAdmin() then
		local storeCurrentSettings = {}
		storeCurrentSettings.aa = GetConVar("gmpl_svadminplay"):GetBool()
		storeCurrentSettings.aadir = GetConVar("gmpl_svadmindir"):GetBool()

		net.Start("updateSettingsFromFirstAdmin")
		net.WriteTable(storeCurrentSettings)

		if storeCurrentSettings.aadir then
			net.WriteTable(mediaplayer:getLeftSongList())
			net.WriteTable(mediaplayer:getRightSongList())
		end
		net.SendToServer()
	end
end )
---------------------------------------------------------------------------]]--

--[[-------------------------------------------------------------------------
Client convars
---------------------------------------------------------------------------]]--
net.Receive( "requestHotkeyFromServer", function(length, sender )
	if !dermaBase.hotkey:GetChecked() then
		net.Start( "toServerHotkey" )
		net.SendToServer()
	end
end )
net.Receive( "persistClientSettings", function(length, sender )
	dermaBase.darkmode.AfterChange = function( panel, bVal )
		ObjPaint.changeTheme(bVal)
		paintMediaPlayer()

		panel.OnCvarWrong = function( panel, old, new )
			MsgC(Color(255,0,0),"Only 0 - 1 value is allowed. Keeping value " .. oldValue .. " \n")
		end

	end dermaBase.darkmode:AfterChange(dermaBase.darkmode:GetChecked())
	dermaBase.contextbutton:AfterChange(dermaBase.contextbutton:GetChecked())

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



net.Receive( "openmenu", function()
	local adminHost = net.ReadType()
	mediaplayer:SetSongHost(adminHost)
	showMPlayer(adminHost)
end )

net.Receive( "openmenucontext", function()
	local adminHost = net.ReadType()
	mediaplayer:SetSongHost(adminHost)

	dermaBase.main:SetParent(g_ContextMenu)
	showMPlayer(adminHost)
	gui.EnableScreenClicker(false)
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
