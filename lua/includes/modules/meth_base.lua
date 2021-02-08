local dermaBase = {}
local defaultFont = "arialDefault"
-- Used for stopping the realtime audio after checking 3 times
-- This also helps if the same pos is pressed multiple times
local count_equals = 0
-- Used for Admin Access checkbox being changed while already on SERVER
local affect_ui_buttons = false
-- callbacks from audio logic
local callbacks = {}
callbacks.OnClientAudioChange = function(media) end -- TODO also check for media:is_looped() cuz i think pause is on false if -- looping so this might not get paused if loop > pause -- if media:is_paused() then --   print("Pause seek end, in paused") --   -- timer.Pause("gmpl_seek_end") -- elseif media:is_stopped() or media:is_missing() then --   print("Pause seek end in stopped") --   -- timer.Pause("gmpl_seek_end") --   dermaBase.sliderseek:ShowSeekBarHandle(false) -- elseif media:is_playing() then --   print("Unpause seek end") --   -- timer.UnPause("gmpl_seek_end") --   dermaBase.sliderseek:ShowSeekBarHandle(true) -- end

local function init(contextMenu, contextMargin)
  dermaBase = {
    cl_seek = 0,
    sv_seek = 0
  }

  dermaBase.mediaplayer = include("includes/modules/musicplayerclass.lua")(dermaBase, callbacks)
  dermaBase.painter = include("includes/modules/meth_paint.lua")()
  dermaBase.interface = include("includes/func/interface.lua")(dermaBase)
  dermaBase.song_data = include("includes/modules/meth_song.lua")(dermaBase)
  dermaBase.contextmedia = vgui.Create("DMultiButton", contextMenu)
  dermaBase.main = vgui.Create("DgMPlayerFrame")
  bottom_p = vgui.Create("Panel", dermaBase.main)
  dermaBase.sliderseek = vgui.Create("DSeekBar", bottom_p)
  dermaBase.slidervol = vgui.Create("DVolumeBar", bottom_p)
  -- Buttons
  dermaBase.buttonstop = vgui.Create("DBetterButton", dermaBase.main)
  dermaBase.buttonpause = vgui.Create("DBetterButton", dermaBase.main)
  dermaBase.buttonplay = vgui.Create("DBetterButton", dermaBase.main)
  -- Music List Server/Client button swap
  dermaBase.buttonswap = vgui.Create("Panel", dermaBase.main)
  dermaBase.labelswap = vgui.Create("DLabel", dermaBase.buttonswap)
  -- Music List
  dermaBase.musicsheet = vgui.Create("DSideMenu", dermaBase.main)
  dermaBase.songlist = vgui.Create("DBetterListView", dermaBase.musicsheet)
  -- Music Dir
  dermaBase.audiodirsheet = vgui.Create("Panel", dermaBase.musicsheet_colsheet)
  dermaBase.foldersearch = vgui.Create("DDoubleListView", dermaBase.audiodirsheet)
  dermaBase.foldersearch:SetInfoColor(Color(255, 255, 255))
  -- Music Dir refresh button
  dermaBase.labelrefresh = vgui.Create("Panel", dermaBase.audiodirsheet)
  dermaBase.buttonrefresh = vgui.Create("DButton", dermaBase.audiodirsheet)
  -- Settings
  dermaBase.settingsheet = vgui.Create("Panel", dermaBase.musicsheet)
  dermaBase.settingPage = vgui.Create("DOptions", dermaBase.settingsheet)
  dermaBase.settingPage:SetDefaultFont(defaultFont)
  -- Settings options
  dermaBase.settingPage:Category("Server Side")
  dermaBase.cbadminaccess = dermaBase.settingPage:CheckBox("Only admins can play songs on the server", true)
  dermaBase.cbadmindir = dermaBase.settingPage:CheckBox("Only admins can select music dirs", true)
  dermaBase.settingPage:Category("Client Side")
  dermaBase.contextbutton = dermaBase.settingPage:CheckBox("Enable context menu button", false)
  dermaBase.hotkey = dermaBase.settingPage:CheckBox("Disable F3 hotkey", false)
  dermaBase.darkmode = dermaBase.settingPage:CheckBox("Enable dark mode", false)
  -- Panel
  bottom_p:DockMargin(0, 0, 25, 0)
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
  dermaBase.slidervol:SetFont(defaultFont)
  dermaBase.songlist:SetFont(defaultFont)
  dermaBase.sliderseek:SetTextFont(defaultFont)
  dermaBase.contextmedia:SetFont(defaultFont)
  dermaBase.contextmedia:SetTextColor(Color(0, 0, 0))
  dermaBase.labelswap:SetTextColor(Color(230, 230, 230))
  dermaBase.buttonstop:SetFont(defaultFont)
  dermaBase.buttonpause:SetFont(defaultFont)
  dermaBase.buttonplay:SetFont(defaultFont)
  dermaBase.buttonrefresh:SetFont(defaultFont)
  dermaBase.labelswap:SetFont(defaultFont)
  -- Convars for checkboxes
  dermaBase.slidervol:SetConVar("gmpl_vol")
  dermaBase.cbadminaccess:SetConVar("gmpl_svadminplay", "1", "[gMusic Player] Allows only admins to play songs on the server")
  dermaBase.cbadmindir:SetConVar("gmpl_svadmindir", "0", "[gMusic Player] Only admins can select Music Dirs")
  dermaBase.contextbutton:SetConVar("gmpl_cmenu", "0", "[gMusic Player] Disable/Enable the context menu button")
  dermaBase.hotkey:SetConVar("gmpl_nohotkey", "0", "[gMusic Player] Disable/Enable the F3 hotkey")
  dermaBase.darkmode:SetConVar("gmpl_dark", "1", "[gMusic Player] Toggle dark mode theme")

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
  dermaBase.set_server_TSS = function(bool)
    -- switch to Client/Server
    dermaBase.main:SetTitleServerState(bool)
    dermaBase.contextmedia:SetTSS(bool)
  end

  dermaBase.painter.OnUpdateUI = function(self)
    dermaBase.songlist:SetDefaultTextColor(self.colors.text)
  end

  dermaBase.painter:theme_dark(dermaBase.darkmode:GetChecked())

  dermaBase.main.OnUpdateUI = function(panel)
    -- if sidemenu or music dir is visible
    if panel:IsVisible() and panel:IsServerMode() then
      if affect_ui_buttons ~= LocalPlayer():IsAdmin() then
        affect_ui_buttons = LocalPlayer():IsAdmin()
        dermaBase.interface:toggle_bottom_ui()
      end
    end

    if dermaBase.musicsheet:IsVisible() or dermaBase.audiodirsheet:IsVisible() then
      local musicsheet_sidebar_items = dermaBase.musicsheet:GetSideBarItems()

      if dermaBase.cbadmindir:GetChecked() then
        if dermaBase.audiodirsheet:IsVisible() and not LocalPlayer():IsAdmin() then
          dermaBase.musicsheet:SetActiveButton(musicsheet_sidebar_items[1].Button)
        end

        if LocalPlayer():IsAdmin() then
          if not musicsheet_sidebar_items[2].Button:IsVisible() then
            musicsheet_sidebar_items[2].Button:SetVisible(true)
            dermaBase.musicsheet.sidebar:InvalidateChildren()
          end
        elseif musicsheet_sidebar_items[2].Button:IsVisible() then
          musicsheet_sidebar_items[2].Button:SetVisible(false)
          dermaBase.musicsheet.sidebar:InvalidateChildren()
        end
      else
        if musicsheet_sidebar_items[2].Button:GetDisabled() then
          musicsheet_sidebar_items[2].Button:SetEnabled(true)
        end

        if not musicsheet_sidebar_items[2].Button:IsVisible() then
          musicsheet_sidebar_items[2].Button:SetVisible(true)
          dermaBase.musicsheet.sidebar:InvalidateChildren()
        end
      end
    end
  end

  dermaBase.main.OnSettingsClick = function(panel)
    dermaBase.musicsheet:ToggleSideBar()
  end

  dermaBase.main.OnClientMode = function(self)
    dermaBase.interface:toggle_normal_ui()
    local is_playing = dermaBase.mediaplayer:cl_mute(false)
    dermaBase.mediaplayer:sv_mute(true)
    dermaBase.mediaplayer:update_ui_highlight()
    dermaBase.sliderseek:ShowSeekBarHandle(is_playing)
    dermaBase.set_server_TSS(false)
  end

  dermaBase.main.OnServerMode = function(self)
    dermaBase.interface:toggle_bottom_ui()
    dermaBase.mediaplayer:cl_mute(true)
    local is_playing = dermaBase.mediaplayer:sv_mute(false)
    dermaBase.mediaplayer:update_ui_highlight()
    dermaBase.sliderseek:ShowSeekBarHandle(is_playing)
    dermaBase.set_server_TSS(true)
  end

  dermaBase.sliderseek.seek_val.Slider.OnMousePressed = function(self, mcode)
    if dermaBase.main:IsServerMode() and dermaBase.cbadminaccess:GetChecked() and not LocalPlayer():IsAdmin() then return end
    dermaBase.sliderseek.seek_val:OnMousePressed(mcode)
  end

  dermaBase.sliderseek.seek_val.Slider.OnMouseReleased = function(self, mcode)
    if dermaBase.main:IsServerMode() and dermaBase.cbadminaccess:GetChecked() and not LocalPlayer():IsAdmin() then return end
    dermaBase.sliderseek.seek_val:OnMouseReleased(mcode)
  end

  dermaBase.sliderseek.seek_val.can_reset_slider = function(self)
    if dermaBase.main:IsServerMode() and dermaBase.cbadminaccess:GetChecked() and not LocalPlayer():IsAdmin() then return false end

    return true
  end

  dermaBase.sliderseek.seek_val.OnEndReached = function(self, is_server_mode)
    if is_server_mode == nil then
      is_server_mode = dermaBase.main:IsServerMode()
    end

    if is_server_mode then
      print("End reached SV")
      net.Start("sv_stop_live")
      net.SendToServer()

      return
    end

    print("End reached not server", is_server_mode, dermaBase.main:IsServerMode())
    dermaBase.buttonstop:DoClick()
  end

  dermaBase.SliderEnded = function(self, is_server_mode)
    local channel = self.mediaplayer.cl_PlayingSong

    if is_server_mode then
      channel = self.mediaplayer.sv_PlayingSong
    end

    local state = channel:state()

    if state == GMOD_CHANNEL_PAUSED then
      dermaBase.sliderseek.seek_val.current_slider_pos = 0
    end

    if dermaBase.sliderseek.seek_val.current_slider_pos == 0 then return false end

    -- prevent stoping at consecutive play and pause changes
    if dermaBase.mediaplayer:has_reached_seek_end(channel) and (not channel:is_paused() and state ~= GMOD_CHANNEL_PLAYING) then
      count_equals = count_equals + 1
    end

    if count_equals == 3 then
      count_equals = 0

      return true
    end

    return false
  end

  dermaBase.MonitorSeekEnd = function(self, is_server_mode)
    -- if self.current_slider_pos == 0 then return end
    -- if self:HasSliderEnded() then
    if self:SliderEnded(is_server_mode) then
      self.sliderseek.seek_val:OnEndReached(is_server_mode)
    end
  end

  -- Used for stopping the realtime audio after checking
  -- the same slider pos 3 times
  -- dermaBase.sliderseek.seek_val.HasSliderEnded = function(panel)
  --   local state = dermaBase.mediaplayer.sv_PlayingSong:state()
  --   if state == GMOD_CHANNEL_PAUSED then
  --     panel.current_slider_pos = 0
  --   end
  --   if panel.current_slider_pos == 0 then
  --     return false
  --   end
  --   -- prevent stopping at consecutive play and pause changes
  --   if dermaBase.mediaplayer:has_reached_seek_end()
  --     and (not dermaBase.mediaplayer:is_paused()
  --     and state ~= GMOD_CHANNEL_PLAYING) then
  --     count_equals = count_equals + 1
  --   end
  --   if count_equals == 3 then
  --     count_equals = 0
  --     return true
  --   end
  --   return false
  -- end
  dermaBase.buttonpause.DoRightClick = function()
    if not dermaBase.mediaplayer:hasValidity() then return end

    if not dermaBase.main:IsServerMode() then
      if not dermaBase.mediaplayer:is_paused() then
        dermaBase.mediaplayer:loop()
      end

      return
    end

    if dermaBase.cbadminaccess:GetChecked() and not LocalPlayer():IsAdmin() then return end
    -- if dermaBase.cbadminaccess:GetChecked() then
    --     if LocalPlayer():IsAdmin() then
    --         dermaBase.mediaplayer:loop()
    --         net.Start("sv_set_loop")
    --         net.WriteBool(dermaBase.mediaplayer:is_looped())
    --         net.SendToServer()
    --     end
    -- else
    -- dermaBase.mediaplayer:loop()
    net.Start("sv_set_loop")
    net.WriteBool(not dermaBase.mediaplayer:is_looped())
    net.SendToServer()
  end

  -- end
  dermaBase.buttonstop.DoClick = function()
    if dermaBase.main:IsServerMode() then
      net.Start("sv_stop_live")
      net.SendToServer()

      return
    end

    print("entering cl stop")

    if dermaBase.mediaplayer:is_looped() then
      -- print("cl stop while looped", dermaBase.sliderseek:GetMin())
      dermaBase.sliderseek:AllowSeek(true)
      dermaBase.sliderseek:SetTime(dermaBase.sliderseek:GetMin(), dermaBase.sliderseek:GetMin())
    elseif dermaBase.mediaplayer:is_autoplaying() then
      -- print("cl dont stop but play next", dermaBase.sliderseek:GetMin())
      dermaBase.mediaplayer:play_next()
    elseif not dermaBase.mediaplayer:isMissing() then
      -- print("cl do stop", dermaBase.sliderseek:GetMin())
      dermaBase.mediaplayer:cl_stop()
    end
  end

  -- print("Pause seek end, in paused")
  -- timer.Pause("gmpl_seek_end")
  -- Clicks M1
  dermaBase.contextmedia.DoClick = function()
    net.Start("sv_gmpl_show")
    net.SendToServer()
  end

  -- Clicks M2
  dermaBase.contextmedia.DoRightClick = function()
    dermaBase.buttonpause.DoClick()
  end

  -- Clicks M3
  dermaBase.contextmedia.DoMiddleClick = function()
    dermaBase.buttonpause.DoRightClick()
  end

  -- Clicks M4
  dermaBase.contextmedia.DoM4Click = function()
    dermaBase.buttonpause.DoRightClick()
  end

  dermaBase.contextmedia.OnScreenSizeChanged = function(old_width, old_height)
    dermaBase.contextmedia:SetPos(ScrW() - contextMargin, 0)
    dermaBase.contextmedia:SetSize(ScrW() - (ScrW() - contextMargin), 30)
  end

  dermaBase.cbadminaccess.AfterChange = function(panel, val)
    local bVal = tobool(val)
    net.Start("sv_refresh_access")
    net.WriteBool(bVal)
    net.SendToServer()
  end

  dermaBase.cbadmindir.AfterChange = function(panel, val)
    local bVal = tobool(val)
    net.Start("toServerRefreshAccessDir")
    net.WriteBool(bVal)
    net.SendToServer()
  end

  dermaBase.contextbutton.AfterChange = function(panel, val)
    if not IsValid(contextMenu) then return end
    local bVal = tobool(val)
    dermaBase.contextmedia:SetVisible(bVal)
  end

  dermaBase.darkmode.AfterChange = function(self, val)
    dermaBase.painter:theme_dark(tobool(val))
    dermaBase.painter:update_colors()

    self.OnCvarWrong = function(panel, old, new)
      MsgC(Color(255, 90, 90), "Only 0 - 1 value is allowed. Keeping value " .. old .. " \n")
    end
  end

  dermaBase.painter.update_colors = function(self)
    self:paintNone({dermaBase.buttonrefresh, dermaBase.buttonstop, dermaBase.buttonpause, dermaBase.buttonplay, dermaBase.musicsheet.sidebar, dermaBase.foldersearch, dermaBase.musicsheet, dermaBase.foldersearch.btnRebuildMid, dermaBase.foldersearch.btnAddMid, dermaBase.foldersearch.btnRemMid})

    local white = Color(255, 255, 255)
    local hoverWhite = Color(230, 230, 230, 50)
    dermaBase.buttonrefresh:SetTextColor(white)
    dermaBase.buttonstop:SetTextColor(white)
    dermaBase.buttonpause:SetTextColor(white)
    dermaBase.buttonplay:SetTextColor(white)
    self:paintSlider(dermaBase.sliderseek:GetSeekLayer())
    self:paintSlider(dermaBase.slidervol)
    self:paintBG(dermaBase.main)
    self:paintBG(dermaBase.musicsheet.sidebar, Color(120, 120, 120))

    for k, sideItem in pairs(dermaBase.musicsheet:GetSideBarItems()) do
      if sideItem.Button then
        self:paintBG(sideItem.Button, Color(255, 255, 255))
        self:paintHoverBG(sideItem.Button, Color(0, 0, 0, 50))
        sideItem.Button:SetTextColor(Color(0, 0, 0))
      end
    end

    self:paintHoverBG(dermaBase.buttonrefresh, hoverWhite)
    self:paintHoverBG(dermaBase.buttonstop, hoverWhite)
    self:paintHoverBG(dermaBase.buttonpause, hoverWhite)
    self:paintHoverBG(dermaBase.buttonplay, hoverWhite)
    self:paintList(dermaBase.songlist)
    self:paintHoverList(dermaBase.songlist)
    self:paintScroll(dermaBase.songlist, Color(120, 120, 120))
    self:paintText(dermaBase.songlist)

    if dermaBase.mediaplayer:hasValidity() and dermaBase.mediaplayer:is_looped() then
      dermaBase.mediaplayer:uiLoop()
    end

    self:paintText(dermaBase.foldersearch)
    self:paintList(dermaBase.foldersearch)
    self:paintColumn(dermaBase.foldersearch)
    self:paintHoverColumn(dermaBase.foldersearch, hoverWhite)
    self:paintScroll(dermaBase.foldersearch, Color(120, 120, 120))
    self:paintHoverBG(dermaBase.foldersearch.btnRebuildMid, hoverWhite)
    self:paintHoverBG(dermaBase.foldersearch.btnAddMid, hoverWhite)
    self:paintHoverBG(dermaBase.foldersearch.btnRemMid, hoverWhite)
    self:paintThemeBG(dermaBase.settingsheet)
    self:paintScroll(dermaBase.settingPage)
    self:paintText(dermaBase.settingPage)

    for _, category in pairs(dermaBase.settingPage.Categories) do
      self:paintBG(category)
      category:SetTextColor(white)
    end
  end

  dermaBase.foldersearch.OnAdd = function(panel, is_selected)
    if dermaBase.cbadmindir:GetChecked() and not LocalPlayer():IsAdmin() then return end
    panel:selectFirstLine()
    if not is_selected then return end
    dermaBase.buttonrefresh:SetVisible(true)
    dermaBase.song_data:populate_left_list()
    dermaBase.song_data:populate_right_list()
  end

  dermaBase.foldersearch.OnRemove = function(panel, is_selected)
    if dermaBase.cbadmindir:GetChecked() and not LocalPlayer():IsAdmin() then return end
    panel:selectFirstLine()
    if not is_selected then return end
    dermaBase.buttonrefresh:SetVisible(true)
    dermaBase.song_data:populate_left_list()
    dermaBase.song_data:populate_right_list()
  end

  dermaBase.buttonrefresh.DoClick = function(self)
    if dermaBase.cbadmindir:GetChecked() and not LocalPlayer():IsAdmin() then return end
    print("\nBUTTON DO CLICK")
    dermaBase.song_data:refresh_song_list()
    dermaBase.song_data:populate_song_page()
    dermaBase.song_data:save_on_disk()
  end

  dermaBase.foldersearch.OnRebuild = function(self)
    dermaBase.song_data:rebuild_song_page()
    self:selectFirstLine()
  end

  dermaBase.foldersearch.UpdateMusicDir = function(panel, inactive_dirs, active_dirs)
    dermaBase.song_data:populate_left_list(inactive_dirs)
    dermaBase.song_data:populate_right_list(active_dirs)
    panel:OnRebuild()
    dermaBase.song_data:populate_song_page()
  end

  --[[
        Updates the settings page checkboxes
    --]]
  dermaBase.InvalidateUI = function()
    dermaBase.settingPage:InvalidateItems()
  end

  dermaBase.create = function(context_menu)
    dermaBase.InvalidateUI()
    dermaBase.foldersearch:OnRebuild()
    dermaBase.main:SetFont(defaultFont)
    dermaBase.musicsheet:AddSheet("Song List", dermaBase.songlist, "icon16/control_play_blue.png")
    dermaBase.musicsheet:AddSheet(" Music Dirs", dermaBase.audiodirsheet, "icon16/folder_add.png", true)
    dermaBase.musicsheet:AddSheet("Settings", dermaBase.settingsheet, "icon16/application_view_list.png")

    dermaBase.musicsheet:GetSideBarItems()[2].Button.PaintOver = function(self, w, h)
      if self:GetDisabled() then
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(0, 0, w, h)
      end
    end

    local tallOptionsPage = 0

    for k, v in pairs(dermaBase.settingPage.Items) do
      tallOptionsPage = tallOptionsPage + v:GetTall()
    end

    dermaBase.settingPage:SetSize(200, tallOptionsPage + 40)
    dermaBase.interface.build()
    dermaBase.interface.init_context_view(context_menu)
  end

  return dermaBase
end

return init