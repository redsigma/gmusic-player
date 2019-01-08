local mediaplayer = nil



local dermaBase = {}
local contextMenu
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
	local ObjPaint = include("includes/modules/meth_paint.lua")(derma.GetSkinTable())

	ObjPaint.paintButton(dermaBase.buttonrefresh)
	ObjPaint.paintButton(dermaBase.buttonstop)
	ObjPaint.paintButton(dermaBase.buttonpause)
	ObjPaint.paintButton(dermaBase.buttonplay)
	ObjPaint.paintSlider(dermaBase.sliderseek)
	ObjPaint.paintSlider(dermaBase.slidervol)


	ObjPaint.paintBase(dermaBase.main)
	ObjPaint.setDisabled(dermaBase.musicsheet)
	ObjPaint.paintList(dermaBase.songlist)
	ObjPaint.paintDoubleList(dermaBase.foldersearch)
	ObjPaint.paintOptions(dermaBase.settingPage)
	ObjPaint.paintText(dermaBase.contextmedia)

	dermaBase.musicsheet.Navigation.Paint = function(panel, w, h)
		surface.SetDrawColor( Color(150, 150, 150) )
		surface.DrawRect( 0, 0, w, h )
	end
	for k, v in pairs(dermaBase.musicsheet.Items) do
		if (!v.Button) then continue end
		v.Button:SetTextColor(Color(0, 0, 0))
		v.Button:DockMargin( 0, 0, 0, 1 )

		v.Button.Paint = function(panel, w, h)
			surface.SetDrawColor( Color(255, 255, 255) )
			surface.DrawRect( 0, 0, w, h )
		end
	end

	ObjPaint.setBGHover(dermaBase.buttonrefresh)
	ObjPaint.setBGHover(dermaBase.buttonstop)
	ObjPaint.setBGHover(dermaBase.buttonpause)
	ObjPaint.setBGHover(dermaBase.buttonplay)

end




local function createMPlayer(ply)
	mediaplayer:SyncSettings(ply)
	mediaplayer:create()

	dermaBase.main:MoveToFront() -- prevents conflcits from other addons that are using the ScreenClicker
	ingameView = dermaBase.main:GetParent()

	paintMediaPlayer()
	dermaBase.main:SetParent(g_ContextMenu) -- must do this else the freking half invisible window appears
											-- still don't hav a clue what could cause it
end

local function showMPlayer( newHost )
	if dermaBase.main:IsVisible() then
		if dermaBase.main:HasParents(g_ContextMenu) then
			dermaBase.main:SetParent(ingameView)
			gui.EnableScreenClicker(true)
		else

			RememberCursorPosition()      -- still doesn't work
			dermaBase.main:SetVisible(false)
			gui.EnableScreenClicker(false)
		end
	else

		if dermaBase.main:HasParents(g_ContextMenu) then
			dermaBase.main:SetParent(ingameView)
		end
		mediaplayer:SetSongHost(newHost)
		gui.EnableScreenClicker(true)
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
	dermaBase = include("includes/modules/meth_base.lua")(contextMenu, ScrW() / 5)
	hook.Remove("PopulateMenuBar", "getContext")

	while !isfunction(dermaBase.main.IsVisible) do
		MsgC( Color( 144, 219, 232 ), "[gMusic Player]", Color( 255, 0, 0 ), " Failed to initialize - retrying\n" )
		dermaBase = include("includes/modules/meth_base.lua")(contextMenu, ScrW() / 5)
	end

	require("musicplayerclass")
	mediaplayer = Media(dermaBase)

	net.Start("serverFirstMade")
	net.SendToServer()

	local currentPlyIsAdmin = net.ReadBool()
	mediaplayer:readFileSongs()
	createMPlayer(currentPlyIsAdmin)

end )

net.Receive( "getSettingsFromFirstAdmin", function()
	if LocalPlayer():IsValid() and LocalPlayer():IsAdmin() then
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
	if dermaBase.contextbutton:GetChecked() then
		dermaBase.contextbutton:AfterChange(true)
	end

end )

---------------------------------------------------------------------------]]--

net.Receive( "openmenu", function()
	local adminHost = net.ReadType()
	mediaplayer:SetSongHost(newHost)
	showMPlayer(adminHost)
end )

net.Receive( "openmenucontext", function()
	mediaplayer:SetSongHost(newHost)

	dermaBase.main:SetParent(g_ContextMenu)
	if dermaBase.main:IsVisible() then
		dermaBase.main:SetVisible(false)
		gui.EnableScreenClicker(false)
	else
		dermaBase.main:SetVisible(true)
	end

end )

concommand.Add("gmplshow", function()
	showMPlayer()
end)


cvars.AddChangeCallback( "gmpl_vol", function( convar , oldValue , newValue  )
	if (TypeID(util.StringToType( newValue, "Float" )) == TYPE_NUMBER) then
		if TypeID(mediaplayer) ~= TYPE_NIL then
			mediaplayer:SetVolume(newValue)
		end
	elseif (TypeID(util.StringToType( oldValue, "Float" )) == TYPE_NUMBER) then
		if TypeID(mediaplayer) ~= TYPE_NIL then
			mediaplayer:SetVolume(oldValue)
			MsgC(Color(255,0,0),"Only 0-100 value is allowed. Value not changed ( \"" ..  oldValue .. "\" )\n")
		end
	end
end )
