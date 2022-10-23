-- if the_player.IsValid == nil then
--   the_player.is_admin = _mock_is_admin
--   -- used for net.SendServer
--   the_player.is_net_admin = _all_players_are_admin
--   for k, v in pairs(_G.Player) do
--     the_player[k] = v
--   end
-- end

local cvarMediaVolume = CreateClientConVar("gmpl_vol", "100", true, false, "[gMusic Player] Sets the Volume of music player")
local interface = {}
local dermaBase = {}
--[[
    Name of host that plays on server
--]]
local server_song_host = ""
--[[
    Parent anchors used for the main panel
--]]
local view_ingame = nil
local view_context_menu = nil
--[[
    Used to track if the player is in context menu
    note: IsWorldClicking() NOT reliable
--]]
local is_context_open = false
--[[
    Used to store the active anchor panel when the window is visible
--]]
local anchor_parent = nil

--[[
  Constants
]]
local defaultFont = "arialDefault"

local function update_server_channel()
  -- TODO this is a duplicate in meth_base too
  -- - i gotta fix this somehow
  local server_channel_attributes = dermaBase.mediaplayer.sv_PlayingSong.attrs
  net.Start("sv_update_channel_data")
  net.WriteTable(server_channel_attributes)
  net.SendToServer()
end

local function player_requires_admin_but_not_admin()
  -- TODO this is duplicate in meth_base too so maybe make it a `util` function
  -- - maybe in the same settings table
  return dermaBase.cbadminaccess:GetChecked() and not LocalPlayer():IsAdmin()
end

local function init(baseMenu)
  dermaBase = baseMenu
  return interface
end

local function get_contextmenu_panel()
  if not IsValid(g_ContextMenu) then return {} end

  local is_panel_context_menu =
    g_ContextMenu:GetClassName() == "LuaEditablePanel"

    if is_panel_context_menu then return g_ContextMenu end
    return {}
end

--[[
    Used to parent the music player to context menu or ingame
--]]
local function prepare_parent_panels(context_menu)
  view_ingame = dermaBase.main:GetParent()
  view_context_menu = get_contextmenu_panel()
end

local function build_button_contextmedia()
  if not dermaBase.contextmedia then return end

  if not view_context_menu then
    dermaBase.contextbutton:SetInactive(true)
    dermaBase.contextmedia:Remove()
    dermaBase.contextmedia = nil
    return
  end

  local full_width = ScrW()
  local width = full_width / 5

  dermaBase.contextmedia:SetParent(view_context_menu)
  dermaBase.contextmedia:Init()
  dermaBase.contextmedia:SetText(false)
  dermaBase.contextmedia:SetVisible(true)
  dermaBase.contextmedia:SetPos(full_width - width, 0)
  dermaBase.contextmedia:SetSize(full_width - (full_width - width), 30)
  dermaBase.contextmedia:SetFont(defaultFont)
  dermaBase.contextmedia:SetTextColor(Color(0, 0, 0))

  dermaBase.contextmedia.OnThink = function(panel)
    if dermaBase.mediaplayer:hasValidity() and dermaBase.mediaplayer:hasState() == GMOD_CHANNEL_PLAYING then
      panel:SetSeekTime(dermaBase.sliderseek:GetTime())
    elseif panel:IsMissing() then
      panel:SetSeekEnabled(false)
    end
  end

  -- Clicks M1
  dermaBase.contextmedia.DoClick = function()
    interface.show()
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
end


local function create_mediaplayer_ui_logic()
  prepare_parent_panels()

  dermaBase.main:SetPos(16, 36)
  dermaBase.main:SetTitle(" gMusic Player")
  dermaBase.main:SetDraggable(true)
  dermaBase.main:SetSizable(true)
  local mainX, mainY = dermaBase.main:GetSize()
  dermaBase.musicsheet:SetPos(0, 20)
  dermaBase.musicsheet.sidebar:Dock(RIGHT)
  dermaBase.musicsheet.sidebar:SetVisible(false)
  dermaBase.settingPage:Dock(FILL)
  dermaBase.settingPage:DockPadding(0, 0, 0, 10)
  dermaBase.audiodirsheet:Dock(FILL)
  dermaBase.audiodirsheet:DockMargin(0, 0, 0, 0)
  dermaBase.songlist:AddColumn("Song")
  dermaBase.labelrefresh:Dock(TOP)
  dermaBase.labelrefresh:SetHeight(44)

  dermaBase.labelrefresh.Paint = function(self, w, h)
    draw.DrawText("Select the folders from ROOT that are going to be added. ROOT: garrysmod\\sound\\ \nIt will also add the content of the first folders found inside them.", "default", w * 0.5, h * 0.10, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
    draw.DrawText("Right Click to deselect | (Ctrl or Shift)+Click for multiple selections", "default", w * 0.5, h * 0.66, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
  end

  dermaBase.buttonrefresh:Dock(BOTTOM)
  dermaBase.buttonrefresh:SetText("Press to refresh the Song List")
  dermaBase.buttonrefresh:SetSize(mainX / 3, 30)
  dermaBase.buttonrefresh:SetVisible(false)
  dermaBase.buttonswap:SetSize(mainX / 3, 30)
  dermaBase.buttonswap:SetPos(0, dermaBase.musicsheet:GetTall() + 20)
  dermaBase.labelswap:Dock(FILL)
  dermaBase.labelswap:DockMargin(6, 1, 0, 0)

  if #server_song_host ~= 0 then
    dermaBase.labelswap:SetText("Host: " .. server_song_host)
  else
    dermaBase.labelswap:SetText("No song currently playing")
  end

  local buttonTall = 30
  dermaBase.buttonstop:SetText("Stop")
  dermaBase.buttonstop:SetSize(mainX / 3, buttonTall)
  dermaBase.buttonstop:SetPos(0, dermaBase.musicsheet:GetTall() + 20)
  dermaBase.buttonpause:SetText("Pause / Loop")
  dermaBase.buttonpause:SetSize(dermaBase.buttonstop:GetWide(), buttonTall)
  dermaBase.buttonpause:SetPos(dermaBase.buttonstop:GetWide(), dermaBase.musicsheet:GetTall() + 20)
  dermaBase.buttonplay:SetText("Play / AutoPlay")
  dermaBase.buttonplay:SetSize(mainX - (dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide()), buttonTall)
  dermaBase.buttonplay:SetPos(dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide(), dermaBase.musicsheet:GetTall() + 20)
  dermaBase.sliderseek:SetSize(mainX - 150, buttonTall)
  dermaBase.sliderseek:AlignBottom()
  dermaBase.sliderseek:GetSeekLayer().Slider.Knob:SetHeight(dermaBase.sliderseek:GetTall())
  dermaBase.sliderseek:GetSeekLayer().Slider.Knob:SetWide(5)
  dermaBase.sliderseek:ShowSeekTime()
  dermaBase.sliderseek:ShowSeekLength()
  dermaBase.slidervol:SetVolume(cvarMediaVolume:GetFloat())

  dermaBase.musicsheet:GetSideBarItems()[2].Button.DoClick = function(self)
    dermaBase.foldersearch:selectFirstLine()

    if not dermaBase.audiodirsheet:IsVisible() then
      dermaBase.musicsheet:SetActiveButton(self)
    end
  end

  dermaBase.buttonpause.DoClick = function()
    -- if dermaBase.cbadminaccess:GetChecked() then
    if not dermaBase.mediaplayer:hasValidity() then return end

    if not dermaBase.main:IsServerMode() then
      -- dermaBase.set_server_TSS(false)
      dermaBase.mediaplayer:cl_pause()

      return
    end

    -- dermaBase.set_server_TSS(true)
    -- local playingFromOtherMode = dermaBase.main:playingFromAnotherMode()
    if player_requires_admin_but_not_admin() then
      -- block future live plays
      dermaBase.mediaplayer:pause_live()

      if not dermaBase.mediaplayer:is_paused_live() then
        net.Start("sv_play_live_seek_from_host")
        net.SendToServer()
      end

      return
    end

    if dermaBase.main:IsServerMode() then
      dermaBase.mediaplayer:sv_pause()
    end

    update_server_channel()
    net.Start("sv_pause_live")
    -- net.WriteBool(not dermaBase.mediaplayer:sv_is_pause())
    -- net.WriteDouble(dermaBase.mediaplayer:get_time())
    net.SendToServer()
  end

  dermaBase.buttonplay.DoClick = function(self, song_path, line_index)
    if dermaBase.songlist:IsEmpty() then
      return
    end
    local current_line = dermaBase.mediaplayer:get_channel():get_song_index()

    if not isnumber(line_index) then
      if current_line ~= 0 then
        line_index = current_line
      else
        line_index = 1
      end
    elseif line_index == 0 then
      line_index = 1
    end


    if not isstring(song_path) then
      song_path, line_index = dermaBase.song_data:get_song(line_index)
    end

    if not dermaBase.main:IsServerMode() then
      dermaBase.set_server_TSS(false)

      local is_same_line = line_index == current_line
      local is_valid_and_paused = dermaBase.mediaplayer:hasValidity() and dermaBase.mediaplayer:is_paused()

      if is_valid_and_paused and is_same_line then
        dermaBase.mediaplayer:resume()
      else
        local is_autoplaying = dermaBase.mediaplayer:is_autoplaying()
        dermaBase.mediaplayer:play(song_path, line_index, is_autoplaying)
      end

      dermaBase.songlist:SetSelectedLine(line_index)

      return
    end

    dermaBase.set_server_TSS(true)

    if player_requires_admin_but_not_admin() then
      net.Start("sv_play_live_seek_from_host")
      net.SendToServer()

      return
    end

    -- if dermaBase.main:IsServerMode() then
    --   local is_autoplaying = dermaBase.mediaplayer:is_autoplaying()
    --   dermaBase.mediaplayer:play(song_path, line_index, is_autoplaying)
    -- end
    update_server_channel()
    net.Start("sv_play_live")
    net.WriteString(song_path)
    net.WriteUInt(line_index, 16)
    net.SendToServer()
  end

  dermaBase.buttonplay.DoRightClick = function(songFile)
    -- if dermaBase.songlist:IsEmpty() then
    --     return
    -- elseif not isnumber(song_index) then
    --   song_index = 1;
    --     dermaBase.songlist:SetSelectedLine(song_index)
    -- end
    -- if not isstring(songFile) then
    --     songFile = dermaBase.song_data:get_song(song_index)
    -- end
    if not dermaBase.mediaplayer:hasValidity() then return end

    if not dermaBase.main:IsServerMode() then
      -- dermaBase.set_server_TSS(false)
      -- if dermaBase.mediaplayer:is_stopped() then
      --     dermaBase.mediaplayer:play(songFile, song_index, true)
      -- else
      -- if dermaBase.mediaplayer:hasState() == GMOD_CHANNEL_PAUSED then
      --     dermaBase.mediaplayer:resume(songFile)
      -- else
      dermaBase.mediaplayer:cl_autoplay()
      -- end
      -- end

      return
    end

    if player_requires_admin_but_not_admin() then return end

    if dermaBase.mediaplayer:hasState() == GMOD_CHANNEL_PAUSED then
      dermaBase.buttonpause:DoClick()

      return
    end

    if dermaBase.main:IsServerMode() then
      dermaBase.mediaplayer:sv_autoplay()
    end

    -- dermaBase.mediaplayer:autoplay()
    -- print("[autplay] is autoplay:", not dermaBase.mediaplayer:sv_is_autoplay())
    update_server_channel()
    net.Start("sv_set_autoplay")
    net.SendToServer()
  end

  dermaBase.slidervol.OnVolumeChanged = function(panel, value)
    -- print("Volume, OnValueChanged:", value)
    if dermaBase.mediaplayer:hasValidity() then
      dermaBase.mediaplayer:volume(value / 100)
    end
  end

  -- dermaBase.slidervol.OnVolumeClick = function(panel, lastVolume)
  -- print("OnVolumeClick:", lastVolume)
  -- if dermaBase.mediaplayer:hasValidity() then
  -- 	if panel:GetMute() then
  -- 		dermaBase.mediaplayer:volume(0)
  -- 	else
  -- 		dermaBase.mediaplayer:volume(lastVolume)
  -- 	end
  -- end
  -- end
  dermaBase.songlist.DoDoubleClick = function(panel, lineIndex, line)
    songFile, index = dermaBase.song_data:get_song(lineIndex)
    dermaBase.buttonplay:DoClick(songFile, index)
  end

  -- dermaBase.sliderseek.SeekClick.OnValueChanged = function(seekClickLayer, seekSecs)
  dermaBase.sliderseek.seek_val.OnValueChanged = function(panel, seekSecs)
    if not dermaBase.mediaplayer:hasValidity() then return end

    if not dermaBase.main:IsServerMode() then
      -- dermaBase.set_server_TSS(false)
      -- if dermaBase.mediaplayer:hasState() ~= GMOD_CHANNEL_PAUSED then
      dermaBase.mediaplayer:seek(seekSecs)
      -- end

      return
    end

    if player_requires_admin_but_not_admin() then return end

    if dermaBase.mediaplayer:hasState() == GMOD_CHANNEL_PAUSED then
      dermaBase.mediaplayer:seek(seekSecs)
    end

    net.Start("sv_set_seek")
    net.WriteDouble(seekSecs)
    net.SendToServer()
  end

  dermaBase.main.OnLayoutChange = function(panel)
    local songHeight = dermaBase.musicsheet:GetTall()
    local mainTall = panel:GetTall()
    dermaBase.musicsheet:SetSize(panel:GetWide(), mainTall - 80)
    dermaBase.songlist:RefreshLayout(panel:GetWide(), mainTall - 80)

    if dermaBase.musicsheet.sidebar:IsVisible() then
      dermaBase.settingPage:RefreshLayout(panel:GetWide() - 100, mainTall - 80)
    else
      dermaBase.settingPage:RefreshLayout(panel:GetWide(), mainTall - 80)
    end

    dermaBase.buttonstop:SetSize(panel:GetWide() / 3, 30)
    dermaBase.buttonstop:SetPos(0, songHeight + 20)
    dermaBase.buttonswap:SetSize(panel:GetWide() / 3, 30)
    dermaBase.buttonswap:SetPos(0, songHeight + 20)
    dermaBase.buttonpause:SetSize(dermaBase.buttonstop:GetWide(), 30)
    dermaBase.buttonpause:SetPos(dermaBase.buttonstop:GetWide(), songHeight + 20)
    dermaBase.buttonplay:SetSize(panel:GetWide() - (dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide()), 30)
    dermaBase.buttonplay:SetPos(dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide(), songHeight + 20)
    dermaBase.sliderseek:SetSize(panel:GetWide() - 150, 30)
    dermaBase.slidervol:SetSize(panel:GetWide() - dermaBase.sliderseek:GetWide() - 5, 30)
  end

  dermaBase.main.OnResizing = function()
    dermaBase.musicsheet:TogglePanelsVisible(false)
  end

  dermaBase.main.AfterResizing = function()
    dermaBase.musicsheet:TogglePanelsVisible()
  end

  dermaBase.musicsheet.OnSideBarToggle = function(sidePanel, wide)
    dermaBase.settingPage:RefreshCategoryLayout(dermaBase.main:GetWide() - wide)
  end

  build_button_contextmedia()

end

local function show()
  dermaBase.musicsheet:SetVisible(true)

  if dermaBase.main:IsVisible() then
    RememberCursorPosition()
    gui.EnableScreenClicker(false)

    if is_context_open then
      if anchor_parent == view_context_menu then
        dermaBase.main:SetVisible(false)
      else
        -- move from outside to context area
        anchor_parent = view_context_menu
      end
    else
      if anchor_parent == view_ingame then
        dermaBase.main:SetVisible(false)
      else
        -- move outside of context menu area
        gui.EnableScreenClicker(true)
        anchor_parent = view_ingame
      end
    end

    if not dermaBase.mediaplayer:sv_is_autoplay() and not dermaBase.mediaplayer:cl_is_autoplay() then

      -- TODO try to move this logic in another place
      --  - this seems to pause disable the constant seeking when autoplay is
      --    off
      timer.Pause("gmpl_realtime_seek")
    end
  else
    if is_context_open then
      -- open in context area
      RememberCursorPosition()
      gui.EnableScreenClicker(false)
      anchor_parent = view_context_menu
    else
      -- open outside
      gui.EnableScreenClicker(true)
      anchor_parent = view_ingame
    end

    dermaBase.main:SetVisible(true)
    timer.UnPause("gmpl_realtime_seek")
  end

  RestoreCursorPosition()
  if IsValid(anchor_parent) then
    dermaBase.main:SetParent(anchor_parent)
  end
end

local function set_volume(var)
  cvarMediaVolume:SetString(var)
  dermaBase.slidervol:SetVolume(var)
end

local function set_song_host(ply)
  if isentity(ply) and ply:IsPlayer() then
    server_song_host = ply:Nick()
    dermaBase.labelswap:SetText("Host: " .. server_song_host)
  else
    dermaBase.labelswap:SetText("No song currently playing")
  end
end

local function get_song_host()
  return server_song_host
end

local function toggle_normal_ui(self)
  dermaBase.buttonplay:SetText("Play / AutoPlay")
  dermaBase.buttonpause:SetText("Pause / Loop")
  dermaBase.buttonstop:SetVisible(true)
  dermaBase.buttonswap:SetVisible(false)
  local length = dermaBase.mediaplayer:get_length()
  dermaBase.sliderseek:SetSeekText(0)
  dermaBase.sliderseek:SetMax(length)

  if not dermaBase.contextmedia then return end
  dermaBase.contextmedia:SetSeekLength(length)
end

local function toggle_listen_ui(self)
  dermaBase.buttonplay:SetText("Resume Live")
  dermaBase.buttonpause:SetText("Pause")
  dermaBase.buttonstop:SetVisible(false)
  dermaBase.buttonswap:SetVisible(true)
  local length = dermaBase.mediaplayer:get_length()
  dermaBase.sliderseek:SetSeekText(0)
  dermaBase.sliderseek:SetMax(length)

  if not dermaBase.contextmedia then return end
  dermaBase.contextmedia:SetSeekLength(length)
end

local function toggle_bottom_ui(self)
  if player_requires_admin_but_not_admin() then
    toggle_listen_ui(self)
  else
    toggle_normal_ui(self)
  end
end

------------------------------------------------------------------------------
hook.Add('OnContextMenuOpen', 'gmpl_context_open', function()
  is_context_open = true
end)

hook.Add('OnContextMenuClose', 'gmpl_context_close', function()
  is_context_open = false
end)

------------------------------------------------------------------------------
interface.build = create_mediaplayer_ui_logic
interface.set_volume = set_volume
interface.show = show
interface.set_song_host = set_song_host
interface.get_song_host = get_song_host
interface.toggle_normal_ui = toggle_normal_ui
interface.toggle_bottom_ui = toggle_bottom_ui

return init