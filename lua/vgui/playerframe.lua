local PANEL = {}
AccessorFunc(PANEL, "m_bIsMenuComponent", "IsMenu", FORCE_BOOL)
AccessorFunc(PANEL, "m_bDraggable", "Draggable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bSizable", "Sizable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bScreenLock", "ScreenLock", FORCE_BOOL)
AccessorFunc(PANEL, "m_iMinWidth", "MinWidth")
AccessorFunc(PANEL, "m_iMinHeight", "MinHeight")
local last_mode = false
local colorServerState = Color(255, 150, 0, 255)
local isTSS = false


local function ui_make_play_indicator(parent)
  local title_server_status = vgui.Create("Panel", parent)
  title_server_status:SetMouseInputEnabled(false)
  title_server_status:SetVisible(true)
  title_server_status:SetSize(10, 20)

  title_server_status.Paint = function(panel, w, h)
    surface.SetDrawColor(colorServerState)
    surface.DrawRect(0, 0, w, h)
  end

  return title_server_status
end

local function ui_make_title(parent)
  local text_title = vgui.Create("DLabel", parent)
  text_title:SetPos(0, 0)
  text_title:SetFont("default")
  text_title:SetTextColor(Color(255, 255, 255))

  text_title.Paint = function(panel, w, h)
    surface.SetDrawColor(150, 150, 150, 255)
    surface.DrawRect(0, 0, w, h)
  end

  return text_title
end

local function ui_make_switch_mode(parent)
  local button_server_client = vgui.Create("DButton", parent)
  button_server_client:SetFont("default")
  button_server_client:SetTextColor(Color(255, 255, 255))
  button_server_client:SetText("CLIENT")
  button_server_client:SetSize(60, 20)

  button_server_client.Paint = function()
  end

  button_server_client.PaintOver = function(panel, w, h)
    if button_server_client:IsHovered() then
      surface.SetDrawColor(255, 255, 255, 30)
      surface.DrawRect(0, 0, w, h)
    end
  end

  return button_server_client
end

local function ui_make_settings(parent)
  local button_settings = vgui.Create("DImageButton", parent)
  button_settings:SetKeepAspect(true)
  button_settings:SetStretchToFit(false)

  -- self.buttonSettings:SetText("")
  button_settings:SetImage("icon16/cog.png")
  -- self.buttonSettings:SetSize(22, 20)

  button_settings.Paint = function() end

  button_settings.PaintOver = function(panel, w, h)
    if button_settings:IsHovered() then
      surface.SetDrawColor(255, 255, 255, 30)
      surface.DrawRect(0, 0, w, h)
    end
  end

  return button_settings
end

local function ui_make_exit(parent)
  local button_close = vgui.Create("DButton", parent)
  button_close:SetFont("default")
  button_close:SetText("X")
  button_close:SetSize(20, 20)
  button_close:SetTextColor(Color(255, 255, 255))

  button_close.DoClick = function(button)
    self:Close()
  end

  button_close.Paint = function() end

  button_close.PaintOver = function(panel, w, h)
    if button_close:IsHovered() then
      surface.SetDrawColor(255, 255, 255, 30)
      surface.DrawRect(0, 0, w, h)
    end
  end

  return button_close
end



function PANEL:Init()
  self:SetMouseInputEnabled(true)
  self:SetFocusTopLevel(false)
  self:SetCursor("sizeall")
  self:UpdateWindowSize()

  self.TSS = ui_make_play_indicator(self)

  self.labelTitle = ui_make_title(self)
  self.labelTitle:SetX(self.TSS:GetWide())

  self.buttonMode = ui_make_switch_mode()
  self.buttonMode.DoClick = function(button)
    self:SwitchMode()
  end

  self.buttonSettings = ui_make_settings()
  self.buttonSettings.DoClick = function(button)
    self:Settings()
  end

  self.buttonClose = ui_make_exit()
  self.buttonClose.DoClick = function(button)
    self:Close()
  end

  self.hbox_right = vgui.Create("DHBox", self)
  self.hbox_right:Add(self.buttonMode)
  self.hbox_right:Add(self.buttonSettings)
  self.hbox_right:Add(self.buttonClose)



  -- TODO: not sure if i need this
  -- self.hbox_center:UpdateLayout()


  self:SetTitle("MMMMMAMCCCCCCCCCCCCCCCCCCCaMMMMMAMCCCCCCCCCCCCCCCCCCCaMMMMMAMCCCCCCCCCCCCCCCCCCCaMMMMMAMCCCCCCCCCCCCCCCCCCCaMMMMMAMCCCCCCCCCCCCCCCCCCCabbb")

  self.hbox_right:__debug_panel(0, 255, 0)


  self.title_color = {}
  self.is_server_mode = false

  self:SetDraggable(true)
  self:SetSizable(true)
  self:SetScreenLock(false)
  self:SetText("Window")
  self:SetMinWidth(500)
  self:SetMinHeight(300)
  self:SetPos(20, 20)

  -- This turns off the engine drawing
  self:SetPaintBackgroundEnabled(false)
  self:SetPaintBorderEnabled(false)
  self:DockPadding(0, 0, 0, 0)
end

function PANEL:SetFont(font)
  self.labelTitle:SetFont(font)
  self.buttonClose:SetFont(font)
  self.buttonMode:SetFont(font)
end

function PANEL:IsTSSEnabled()
  return isTSS
end

function PANEL:playingFromAnotherMode()
  return last_mode ~= self.is_server_mode
end

function PANEL:SetTSSEnabled(bool)
  if bool then
    self.labelTitle:SetPos(10, 0)
  else
    self.labelTitle:SetPos(0, 0)
  end

  self.TSS:SetVisible(bool)
  isTSS = bool
end

function PANEL:SetTitleServerState(selected_mode)
  if selected_mode then
    colorServerState = Color(20, 150, 240, 255)
  else
    colorServerState = Color(255, 150, 0, 255)
  end

  last_mode = selected_mode

  self.TSS.Paint = function(panel, w, h)
    surface.SetDrawColor(colorServerState)
    surface.DrawRect(0, 0, w, h)
  end
end

function PANEL:SetTitleBGColor(r, g, b)
  self.labelTitle.Paint = function(panel, w, h)
    surface.SetDrawColor(r, g, b, 255)
    surface.DrawRect(0, 0, w, h)
  end

  if g == nil then
    self.title_color = r
  else
    self.title_color = {r, g, b}
  end
end

function PANEL:UpdateWindowSize()
  if (ScrW() < 800) then
    self:SetSize(500, 400)
  elseif (ScrW() > 1280) then
    self:SetSize(1160, 400 + (ScrW() / 7))
  else
    self:SetSize(ScrW() - 120, 400)
  end
end

function PANEL:OnScreenSizeChanged(old_width, old_height)
  self:UpdateWindowSize()
end

function PANEL:ShowCloseButton(bShow)
  self.btnClose:SetVisible(bShow)
end

function PANEL:GetTitle()
  return self.labelTitle:GetText()
end

function PANEL:SetTitle(strTitle)
  self.labelTitle:SetText(strTitle)
  self.labelTitle:SizeToContents()

  self.hbox_right:SetPosNearPanel(self.labelTitle)
end

function PANEL:GetTitleColor()
  return self.labelTitle:GetTextColor()
end

function PANEL:SetTitleColor(color)
  self.labelTitle:SetTextColor(color)
end

function PANEL:Close()
  gui.EnableScreenClicker(false)
  self:SetVisible(false)
  self:OnClose()
end

function PANEL:OnClose()
end

function PANEL:SwitchModeServer()
  self.is_server_mode = true
  self.buttonMode:SetText("SERVER")
  self.buttonMode:SizeToContents()

  self.hbox_right:SizeToContentsX()



  self.buttonMode.Paint = function(panel, w, h)
    surface.SetDrawColor(20, 150, 240, 255)
    surface.DrawRect(0, 0, w, h)
  end

  self:OnServerMode()
end

function PANEL:SwitchModeClient()
  self.is_server_mode = false
  self.buttonMode:SetText("CLIENT")
  -- self.buttonMode:SizeToContents()
  -- self.hbox_right:SizeToContentsX()

  self.buttonMode.Paint = function() end
  self:OnClientMode()
end

function PANEL:SwitchMode(is_server)
  local is_server_mode = self.is_server_mode

  if is_server ~= nil then
    is_server_mode = not is_server
  end

  if is_server_mode then
    self:SwitchModeClient()
  else
    self:SwitchModeServer()
  end
end

function PANEL:IsServerMode()
  return self.is_server_mode
end

function PANEL:OnClientMode()
end

-- override
function PANEL:OnServerMode()
end

-- override
function PANEL:Settings()
  self:OnSettingsClick()
end

function PANEL:OnSettingsClick()
end

function PANEL:Center()
  self:InvalidateLayout(true)
  self:CenterVertical()
  self:CenterHorizontal()
end

function PANEL:IsActive()
  if (self:HasFocus()) then return true end
  if (vgui.FocusedHasParent(self)) then return true end

  return false
end

function PANEL:OnResizing()
end

function PANEL:AfterResizing()
end

function PANEL:Think()
  local mousex = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
  local mousey = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

  if (self.Dragging) then
    local x = mousex - self.Dragging[1]
    local y = mousey - self.Dragging[2]

    -- Lock to screen bounds if screenlock is enabled
    if (self:GetScreenLock()) then
      x = math.Clamp(x, 0, ScrW() - self:GetWide())
      y = math.Clamp(y, 0, ScrH() - self:GetTall())
    end

    self:SetPos(x, y)
  end

  if (self.Sizing) then
    local x = mousex - self.Sizing[1]
    local y = mousey - self.Sizing[2]
    local px, py = self:GetPos()

    if (x < self.m_iMinWidth) then
      x = self.m_iMinWidth
    elseif (x > ScrW() - px and self:GetScreenLock()) then
      x = ScrW() - px
    end

    if (y < self.m_iMinHeight) then
      y = self.m_iMinHeight
    elseif (y > ScrH() - py and self:GetScreenLock()) then
      y = ScrH() - py
    end

    self:SetSize(x, y)
    self:SetCursor("sizenwse")

    return
  end

  if (self.Hovered and self.m_bSizable and mousex > (self.x + self:GetWide() - 20) and mousey > (self.y + self:GetTall() - 20)) then
    self:SetCursor("sizenwse")

    return
  end

  if (self.Hovered and self:GetDraggable() and mousey < (self.y + self.labelTitle:GetTall())) then
    self:SetCursor("sizeall")

    return
  end

  self:SetCursor("arrow")

  if (self.y < 0) then
    self:SetPos(self.x, 0)
  end

  self:OnUpdateUI()
end

--[[
    Callback for custom use
--]]
function PANEL:OnUpdateUI()
end

function PANEL:Paint(w, h)
  derma.SkinHook("Paint", "Frame", self, w, h)

  return true
end

function PANEL:OnMousePressed()
  if (self.m_bSizable and gui.MouseX() > (self.x + self:GetWide() - 20) and gui.MouseY() > (self.y + self:GetTall() - 20)) then
    self.Sizing = {gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall()}

    self:MouseCapture(true)
    self:OnResizing()

    return
  end

  if (self:GetDraggable() and gui.MouseY() < (self.y + 24)) then
    self.Dragging = {gui.MouseX() - self.x, gui.MouseY() - self.y}

    self:MouseCapture(true)

    return
  end
end

function PANEL:IsMouseReleased()
end

function PANEL:OnMouseReleased()
  self.Dragging = nil

  if self.Sizing then
    self:AfterResizing()
  end

  self.Sizing = nil
  self:MouseCapture(false)
  self:IsMouseReleased()
end

function PANEL:HasParents(panel)
  if IsValid(panel) then return self:HasParent(panel) end
end

function PANEL:OnLayoutChange()
end

function PANEL:PerformLayout()
  self.hbox_right:SetSizeWithPanel(self:GetWide(), 20)
  self.hbox_right:UpdateSizeContents()

  self:OnLayoutChange()
end

------------------------------------------------------------------------------




derma.DefineControl("DgMPlayerFrame", "Music Player", PANEL, "EditablePanel")