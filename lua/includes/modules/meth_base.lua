local dermaBase = {}

local defaultFont = "arialDefault"

local function init(contextMenu, contextMargin)
    dermaBase.painter = include("includes/modules/meth_paint.lua")()

	dermaBase.contextmedia = vgui.Create("DMultiButton", contextMenu)

	dermaBase.main = vgui.Create("DgMPlayerFrame")

	bottom_p                = vgui.Create("Panel", dermaBase.main)
	dermaBase.sliderseek    = vgui.Create("DSeekBar",bottom_p)
	dermaBase.slidervol     = vgui.Create("DNumSliderNoLabel", bottom_p)

	-- Buttons
	dermaBase.buttonstop    = vgui.Create("DBetterButton", dermaBase.main)
	dermaBase.buttonpause   = vgui.Create("DBetterButton", dermaBase.main)
	dermaBase.buttonplay    = vgui.Create("DBetterButton", dermaBase.main)

	-- Music List Server/Client button swap
	dermaBase.buttonswap    = vgui.Create("Panel", dermaBase.main)
	dermaBase.labelswap     = vgui.Create("DLabel", dermaBase.buttonswap)
	dermaBase.labelswap:SetTextColor(Color(230, 230, 230))

	-- Music List
	dermaBase.musicsheet    = vgui.Create("DSideMenu",dermaBase.main)
	dermaBase.songlist      = vgui.Create("DBetterListView", dermaBase.musicsheet )

	-- Music Dir
	dermaBase.audiodirsheet = vgui.Create("Panel", dermaBase.musicsheet_colsheet)
	dermaBase.foldersearch	= vgui.Create("DDoubleListView", dermaBase.audiodirsheet )
	dermaBase.foldersearch:SetInfoColor(Color(255, 255, 255))

	-- Music Dir refresh button
	dermaBase.labelrefresh 	= vgui.Create("Panel", dermaBase.audiodirsheet )
	dermaBase.buttonrefresh = vgui.Create("DButton", dermaBase.audiodirsheet)

	-- Settings
	dermaBase.settingsheet 	= vgui.Create("Panel", dermaBase.musicsheet)
	dermaBase.settingPage  	= vgui.Create("DOptions", dermaBase.settingsheet )
	dermaBase.settingPage:SetDefaultFont(defaultFont)

	-- Settings options
	dermaBase.settingPage:Category( "Server Side" )
	dermaBase.cbadminaccess	= dermaBase.settingPage:CheckBox(
        true, "Only admins can play songs on the server", true )
	dermaBase.cbadmindir    = dermaBase.settingPage:CheckBox(
        false, "Only admins can select music dirs", true )

	dermaBase.settingPage:Category( "Client Side" )
	dermaBase.contextbutton = dermaBase.settingPage:CheckBox(
        false, "Enable context menu button", false )
	dermaBase.hotkey        = dermaBase.settingPage:CheckBox(
        false, "Disable F3 hotkey", false )
	dermaBase.darkmode      = dermaBase.settingPage:CheckBox(
        true, "Enable dark mode", false )

	-- Panel
	bottom_p:DockMargin(0,0,25,0)
	bottom_p:Dock(BOTTOM)

	dermaBase.foldersearch:Dock(FILL)
	dermaBase.settingsheet:Dock(FILL)
	dermaBase.slidervol:Dock(RIGHT)

	dermaBase.contextmedia:SetPos(ScrW() - contextMargin, 0)
	dermaBase.contextmedia:SetSize(ScrW() - (ScrW() - contextMargin), 30)

	-- Visibility
	dermaBase.main:SetVisible(false)
	dermaBase.buttonswap:SetVisible(false)
	dermaBase.contextmedia:SetVisible(false)

	-- Font style
	dermaBase.songlist:SetFont(defaultFont)
	dermaBase.slidervol:SetFont(defaultFont)
	dermaBase.sliderseek:SetTextFont(defaultFont)
	dermaBase.contextmedia:SetFont(defaultFont)
	dermaBase.contextmedia:SetTextColor(Color(0, 0, 0))

	dermaBase.buttonstop:SetFont(defaultFont)
	dermaBase.buttonpause:SetFont(defaultFont)
	dermaBase.buttonplay:SetFont(defaultFont)

	-- Convars for checkboxes
	dermaBase.slidervol:SetConVar("gmpl_vol")
	dermaBase.cbadminaccess:SetConVar("gmpl_svadminplay", "1",
        "[gMusic Player] Allows only admins to play songs on the server")
	dermaBase.cbadmindir:SetConVar("gmpl_svadmindir", "0",
        "[gMusic Player] Only admins can select Music Dirs")

	dermaBase.contextbutton:SetConVar("gmpl_cmenu", "0",
        "[gMusic Player] Disable/Enable the context menu button")
	dermaBase.contextbutton:SetEnabled(IsValid(contextMenu))

	dermaBase.hotkey:SetConVar(
        "gmpl_nohotkey", "0", "[gMusic Player] Disable/Enable the F3 hotkey")
	dermaBase.darkmode:SetConVar(
        "gmpl_dark", "1", "[gMusic Player] Toggle dark mode theme")
	-- DO gmpl_resetsize for dumbass
	-- Do gmpl_size x y
	-- bring player to front if pressing context while already opened with f3
	-- bind F3 back to gm_showspare1 if or add some kind of F3 it's bound to gmplshow
	-- check seek with some tf2 songs it doesnt stop when reaches end
	-- text color of song item doesnt keep the right one when switching from/to dark mode
	-- Looping should work even when autoplay is on. Good for autoplay+loop combo
	-- wolf has a white bar instead of Song. Test with all vocas see if you can get the bug to appear
	-- make autoplay operational serverside similar to how is looped works
	-- find why some songs does not stop when reach end. This also blocks the autoplay when it happens.  test with tf2 and hl2 songs the short the better
	-- also try to find a way to auto invalidate the song list if you add/rem songs so you dont need to resize it a bit. Scroll doesn't appear cuz of this sometimes
	-- context button shows Label instead of song name. Also make the timer less taller
	-- it shows no host even though somebody was the host.. fix
	-- pause the song serverside if admin pause
	-- seekbar prevent stopping the sound if you still hold on the click. If you seeked to the end

	-- Clicks M1
	dermaBase.contextmedia.DoClick = function()
		net.Start( "toServerContextMenu" )
		net.SendToServer()
	end

	-- Clicks M2
	dermaBase.contextmedia.DoRightClick  = function()
		dermaBase.buttonpause.DoClick()
	end

	-- Clicks M3
	dermaBase.contextmedia.DoMiddleClick  = function()
		dermaBase.buttonpause.DoRightClick()
	end

	-- Clicks M4
	dermaBase.contextmedia.DoM4Click  = function()
		dermaBase.buttonpause.DoRightClick()
	end

    dermaBase.contextmedia.OnScreenSizeChanged = function(old_width, old_height)
        dermaBase.contextmedia:SetPos(ScrW() - contextMargin, 0)
        dermaBase.contextmedia:SetSize(ScrW() - (ScrW() - contextMargin), 30)
	end

	dermaBase.cbadminaccess.OnCvarChange = function( panel, oldVal, newVal )
		net.Start("toServerRefreshAccess")
		net.WriteBool(newVal)
		net.SendToServer()
	end

	dermaBase.cbadminaccess.AfterChange = function( panel, bVal )
		net.Start("toServerRefreshAccess_msg")
		net.WriteBool(bVal)
		net.SendToServer()
	end

	dermaBase.cbadmindir.OnCvarChange = function( panel, oldVal, newVal )
		net.Start("toServerRefreshAccessDir")
		net.WriteBool(newVal)
		net.SendToServer()
	end

	dermaBase.cbadmindir.AfterChange = function( panel, bVal )
		net.Start("toServerRefreshAccessDir_msg")
		net.WriteBool(bVal)
		net.SendToServer()
	end

	dermaBase.contextbutton.AfterChange = function( panel, val )
		if !IsValid(contextMenu) then return end
        local bVal = tobool(val)
		dermaBase.contextmedia:SetVisible(bVal)
	end

    dermaBase.painter.update_colors = function ()
        dermaBase.painter.paintNone({
            dermaBase.buttonrefresh, dermaBase.buttonstop, dermaBase.buttonpause, dermaBase.buttonplay, dermaBase.buttonaplay,
            dermaBase.musicsheet.Navigation, dermaBase.foldersearch,
            dermaBase.musicsheet, dermaBase.foldersearch.btnRebuildMid,
            dermaBase.foldersearch.btnAddMid, dermaBase.foldersearch.btnRemMid
        })
        local white = Color(255, 255, 255)
        local hoverWhite = Color(230, 230, 230, 50)

        dermaBase.buttonrefresh:SetTextColor(white)
        dermaBase.buttonstop:SetTextColor(white)
        dermaBase.buttonpause:SetTextColor(white)
        dermaBase.buttonplay:SetTextColor(white)

        dermaBase.painter.paintSlider(dermaBase.sliderseek)
        dermaBase.painter.paintSlider(dermaBase.slidervol)

        dermaBase.painter.paintBG(dermaBase.main)

        dermaBase.painter.paintBG(
            dermaBase.musicsheet.Navigation, Color(120, 120, 120))
        for k, sideItem in pairs(dermaBase.musicsheet.Items) do
            if (!sideItem.Button) then continue end
                dermaBase.painter.paintBG(
                    sideItem.Button, Color(255, 255 ,255))
                dermaBase.painter.paintHoverBG(
                    sideItem.Button, Color(0, 0, 0, 50))
                sideItem.Button:SetTextColor(Color(0, 0, 0))
        end
        dermaBase.painter.paintHoverBG(dermaBase.buttonrefresh, hoverWhite)
        dermaBase.painter.paintHoverBG(dermaBase.buttonstop, hoverWhite)
        dermaBase.painter.paintHoverBG(dermaBase.buttonpause, hoverWhite)
        dermaBase.painter.paintHoverBG(dermaBase.buttonplay, hoverWhite)

        dermaBase.painter.paintList(dermaBase.songlist)
        dermaBase.painter.paintHoverList(dermaBase.songlist)

        dermaBase.painter.paintScroll(dermaBase.songlist, Color(120, 120, 120))
        dermaBase.painter.paintText(dermaBase.songlist)

        dermaBase.painter.paintText(dermaBase.foldersearch)
        dermaBase.painter.paintList(dermaBase.foldersearch)
        dermaBase.painter.paintColumn(dermaBase.foldersearch)
        dermaBase.painter.paintHoverColumn(dermaBase.foldersearch, hoverWhite)
        dermaBase.painter.paintScroll(
            dermaBase.foldersearch, Color(120, 120, 120))

        dermaBase.painter.paintHoverBG(
            dermaBase.foldersearch.btnRebuildMid, hoverWhite)
        dermaBase.painter.paintHoverBG(
            dermaBase.foldersearch.btnAddMid, hoverWhite)
        dermaBase.painter.paintHoverBG(
            dermaBase.foldersearch.btnRemMid, hoverWhite)

        dermaBase.painter.paintThemeBG(dermaBase.settingsheet)
        dermaBase.painter.paintScroll(dermaBase.settingPage)
        dermaBase.painter.paintText(dermaBase.settingPage)
        for _, category in pairs(dermaBase.settingPage.Categories) do
            dermaBase.painter.paintBG(category)
            category:SetTextColor(white)
        end
    end

return dermaBase
end

return init
