local mediaplayer = nil

local ObjPaint = include("includes/modules/meth_paint.lua")


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
  local foldersearchlistl = dermaBase.foldersearch:getLeftList()
  local foldersearchlistr = dermaBase.foldersearch:getRightList()

  ObjPaint.setDisabled(dermaBase.musicsheet)
  ObjPaint.setDisabled(dermaBase.buttonrefresh)
  ObjPaint.setDisabled(dermaBase.buttonstop)
  ObjPaint.setDisabled(dermaBase.buttonpause)
  ObjPaint.setDisabled(dermaBase.buttonplay)
  ObjPaint.setDisabled(dermaBase.sliderseek)
  ObjPaint.setDisabled(dermaBase.songlist.VBar)
  ObjPaint.setDisabled(foldersearchlistl.VBar)
  ObjPaint.setDisabled(foldersearchlistr.VBar)


  dermaBase.main.Paint = function(self, w, h)
    ObjPaint.setBG(0, 20, w, h, 20, 150, 240, 255)
  end
  dermaBase.musicsheet.Navigation.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 150, 150, 150, 255)
  end
  for k, v in pairs(dermaBase.musicsheet.Items) do
    if (!v.Button) then continue end
      v.Button:SetTextColor(Color(0, 0, 0))
      v.Button:DockMargin( 0, 0, 0, 1 )

      v.Button.Paint = function(self, w, h)
        ObjPaint.setBG(0, 0, w, h, 255, 255, 255, 255)
      end
  end

  ObjPaint.setBGHover(dermaBase.buttonrefresh)
  ObjPaint.setBGHover(dermaBase.buttonstop)
  ObjPaint.setBGHover(dermaBase.buttonpause)
  ObjPaint.setBGHover(dermaBase.buttonplay)


  dermaBase.sliderseek.Slider.Knob.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, dermaBase.sliderseek:GetTall(), 255, 255, 255, 255)
  end


  dermaBase.songlist.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 255, 255, 255, 255)
    surface.SetDrawColor( 20, 150, 240, 255 )
    surface.DrawOutlinedRect( w-1, 0, w, h )
  end
  dermaBase.songlist.VBar.btnGrip.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 20, 150, 240, 255)
  end
  dermaBase.songlist.VBar.btnUp.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 20, 150, 240, 255)
    surface.SetFont("Marlett")
    surface.SetTextPos( 2, 2 )
    surface.SetTextColor( 255, 255, 255, 255 )
    surface.DrawText("5")
  end
  dermaBase.songlist.VBar.btnDown.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 20, 150, 240, 255)
    surface.SetFont("Marlett")
    surface.SetTextPos( 2, 1 )
    surface.SetTextColor( 255, 255, 255, 255 )
    surface.DrawText("6")
  end


  foldersearchlistl.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 255, 255, 255, 255)
    surface.SetDrawColor( 20, 150, 240, 255 )
    surface.DrawOutlinedRect( w-1, 0, w, h )
  end
  foldersearchlistr.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 255, 255, 255, 255)
    surface.SetDrawColor( 20, 150, 240, 255 )
    surface.DrawOutlinedRect( w-1, 0, w, h )
  end
  foldersearchlistl.VBar.btnGrip.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 20, 150, 240, 255)
  end
  foldersearchlistr.VBar.btnGrip.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 20, 150, 240, 255)
  end


  foldersearchlistl.VBar.btnUp.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 20, 150, 240, 255)
    surface.SetFont("Marlett")
    surface.SetTextPos( 2, 2 )
    surface.SetTextColor( 255, 255, 255, 255 )
    surface.DrawText("5")
  end
  foldersearchlistl.VBar.btnDown.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 20, 150, 240, 255)
    surface.SetFont("Marlett")
    surface.SetTextPos( 2, 1 )
    surface.SetTextColor( 255, 255, 255, 255 )
    surface.DrawText("6")
  end

  foldersearchlistr.VBar.btnUp.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 20, 150, 240, 255)
    surface.SetFont("Marlett")
    surface.SetTextPos( 2, 2 )
    surface.SetTextColor( 255, 255, 255, 255 )
    surface.DrawText("5")
  end
  foldersearchlistr.VBar.btnDown.Paint = function(self, w, h)
    ObjPaint.setBG(0, 0, w, h, 20, 150, 240, 255)
    surface.SetFont("Marlett")
    surface.SetTextPos( 2, 1 )
    surface.SetTextColor( 255, 255, 255, 255 )
    surface.DrawText("6")
  end
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
    if dermaBase.main:HasParent(g_ContextMenu) then
      dermaBase.main:SetParent(ingameView)
      gui.EnableScreenClicker(true)
    else

      RememberCursorPosition()      -- still doesn't work
      dermaBase.main:SetVisible(false)
      gui.EnableScreenClicker(false)
    end

  else

    if dermaBase.main:HasParent(g_ContextMenu) then
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

net.Receive( "requestHotkeyFromServer", function(length, sender )
  if !dermaBase.contexthotkey:GetChecked() then
      net.Start( "toServerHotkey" )
      net.SendToServer()
  end
end )


net.Receive( "openmenu", function()
  local adminHost = net.ReadType()
  mediaplayer:SetSongHost(newHost)
  showMPlayer(adminHost)
end )



net.Receive( "openmenucontext", function()
  local adminHost = net.ReadType()
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