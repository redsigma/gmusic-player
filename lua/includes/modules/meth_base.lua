local baseMusic = {}

local defaultFont = "arialDefault"

local function init( contextMenu, contextMargin )

    local ContextMedia = vgui.Create("DMultiButton", g_ContextMenu)
    ContextMedia:SetColor(Color(0,0,0))
    ContextMedia:SetFont(defaultFont)
    ContextMedia:SetPos(ScrW() - contextMargin, 0)
    ContextMedia:SetSize(ScrW()-(ScrW() - contextMargin), 30)
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

    local Main_colsheet = vgui.Create("DColumnSheet",Main)
    local Main_colsheet_SongList = vgui.Create( "DListView", Main_colsheet )

    local Main_colsheet_AudioDirSettings = vgui.Create("Panel", Main_colsheet)
    local Main_colsheet_AudioDirSettings_folderSearch = vgui.Create( "DDoubleListView", Main_colsheet_AudioDirSettings )
    Main_colsheet_AudioDirSettings_folderSearch:Dock(FILL)

    local labelRefreshSongList = vgui.Create( "Panel", Main_colsheet_AudioDirSettings )
    local Main_colsheet_AudioDirSettings_buttonRefresh = vgui.Create("DButton", Main_colsheet_AudioDirSettings)

    local Main_colsheet_Settings = vgui.Create("Panel", Main_colsheet)
    Main_colsheet_Settings:Dock(FILL)

    local Main_colsheet_Settings_Options = vgui.Create( "DScrollPanel", Main_colsheet_Settings )
    Main_colsheet_Settings_Options:Dock(FILL)


    local Main_colsheet_Settings_settingPage = vgui.Create( "DOptions", Main_colsheet_Settings_Options )
    Main_colsheet_Settings_settingPage:SetDefaultFont(defaultFont)

    local settingsW = Main_colsheet_Settings:GetWide()

    local Main_colsheet_Settings_settingPage_catServer = Main_colsheet_Settings_settingPage:Category( "Server Side Options" )

    

    local Main_colsheet_Settings_settingPage_cbAdminAccess = Main_colsheet_Settings_settingPage:CheckBox( true, "Only admins can play songs on the server", true )
    Main_colsheet_Settings_settingPage_cbAdminAccess:SetConVar("gmpl_svadminplay", "1", "[gMusic Player] Allows only admins to play songs on the server")

    local Main_colsheet_Settings_settingPage_cbAdminDir = Main_colsheet_Settings_settingPage:CheckBox( false,"Only admins can select music dirs", true )
    Main_colsheet_Settings_settingPage_cbAdminDir:SetConVar("gmpl_svadmindir", "0", "[gMusic Player] Only admins can select Music Dirs")


    local Main_colsheet_Settings_settingPage_catClient = Main_colsheet_Settings_settingPage:Category( "Client Side Options" )

    local Main_colsheet_Settings_settingPage_contextbutton = Main_colsheet_Settings_settingPage:CheckBox( false,"Enable context menu button", false )
    local Main_colsheet_Settings_settingPage_contexthotkey = Main_colsheet_Settings_settingPage:CheckBox( false,"Disable F3 hotkey", false )
    Main_colsheet_Settings_settingPage_contexthotkey:SetEnabled(false)
    Main_colsheet_Settings_settingPage_contexthotkey:SetPos(20, 0)
    Main_colsheet_Settings_settingPage_contexthotkey:SetConVar("gmpl_nohotkey", "0", "[gMusic Player] Disable/Enable the F3 hotkey")


    baseMusic.contextmedia  =   ContextMedia

    baseMusic.main          =   Main
    baseMusic.buttonstop    =   Main_buttonStop
    baseMusic.buttonpause   =   Main_buttonPause
    baseMusic.buttonplay    =   Main_buttonPlay
    baseMusic.sliderseek    =   Main_sliderSeek
    baseMusic.slidervol     =   Main_sliderVolume

    baseMusic.buttonswap    =   Main_buttonSwap
    baseMusic.labelswap     =   labelSwap

    baseMusic.musicsheet    =   Main_colsheet
    baseMusic.songlist      =   Main_colsheet_SongList
    baseMusic.audiodirsheet =   Main_colsheet_AudioDirSettings
    baseMusic.foldersearch  =   Main_colsheet_AudioDirSettings_folderSearch

    baseMusic.buttonrefresh =   Main_colsheet_AudioDirSettings_buttonRefresh
    baseMusic.labelrefresh  =   labelRefreshSongList

    baseMusic.settingsheet  =   Main_colsheet_Settings
    baseMusic.cloptions     =   Main_colsheet_Settings_Options

    baseMusic.settingPage   =   Main_colsheet_Settings_settingPage
    baseMusic.cbadminaccess =   Main_colsheet_Settings_settingPage_cbAdminAccess
    baseMusic.cbadmindir    =   Main_colsheet_Settings_settingPage_cbAdminDir
    baseMusic.contextbutton =   Main_colsheet_Settings_settingPage_contextbutton
    baseMusic.contexthotkey =   Main_colsheet_Settings_settingPage_contexthotkey


    baseMusic.contextmedia.DoClick = function()
        net.Start( "toServerContext" )
        net.SendToServer()
    end


    baseMusic.cbadminaccess.AfterConvarChanged = function( panel, bVal )
        net.Start("toServerRefreshAccess_msg")
        net.WriteBool(bVal)
        net.SendToServer()
    end   

    baseMusic.cbadminaccess.AfterChange = function( panel, bVal )
        net.Start("toServerRefreshAccess")
        net.WriteBool(bVal)
        net.SendToServer()
    end   


    baseMusic.cbadmindir.AfterConvarChanged = function( panel, bVal )
        net.Start("toServerRefreshAccessDir_msg")
        net.WriteBool(bVal)
        net.SendToServer()
    end   

    baseMusic.cbadmindir.AfterChange = function( panel, bVal )
        net.Start("toServerRefreshAccessDir")
        net.WriteBool(bVal)
        net.SendToServer()
    end


    baseMusic.contextbutton.BeforeChange = function( panel )

        if !baseMusic.contexthotkey:GetChecked() then
            panel:AllowContinue(true)
        else
            panel:AllowContinue(false) -- don't think this gets selected cuz of GetDisabled
        end
    end

    baseMusic.contexthotkey.BeforeConvarChanged = function( panel, val )

        if val then
            if !baseMusic.contextbutton:GetChecked() then
                baseMusic.contextbutton:DoClick() 
                baseMusic.contextbutton:SetInactive(true)
            end
        end
    end

    baseMusic.contextbutton.AfterChange = function( panel, bVal )

        if bVal then
          getmetatable(contextMenu).DockMargin(contextMenu,0, 0, contextMargin, 0)
        else
          getmetatable(contextMenu).DockMargin(contextMenu,0, 0, 0, 0)
        end

        baseMusic.contexthotkey:SetEnabled(bVal)

        if g_ContextMenu:IsVisible() then
          getmetatable(contextMenu).InvalidateParent(contextMenu,false)
        end

        baseMusic.contextmedia:SetVisible(bVal)
    end
    baseMusic.contexthotkey.AfterChange = function( panel, bVal )
        baseMusic.contextbutton:SetInactive(bVal)
    end

return baseMusic
end

return init