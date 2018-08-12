local dermaBase = {}

local defaultFont = "arialDefault"

local function init( contextMenu, contextMargin )

	local ContextMedia = vgui.Create("DMultiButton", g_ContextMenu)
	ContextMedia:SetFont(defaultFont)
	ContextMedia:SetPos(ScrW() - contextMargin, 0)
	ContextMedia:SetSize(ScrW() - (ScrW() - contextMargin), 30)
	ContextMedia:SetVisible(false)

	local Main = vgui.Create("DgMPlayerFrame")
	Main:SetVisible(false)

	local Main_buttonStop = vgui.Create("DButton", Main)
	local Main_buttonPause = vgui.Create("DButton", Main)
	local Main_buttonPlay = vgui.Create("DButton", Main)
	local Main_sliderSeek = vgui.Create("DSeekBar",Main)
	local Main_sliderVolume = vgui.Create("DNumSliderNoLabel", Main)

	local Main_buttonSwap = vgui.Create("Panel", Main)
	Main_buttonSwap:SetVisible(false)

	local labelSwap = vgui.Create("DLabel", Main_buttonSwap)

	local Main_colsheet = vgui.Create("DSideMenu",Main)
	local Main_colsheet_SongList = vgui.Create( "DBetterListView", Main_colsheet )
	Main_colsheet_SongList:SetFont(defaultFont)

	local Main_colsheet_AudioDirSettings = vgui.Create("Panel", Main_colsheet)
	local Main_colsheet_AudioDirSettings_folderSearch = vgui.Create( "DDoubleListView", Main_colsheet_AudioDirSettings )
	Main_colsheet_AudioDirSettings_folderSearch:Dock(FILL)

	local labelRefreshSongList = vgui.Create( "Panel", Main_colsheet_AudioDirSettings )
	local Main_colsheet_AudioDirSettings_buttonRefresh = vgui.Create("DButton", Main_colsheet_AudioDirSettings)

	local Main_colsheet_Settings = vgui.Create("Panel", Main_colsheet)
	Main_colsheet_Settings:Dock(FILL)
	Main_colsheet_Settings.Paint = function(panel, w, h)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawRect(0, 0, w, h)
	end

	local Main_colsheet_Settings_settingPage = vgui.Create( "DOptions", Main_colsheet_Settings )
	Main_colsheet_Settings_settingPage:SetDefaultFont(defaultFont)

	Main_colsheet_Settings_settingPage:Category( "Server Side Options" )
	local Main_colsheet_Settings_settingPage_cbAdminAccess = Main_colsheet_Settings_settingPage:CheckBox( true, "Only admins can play songs on the server", true )
	Main_colsheet_Settings_settingPage_cbAdminAccess:SetConVar("gmpl_svadminplay", "1", "[gMusic Player] Allows only admins to play songs on the server")
	local Main_colsheet_Settings_settingPage_cbAdminDir = Main_colsheet_Settings_settingPage:CheckBox( false,"Only admins can select music dirs", true )
	Main_colsheet_Settings_settingPage_cbAdminDir:SetConVar("gmpl_svadmindir", "0", "[gMusic Player] Only admins can select Music Dirs")

	Main_colsheet_Settings_settingPage:Category( "Client Side Options" )
	local Main_colsheet_Settings_settingPage_contextbutton = Main_colsheet_Settings_settingPage:CheckBox( false,"Enable context menu button", false )
	Main_colsheet_Settings_settingPage_contextbutton:SetConVar("gmpl_cmenu", "0", "[gMusic Player] Disable/Enable the context menu button")
	Main_colsheet_Settings_settingPage_contextbutton:SetEnabled(IsValid(g_ContextMenu))

	local Main_colsheet_Settings_settingPage_contexthotkey = Main_colsheet_Settings_settingPage:CheckBox( false,"Disable F3 hotkey", false )
	Main_colsheet_Settings_settingPage_contexthotkey:SetConVar("gmpl_nohotkey", "0", "[gMusic Player] Disable/Enable the F3 hotkey")

	dermaBase.contextmedia  =   ContextMedia

	dermaBase.main          =   Main
	dermaBase.buttonstop    =   Main_buttonStop
	dermaBase.buttonpause   =   Main_buttonPause
	dermaBase.buttonplay    =   Main_buttonPlay
	dermaBase.sliderseek    =   Main_sliderSeek
	dermaBase.slidervol     =   Main_sliderVolume

	dermaBase.buttonswap    =   Main_buttonSwap
	dermaBase.labelswap     =   labelSwap

	dermaBase.musicsheet    =   Main_colsheet
	dermaBase.songlist      =   Main_colsheet_SongList
	dermaBase.audiodirsheet =   Main_colsheet_AudioDirSettings
	dermaBase.foldersearch  =   Main_colsheet_AudioDirSettings_folderSearch

	dermaBase.buttonrefresh =   Main_colsheet_AudioDirSettings_buttonRefresh
	dermaBase.labelrefresh  =   labelRefreshSongList

	dermaBase.settingsheet  =   Main_colsheet_Settings

	dermaBase.settingPage   =   Main_colsheet_Settings_settingPage
	dermaBase.cbadminaccess =   Main_colsheet_Settings_settingPage_cbAdminAccess
	dermaBase.cbadmindir    =   Main_colsheet_Settings_settingPage_cbAdminDir

	dermaBase.contextbutton =   Main_colsheet_Settings_settingPage_contextbutton
	dermaBase.hotkey 		=	Main_colsheet_Settings_settingPage_contexthotkey

	dermaBase.contextmedia.DoClick = function()
		net.Start( "toServerContext" )
		net.SendToServer()
	end
	dermaBase.contextmedia.DoRightClick  = function()
		dermaBase.buttonpause.DoClick()
	end
	dermaBase.contextmedia.DoMiddleClick  = function()
		dermaBase.buttonpause.DoRightClick()
	end
	dermaBase.contextmedia.DoM4Click  = function()
		dermaBase.buttonpause.DoRightClick()
	end

	dermaBase.cbadminaccess.AfterConvarChanged = function( panel, bVal )
		net.Start("toServerRefreshAccess_msg")
		net.WriteBool(bVal)
		net.SendToServer()
	end

	dermaBase.cbadminaccess.AfterChange = function( panel, bVal )
		net.Start("toServerRefreshAccess")
		net.WriteBool(bVal)
		net.SendToServer()
	end


	dermaBase.cbadmindir.AfterConvarChanged = function( panel, bVal )
		net.Start("toServerRefreshAccessDir_msg")
		net.WriteBool(bVal)
		net.SendToServer()
	end

	dermaBase.cbadmindir.AfterChange = function( panel, bVal )
		net.Start("toServerRefreshAccessDir")
		net.WriteBool(bVal)
		net.SendToServer()
	end

	dermaBase.contextbutton.AfterChange = function( panel, bVal )
		if !IsValid(g_ContextMenu) then return end

		if bVal then getmetatable(contextMenu).DockMargin(contextMenu,0, 0, contextMargin, 0)
		else getmetatable(contextMenu).DockMargin(contextMenu,0, 0, 0, 0)
		end

		if g_ContextMenu:IsVisible() then
			getmetatable(contextMenu).InvalidateParent(contextMenu,false)
		end

		dermaBase.contextmedia:SetVisible(bVal)
	end

return dermaBase
end

return init