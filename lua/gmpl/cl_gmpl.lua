local contextMenu
local gmusic = include("includes/modules/setup.lua")

surface.CreateFont("arialDefault", {
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
})

local function showMPlayer(newHost)
  local main_panel = gmusic.derma().main
  local mediaplayer = gmusic.media()
  local ingame_viewport = gmusic.parent()

  if main_panel:IsVisible() then
    if main_panel:HasParents(g_ContextMenu) then
      main_panel:SetParent(ingame_viewport)
      gui.EnableScreenClicker(true)
    else
      RememberCursorPosition() -- still doesn't work
      main_panel:SetVisible(false)
      gui.EnableScreenClicker(false)
    end
  else
    if main_panel:HasParents(g_ContextMenu) then
      main_panel:SetParent(ingame_viewport)
    end

    mediaplayer:SetSongHost(newHost)
    gui.EnableScreenClicker(true)
    main_panel:SetVisible(true)
    mediaplayer:SyncSettings(nil) -- will sync using LocalPlayer()
    RestoreCursorPosition()
  end
end

--[[-------------------------------------------------------------------------
Runs if server not just Created
---------------------------------------------------------------------------]]
--
net.Receive("sendServerSettings", function()
  local serverSettings = net.ReadTable()
  gmusic.derma().cbadminaccess:SetChecked(serverSettings.aa)
  gmusic.derma().cbadmindir:SetChecked(serverSettings.aadir)
end)

--[[-------------------------------------------------------------------------
First Run on server start
---------------------------------------------------------------------------]]
--
net.Receive("createMenu", function()

  net.Start("serverFirstMade")
  net.SendToServer()

  local is_admin_current_player = net.ReadBool()

  if not gmusic then return end
  gmusic.media():SyncSettings(is_admin_current_player)
end)

net.Receive("getSettingsFromFirstAdmin", function()
  local mediaplayer = gmusic.media()

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
end)

--[[-------------------------------------------------------------------------
Client convars
---------------------------------------------------------------------------]]
--
net.Receive("requestHotkeyFromServer", function(length, sender)
  if not gmusic.derma().hotkey:GetChecked() then
    net.Start("toServerHotkey")
    net.SendToServer()
  end
end)

net.Receive("persistClientSettings", function(length, sender)
  if gmusic.derma().contextbutton:GetChecked() then
    gmusic.derma().contextbutton:AfterChange(true)
  end
end)

---------------------------------------------------------------------------]]--
net.Receive("openmenu", function()
  local adminHost = net.ReadType()

  gmusic.media():SetSongHost(newHost)
  showMPlayer(adminHost)
end)

net.Receive("openmenucontext", function()
  local mediaplayer = gmusic.media()
  local main_panel =  gmusic.derma().main

  mediaplayer:SetSongHost(newHost)

  if main_panel:IsVisible() then
    main_panel:SetVisible(false)
    gui.EnableScreenClicker(false)
  else
    main_panel:SetVisible(true)
  end
end)

concommand.Add("gmplshow", function()
  showMPlayer()
end)


cvars.AddChangeCallback("gmpl_vol", function(convar, oldValue, newValue)
  local mediaplayer = gmusic.media()

  if (TypeID(util.StringToType(newValue, "Float")) == TYPE_NUMBER) then
    if TypeID(mediaplayer) ~= TYPE_NIL then
      mediaplayer:SetVolume(newValue)
    end
  elseif (TypeID(util.StringToType(oldValue, "Float")) == TYPE_NUMBER) then
    if TypeID(mediaplayer) ~= TYPE_NIL then
      mediaplayer:SetVolume(oldValue)
      MsgC(Color(255, 0, 0), "Only 0-100 value is allowed. Value not changed ( \"" .. oldValue .. "\" )\n")
    end
  end
end)
