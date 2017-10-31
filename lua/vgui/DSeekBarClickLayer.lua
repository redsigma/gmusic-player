local PANEL = {}
AccessorFunc(PANEL, "m_numMin", "Min")
AccessorFunc(PANEL, "m_numMax", "Max")
AccessorFunc(PANEL, "m_fFloatValue", "FloatValue")
AccessorFunc(PANEL, "Dragging", "Dragging")

function PANEL:Init()
	self:SetMouseInputEnabled(true)
	self:SetMin(0)
	self:SetMax(0)
	self:SetFloatValue(0)

end

function PANEL:OnValueChanged()
	-- changes goes here and not in the seekbar
end

function PANEL:OnCursorMoved(x, y)
	if (not self.Dragging) then
		return
	end

	local w, h = self:GetSize()
	x = math.Clamp(x, 0, w) / w
	y = math.Clamp(y, 0, h) / h
	x, y = self:TranslateValues(x, y)
	self:OnValueChanged()
end

function PANEL:SetFraction(fFraction)
	self:SetFloatValue(self:GetMin() + (fFraction * self:GetRange()))
end

function PANEL:GetFraction()
	return (self:GetFloatValue() - self:GetMin()) / self:GetRange()
end

function PANEL:GetValue()
	return self:GetFloatValue()
end

function PANEL:GetRange()
	return self:GetMax() - self:GetMin()
end

function PANEL:TranslateValues(x, y)
	self:SetFraction(x)
end

function PANEL:OnMousePressed(mcode)
	self:SetDragging(true)
	self:MouseCapture(true)
	local x, y = self:CursorPos()
	self:OnCursorMoved(x, y)
end

function PANEL:OnMouseReleased(mcode)
	self:SetDragging(false)
	self:MouseCapture(false)
end

derma.DefineControl("DSeekBarClickLayer", "SeekBar Click Invisible Panel", PANEL, "Panel")
