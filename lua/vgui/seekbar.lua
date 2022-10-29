local PANEL = {}

local round = math.Round
local textColor = Color(255, 255, 255)

function PANEL:Init()
	self.seek_text = self:Add("DTextEntry")
	self.seek_text:DockMargin(5, 0, 0, 0)
	self.seek_text:Dock(LEFT)
	self.seek_text:SetPaintBackground(false)
	self.seek_text:SetWide(45)
	self.seek_text:SetEditable(false)
	self.seek_text:SetVisible(false)
	self.seek_text.Paint = function(panel, w, h)
		if ( panel.m_bBackground ) then
			if ( panel:GetDisabled() ) then
				self.tex.TextBox_Disabled( 0, 0, w, h )
			elseif ( panel:HasFocus() ) then
				self.tex.TextBox_Focus( 0, 0, w, h )
			else
				self.tex.TextBox( 0, 0, w, h )
			end
		end
		panel:DrawTextEntryText( textColor, textColor, textColor)
	end

	self.seek_text_max = vgui.Create("DTextEntry", self)
	self.seek_text_max:Dock(RIGHT)
	self.seek_text_max:SetPaintBackground(false)
	self.seek_text_max:SetWide(45)
	self.seek_text_max:SetEditable(false)
	self.seek_text_max:SetVisible(false)
	self.seek_text_max.Paint = function(panel, w, h)
		if ( panel.m_bBackground ) then
			if ( panel:GetDisabled() ) then
				self.tex.TextBox_Disabled( 0, 0, w, h )
			elseif ( panel:HasFocus() ) then
				self.tex.TextBox_Focus( 0, 0, w, h )
			else
				self.tex.TextBox( 0, 0, w, h )
			end

		end
		panel:DrawTextEntryText(textColor, textColor, textColor)
	end

	self.seek_val = vgui.Create("DSeekBarClickLayer", self)
  self.seek_val:SetDecimals(1)
	self.seek_val:Dock(FILL)
  self.seek_val.AfterCursorMove = function(panel, seconds_at_cursor)
    local pos_slider =
      math.Remap(panel.seek_seconds_from_slider, 0, panel:GetMax(), 0, 1)
    self:SetTime(seconds_at_cursor, pos_slider)
  end

	self.seek_text:SetValue(string.ToMinutesSeconds(0))
  self.seek_text_max:SetValue(string.ToMinutesSeconds(0))
end

function PANEL:GetSeekLayer()
    return self.seek_val
end

function PANEL:isAllowed()
	return self.seek_val.allow_seek
end

function PANEL:AllowSeek(bool)
  self.seek_val.allow_seek = bool
end

function PANEL:IsCursorMoved()
  return self.seek_val.cursor_moved
end

-- function PANEL:ReleaseSeek()
--     print("[TODO] Release Seek might need rework\n")
--     self.seek_val:OnMouseReleased()
-- end

function PANEL:SetTextFont(font)
	self.seek_text:SetFont(font)
	self.seek_text_max:SetFont(font)
end

function PANEL:SetTextColor(color)
  textColor = color
  self.seek_text.Paint(self.seek_text,
    self.seek_text:GetWide(), self.seek_text:GetTall())
  self.seek_text_max.Paint(self.seek_text_max,
    self.seek_text_max:GetWide(), self.seek_text_max:GetTall())
  self.seek_val:SetTextColor(textColor)
end

function PANEL:SetSliderColor(color)
  self.seek_val:SetSliderColor(color)
end

function PANEL:ResetValue()
  self.seek_val.Slider.Knob:SetVisible(false)
  self.seek_val.seek_seconds_from_slider = 0
  self:SetTime(0, 0)
  self:SetMax(0)
end

-- TODO be able to write text or image in the invisible place
function PANEL:ShowSeekBar(bool)
	self.seek_val:SetVisible(bool)
end

function PANEL:ShowSeekBarIndicator(bool)
  self.seek_val.Slider.Knob:SetVisible(bool)
end

function PANEL:DisableNotches()
	self.seek_val.Slider:SetNotches( nil )
	return true
end

function PANEL:ShowSeekTime()
	self.seek_text:SetVisible(true)
end

function PANEL:ShowSeekLength()
	self.seek_text_max:SetVisible(true)
end

function PANEL:SetMinMax(min, max)
	self.seek_text_max:SetValue(string.ToMinutesSeconds(tonumber(max)))
	self.seek_val:SetMin(tonumber(min))
	self.seek_val:SetMax(tonumber(max))
	self:UpdateNotches()
end

function PANEL:GetMin()
	return self.seek_val:GetMin()
end

function PANEL:GetMax()
	return self.seek_val:GetMax()
end

function PANEL:GetRange()
	return self:GetMax() - self:GetMin()
end

function PANEL:SetMin(min)
	if (not min) then
		min = 0
	end

	self.seek_val:SetMin(tonumber(min))
	self:UpdateNotches()
end

function PANEL:SetMax(max)
	if (not max) then
		max = 0
	end

	self.seek_text_max:SetValue(string.ToMinutesSeconds(tonumber(max)))
	self.seek_val:SetMax(tonumber(max))
	self:UpdateNotches()
end

function PANEL:GetTime()
	return self.seek_val:GetSeekSeconds()
end

function PANEL:IsHovered()
	return self.seek_val:IsHovered() or self.seek_text_max:IsHovered() or self.seek_text:IsHovered() or self.seek_val.Slider:IsHovered() or vgui.GetHoveredPanel() == self
end

function PANEL:SetTime(time_secs, slider_pos)
  if not self.seek_val.allow_seek then return end

	self.seek_val:SetSeekSeconds(time_secs)
	self.seek_text:SetValue(string.ToMinutesSeconds(time_secs))
  self.seek_val:SetSlider(slider_pos)
end

function PANEL:SetSeekText(val)
  self.seek_text:SetValue(string.ToMinutesSeconds(val))
end
function PANEL:GetSeekText()
	return self.seek_text:GetValue()
end

function PANEL:GetSeekLength( isfloat )
	if isfloat then
		return self:GetMax()
	else
		return self.seek_text_max:GetValue()
	end
end

function PANEL:UpdateNotches()
	if self:DisableNotches() then
		self.seek_val.Slider:SetNotches(self:GetMax() / 30)
	end
end

function PANEL:PerformLayout()
end

derma.DefineControl("DSeekBar", "SeekBar Panel", PANEL, "Panel")