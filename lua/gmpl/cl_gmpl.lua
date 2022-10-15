-- local mediaplayer = nil
local shared_settings = nil
-- local dermaBase = {}
local view_context_menu = nil
local contextMenuMargin = ScrW() / 5

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

--[[-------------------------------------------------------------------------
Runs if server not just Created
---------------------------------------------------------------------------]]
--
-- net.Receive( "sendServerSettings", function()
-- 	local serverSettings = net.ReadTable()
-- 	dermaBase.cbadminaccess:SetChecked(serverSettings.admin_server_access)
-- 	dermaBase.cbadmindir:SetChecked(serverSettings.admin_dir_access)
-- end )
--[[-------------------------------------------------------------------------
First Run on server start
---------------------------------------------------------------------------]]
--
net.Receive("cl_ask_server_settings", function()
  local server_access = net.ReadBool()
  local dir_access = net.ReadBool()
  print("SERVER ACCESS IS", server_access)
  print("DIR ACCESS IS", dir_access)
end)


local function initialize_music_player()
  if not gmusic then return end

  include("gmpl/cl_cvars.lua")
  gmusic.get()
end

net.Receive("cl_gmpl_create", function()
  initialize_music_player()
end)

-- timer.Pause("gmpl_seek_end")
-- dermaBase.mediaplayer
-- print("\nshared settings cl_gmpl:", shared_settings)
-- PrintTable(shared_settings)
net.Receive("cl_gmpl_show", function()
  local gmusic_ui_lowlevel = gmusic.interface()
  local gmusic_ui = gmusic.derma()

  local live_host = net.ReadType()
  gmusic_ui_lowlevel.set_song_host(live_host)
  gmusic_ui.InvalidateUI()
  gmusic_ui_lowlevel.show()
end)

concommand.Add("gmplshow", function()
  local gmusic_ui_lowlevel = gmusic.interface()
  local gmusic_ui = gmusic.derma()

  gmusic_ui.InvalidateUI()
  gmusic_ui_lowlevel.show()
end)



-- end
-- hook.Add("OnScreenSizeChanged", "warn_users", function(old_width, old_height)
--     // Keep this warning to notice users of this bug
--      local dialog_warning = vgui.Create("DFrame")
--      dialog_warning:SetSize(350, 200)
--      dialog_warning:SetDeleteOnClose(true)
--      dialog_warning:ShowCloseButton(false)
--      dialog_warning:Center()
--      dialog_warning:SetTitle("Warning resolution changed")
--      dialog_warning:MoveToFront()
--      dialog_warning.Label = vgui.Create("RichText", dialog_warning)
--      dialog_warning.Label:SetVerticalScrollbarEnabled(false)
--      dialog_warning.Label:Dock(FILL)
--      dialog_warning.Label:InsertColorChange(255, 255, 255, 255)
--      dialog_warning.Label:AppendText(
--          "Resolution Change Detectednot \n\nBecause of this, a small panel will appear in the left corner due to a bug in Gmod. Please reconnect to the server or live with it :)")
--      dialog_warning.Label.Paint = function(panel)
--          panel:SetFontInternal( "GModNotify" )
--          panel.Paint = nil
--      end
--      local bottom = vgui.Create("Panel", dialog_warning)
--      bottom:Dock(BOTTOM)
--      bottom.btn = vgui.Create("DButton", bottom)
--      bottom.btn:Dock(FILL)
--      bottom.btn:DockMargin(4, 0, 0, 0)
--      bottom.btn:SetText("I Understand")
--      bottom.btn:SetFont("GModNotify")
--      bottom.btn.Paint = function(panel, w, h)
--          surface.SetDrawColor(Color(255, 255, 255))
--          surface.DrawRect(0, 0, w, h)
--      end
--      bottom.btn.DoClick = function()
--          dialog_warning:Close()
--      end
-- end)