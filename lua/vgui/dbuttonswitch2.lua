local PANEL = {}

local titleMargin
local last_mode = false
local colorServerState = Color(255, 150, 0, 255)
local isTSS = false

local action_state = 0


function PANEL:Init()
  -- self:SetMouseInputEnabled(true)
  -- self:SetFocusTopLevel(false)
  -- self:SetCursor("sizeall")
  -- self:UpdateWindowSize()
  -- self.TSS = vgui.Create("Panel", self)
  -- self.TSS:SetVisible(false)
  -- self.TSS:SetSize(10, 20)

  -- self.TSS.Paint = function(panel, w, h)
  --   surface.SetDrawColor(colorServerState)
  --   surface.DrawRect(0, 0, w, h)
  -- end


  self.button = vgui.Create("DButton", self)
  self.button:SetFont("default")
  self.button:SetTextColor(Color(255, 255, 255))

  self.button.DoClick = function(button)
    action_state = 0
    if action_state != 0 then

      OnClickState1()
      action_state = 1
      return
    end

    if action_state == 1 then

      OnClickState2()
      action_state = 0
      return
    end
  end

  -- self.button.Paint = function() end

  -- self.button.PaintOver = function(panel, w, h)
  --   if self.button:IsHovered() then
  --     surface.SetDrawColor(255, 255, 255, 30)
  --     surface.DrawRect(0, 0, w, h)
  --   end
  -- end


  self:SizeToContents()

  -- This turns off the engine drawing
  self:SetPaintBackgroundEnabled(false)
  self:SetPaintBorderEnabled(false)
  self:DockPadding(0, 0, 0, 0)
end

function PANEL:SizeToContents()
  self.button:SizeToContents()
	local w, h = self.button:GetContentSize()
	self:SetSize( w + 8, h + 4 )
end

function PANEL:SetFont(font_name)
  self.button:SetFont(font_name)
end

function PANEL:SetText(text)
  self.button:SetText(text)
end

function PANEL:SetTextColor(color)
  self.button:SetTextColor(color)
end


function PANEL:OnClickState1()
  -- override
end

function PANEL:OnClickState2()
  -- override
end

derma.DefineControl("DButtonSwitch2State", "Two State Button", PANEL, "Panel")