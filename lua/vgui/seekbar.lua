local PANEL = {}

function PANEL:Init()

  self.TextCurrent = self:Add("DTextEntry")
  self.TextCurrent:Dock(LEFT)
  self.TextCurrent:SetPaintBackground(false)
  self.TextCurrent:SetWide(45)
  self.TextCurrent:SetEditable(false)
  self.TextCurrent:SetVisible(false)

  self.TextLength = self:Add("DTextEntry")
  self.TextLength:Dock(RIGHT)
  self.TextLength:SetPaintBackground(false)
  self.TextLength:SetWide(45)
  self.TextLength:SetEditable(false)
  self.TextLength:SetVisible(false)


  self.Slider = self:Add("DSlider", self)
  self.Slider:SetSlideY(0)
  self.Slider:SetLockY(0)
  self.Slider.TranslateValues = function(slider, x, y) return self:TranslateSliderValues(x, y) end
  self.Slider:SetTrapInside(true)
  self.Slider:Dock(FILL)
  self.Slider:SetHeight(self:GetTall())
  Derma_Hook(self.Slider, "Paint", "Paint", "NumSlider")


  self.SeekClick = vgui.Create("DSeekBarClickLayer", self)
  self.SeekClick:Dock(FILL)


  self.Scratch = self:Add("DNumberScratch")
  self.Scratch:SetImageVisible(false)
  self.Scratch:SetDecimals(1)
  self.Scratch:Dock(FILL)

  self:SetValue(0)
  self:SetMin(0)
  self:SetMax(0)
  self:SetText("")
  self.TextCurrent:SetValue(string.ToMinutesSeconds(0))
  self.Scratch:SetFloatValue(0)
  self.Wang = self.Scratch
end

function PANEL:SetTextFont(font)
  self.TextCurrent:SetFont(font)
  self.TextLength:SetFont(font)
end

function PANEL:SetTextColor(r,g,b)
  self.TextCurrent:SetTextColor(Color(r,g,b))
  self.TextLength:SetTextColor(Color(r,g,b))
end

function PANEL:ResetValue()
  self.TextCurrent:SetValue(string.ToMinutesSeconds(self:GetMin()))
  self:SetValue(self:GetMin())
  self:SetMax(self:GetMin())
end

function PANEL:Invisible()
  self.Slider.Knob:SetVisible(false)
  self.Slider.Paint = function() end
  self.Paint = function() end
end

function PANEL:DisableNotches()
  self.Slider:SetNotches( nil )
  return true
end

function PANEL:ShowSeekTime()
  self.TextCurrent:SetVisible(true)
end

function PANEL:ShowSeekLength()
  self.TextLength:SetVisible(true)
end

function PANEL:SetMinMax(min, max)
  self.TextLength:SetValue(string.ToMinutesSeconds(tonumber(max)))
  self.Scratch:SetMin(tonumber(min))
  self.Scratch:SetMax(tonumber(max))
  self.SeekClick:SetMin(tonumber(min))
  self.SeekClick:SetMax(tonumber(max))
  self:UpdateNotches()
end

function PANEL:GetMin()
  return self.Scratch:GetMin()
end

function PANEL:GetMax()
  return self.Scratch:GetMax()
end

function PANEL:GetRange()
  return self:GetMax() - self:GetMin()
end

function PANEL:SetMin(min)
  if (not min) then
    min = 0
  end

  self.Scratch:SetMin(tonumber(min))
  self.SeekClick:SetMin(tonumber(min))
  self:UpdateNotches()
end

function PANEL:SetMax(max)
  if (not max) then
    max = 0
  end

  self.TextLength:SetValue(string.ToMinutesSeconds(tonumber(max)))
  self.Scratch:SetMax(tonumber(max))
  self.SeekClick:SetMax(tonumber(max))
  self:UpdateNotches()
end

function PANEL:SetValue(val)
  val = math.Clamp(tonumber(val) or 0, self:GetMin(), self:GetMax())

  if (self:GetValue() == val) then
    return
  end

  self.SeekClick:SetFloatValue(val)
  self.Scratch:SetFloatValue(val)
  self.TextCurrent:SetValue(string.ToMinutesSeconds(val))
end

function PANEL:GetValue()
  return self.SeekClick:GetValue()
end

function PANEL:IsEditing()
  return self.Scratch:IsEditing() or self.TextLength:IsEditing() or self.TextCurrent:IsEditing() or self.Slider:IsEditing()
end

function PANEL:IsHovered()
  return self.Scratch:IsHovered() or self.TextLength:IsHovered() or self.TextCurrent:IsHovered() or self.Slider:IsHovered() or vgui.GetHoveredPanel() == self
end

function PANEL:ValueChanged(val)
  val = math.Clamp(tonumber(val) or 0, self:GetMin(), self:GetMax())

  if (self.TextCurrent ~= vgui.GetKeyboardFocus()) then
    self.TextCurrent:SetValue(string.ToMinutesSeconds(self.Scratch:GetFloatValue()))
  end

  self.TextLength:SetValue(string.ToMinutesSeconds(self:GetMax()))
  self.Slider:SetSlideX(self.Scratch:GetFraction(val))
end

function PANEL:TranslateSliderValues(x, y)
  self:SetValue(self.Scratch:GetMin() + (x * self.Scratch:GetRange()))
  return self.Scratch:GetFraction(), y
end

function PANEL:SetTime( val )
  self:SetValue(val)
end

function PANEL:GetSeekTime( isfloat )
  if isfloat then
    return self.Scratch:GetFloatValue()
  else
    return self.TextCurrent:GetValue()
  end
end

function PANEL:GetSeekLength( isfloat )
  if isfloat then
    return self:GetMax()
  else
    return self.TextLength:GetValue()
  end
end

function PANEL:UpdateNotches()
  if self:DisableNotches() then
    self.Slider:SetNotches(self:GetMax() / 30)
  end
end

function PANEL:PerformLayout()
  self.Scratch:SetVisible(false)
  self.Slider:StretchToParent(0, 0, 0, 0)
  self.Slider:SetSlideX(self.Scratch:GetFraction())
end

derma.DefineControl("DSeekBar", "SeekBar Panel", PANEL, "Panel")
