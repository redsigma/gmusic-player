local PANEL = {}
AccessorFunc(PANEL, "m_numMin", "Min")
AccessorFunc(PANEL, "m_numMax", "Max")
AccessorFunc(PANEL, "Dragging", "Dragging")

-- Derma_Install_Convar_Functions( PANEL )

local round = math.Round
local textColor = Color(255, 255, 255)
local slideColor = Color(0, 0, 0, 100)

function PANEL:Init()
	self:SetMouseInputEnabled(true)
	self:SetMin(0)
	self:SetMax(0)
  self:SetWide(0)
  self:SetTall(0)

  -- Used for stopping the realtime audio after checking 3 times
  self.current_slider_pos = 0
  self.previous_slider_pos = 0

  -- Used for realtime seek and cursor seek on release
  self.seek_seconds = 0
  -- Used to overwrite seek_seconds if manual seek
  self.seek_seconds_from_slider = 0

  self.decimals = 0
  self.allow_seek = false
  self.cursor_moved = false

  local margin = 15
  self.Slider = self:Add("DSlider")
  self.Slider:SetSlideX(0)
	self.Slider:SetSlideY(0)
	self.Slider:SetLockY(0)
	self.Slider:SetTrapInside(true)
	self.Slider:Dock(FILL)
	self.Slider:SetHeight(self:GetTall())
  self.Slider:DockMargin(0, 0, margin, 0)
  self.Slider.Knob:SetMouseInputEnabled(false)
  self.Slider.Knob:SetVisible(false)
	self.Slider.Paint = function(panel, w, h)
		surface.SetDrawColor(slideColor)
		surface.DrawRect( 0, h / 2 - 1, w, 1 )

		surface.DrawRect( w / 4, h / 2 + 3, 1, 5 )
		surface.DrawRect( w / 2, h / 2 + 3, 1, 5 )
		surface.DrawRect( w - (w / 4), h / 2 + 3, 1, 5 )
	end
	self.Slider.Knob.Paint = function(panel, w, h)
		surface.SetDrawColor(textColor)
		surface.DrawRect( 0, 5, w, self:GetTall() - 8 )
	end
  -- self.Slider.OnMousePressed = function(self, mcode)
  --     self:OnMousePressed(mcode)
  -- end
  -- self.Slider.OnMouseReleased = function(self, mcode)
  --     self:OnMouseReleased(mcode)
  -- end
end

function PANEL:OnEndReached()
    -- override
end

function PANEL:SetSlider(pos_x)
  self.Slider:SetSlideX(pos_x)
  self.previous_slider_pos = self.current_slider_pos
  self.current_slider_pos = pos_x
end

function PANEL:SetSliderColor(color)
	slideColor = color
end

function PANEL:SetTextColor(color)
	textColor = color
  self.Slider.Knob.Paint(
    self.Slider.Knob, self.Slider.Knob:GetWide(), self.Slider.Knob:GetTall())
end

function PANEL:OnValueChanged(seconds)
	-- override
end

function PANEL:SetDecimals(val)
	self.decimals = val
end

function PANEL:GetDecimals()
	return self.decimals or 0
end

function PANEL:GetFraction()
	return (self:GetSeekSeconds() - self:GetMin()) / self:GetRange()
end

function PANEL:SetSeekSeconds(seek_time)
  self.seek_seconds = seek_time
end

function PANEL:GetSeekSeconds()
	return self.seek_seconds
end

function PANEL:GetRange()
	return self:GetMax() - self:GetMin()
end

function PANEL:OnMousePressed(mcode)
	self:SetDragging(true)
	self:MouseCapture(true)
	local x, y = self:CursorPos()
	self:OnCursorMoved(x)
end

function PANEL:AfterCursorMove(seconds_at_cursor)
    --override
end

function PANEL:OnMouseReleased(mcode)
	self:SetDragging(false)
	self:MouseCapture(false)
  self:OnValueChanged(self.seek_seconds_from_slider)
  self.cursor_moved = false
end

-- Needs to be called before reaching end of slider
function PANEL:can_reset_slider(pos_x)
  -- override
end

function PANEL:OnCursorMoved(pos_x)
  if pos_x < 0 or (not self.allow_seek or not self.Dragging) then
    return
  end

  self.cursor_moved = true
  local slider_max_size = self.Slider:GetWide()
  if pos_x >= slider_max_size then
    if self:can_reset_slider() then
      self:OnMouseReleased()
      self:OnEndReached()
      self.seek_seconds_from_slider = 0
    end
    return
  end

  -- remap slider width to audio length in 0 - 1 range
  self.seek_seconds_from_slider = ((pos_x / slider_max_size) or 0)
    * (self:GetMax() - self:GetMin())
  self:AfterCursorMove(self.seek_seconds_from_slider)
end

derma.DefineControl("DSeekBarClickLayer", "SeekBar Click Invisible Panel", PANEL, "Panel")
