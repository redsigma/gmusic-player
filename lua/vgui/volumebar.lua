local PANEL = {}
local textColor = Color(255, 255, 255)
local slideColor = Color(0, 0, 0, 100)

function PANEL:Init()
	self.previous_volume = 0
  self.is_muted = false

	self.volume_text = self:Add("DLabel")
	self.volume_text:SetMouseInputEnabled( true )
	self.volume_text:SetTextInset( 15, -3 )
	self.volume_text:Dock( RIGHT )
	self.volume_text:SetWidth(45)
	self.volume_text:SetCursor("hand")
	self.volume_text:SetTextColor(textColor)
	self.volume_text.DoClick = function()
		if self.is_muted then
      self:SetVolume(self.previous_volume)
		else
      self:SetVolume(0)
		end
	end
    self.volume_text.Paint = function() end
	self.volume_text.PaintOver = function(panel, w, h)
		if panel:IsHovered() then
			surface.SetDrawColor(255, 255, 255, 30)
			surface.DrawRect(5, 0, w, h - 5)
		end
	end

  self.volume = self:Add("DNumberScratch")
	self.volume:SetImageVisible(false)
	self.volume:SetVisible(false)
	self.volume.OnValueChanged = function(panel, val)
    if self.volume_text ~= vgui.GetKeyboardFocus() then
      self.is_muted = (val == 0)
      if self.is_muted then
        self.volume_text:SetText("Mute")
      else
        self.volume_text:SetText(self.volume:GetTextValue())
      end
      self:OnVolumeChanged(val)
    end
  end

	self.Slider = self:Add("DSlider", self)
	self.Slider:SetLockY( 0.5 )
	self.Slider.TranslateValues = function( slider, x, y ) return self:TranslateSliderValues( x, y ) end
	self.Slider:DockMargin(20, 0, 0, 0)
	self.Slider:Dock( FILL )
	self.Slider:SetHeight( 16 )
	self.Slider.Paint = function( panel, w, h )
		surface.SetDrawColor(slideColor)
		surface.DrawRect( 0, h / 2 - 4, w, 1 )

		surface.DrawRect( w / 4, h / 2, 1, 5 )
		surface.DrawRect( w / 2, h / 2, 1, 5 )
		surface.DrawRect( w - (w / 4), h / 2, 1, 5 )
	end
	self.Slider.Knob:SetSize( 8, 15 )
	self.Slider.Knob.Paint = function(panel, w, h)
		surface.SetDrawColor(textColor)
		surface.DrawRect( 0, -3, w, h)
	end
    self.Slider.Knob.DragMouseRelease = function(mouse_code)
      print("Releaase from slider:", mouseCode)
      if not self.is_muted then
        self.previous_volume = self.volume:GetFloatValue()
      end
    end
    self.Slider.OnMouseReleased = function(mouse_code)
      self.Slider:SetDragging(false)
      self.Slider:MouseCapture(false)
      self.Slider.Knob:DragMouseRelease(mouse_code)
    end

    self:SetTall(32)
    self:SetWide(0)
    self:SetText("")
    self.volume:SetMin(0)
    self.volume:SetMax(100)
    self:SetDecimals(0)
end

function PANEL:OnVolumeClick(lastVolume)
	-- For override
end

function PANEL:SetTextColor( color )
	textColor = color
	self.volume_text:SetTextColor(color)
	self.Slider.Knob.Paint(self.Slider.Knob, self.Slider.Knob:GetWide(), self.Slider.Knob:GetTall())
end

function PANEL:SetSliderColor(color)
	slideColor = color
end

function PANEL:SetFont( value )
	self.volume_text:SetFont(value)
end

function PANEL:SetMinMax( min, max )
	self.volume:SetMin( tonumber( min ) )
	self.volume:SetMax( tonumber( max ) )
	self:UpdateNotches()
end

function PANEL:GetMin()
	return self.volume:GetMin()
end

function PANEL:GetMax()
	return self.volume:GetMax()
end

function PANEL:GetRange()
	return self:GetMax() - self:GetMin()
end

function PANEL:SetMin( min )

	if ( not min ) then min = 0 end

	self.volume:SetMin( tonumber( min ) )
	self:UpdateNotches()
end

function PANEL:SetMax( max )

	if ( not max ) then max = 0 end

	self.volume:SetMax( tonumber( max ) )
	self:UpdateNotches()
end

function PANEL:SetVolume(val)
    val = math.Clamp( tonumber(val) or 0, self:GetMin(), self:GetMax() )
    if ( self:GetVolume() == val ) then return end
    self.volume:SetValue(val)

	-- self:VolumeChanged(self:GetVolume()) -- In most cases this will cause double execution of OnValueChanged
end

function PANEL:GetVolume()
	return self.volume:GetFloatValue()
end

function PANEL:SetDecimals(d)
	self.volume:SetDecimals(d)
	self:UpdateNotches()
--     self.volume.OnValueChanged(self:GetVolume())
	self:OnVolumeChanged( self:GetVolume() ) -- Update the text
end

function PANEL:GetDecimals()
	return self.volume:GetDecimals()
end

function PANEL:IsHovered()
	return self.volume:IsHovered() or self.volume_text:IsHovered() or self.Slider:IsHovered() or vgui.GetHoveredPanel() == self
end

function PANEL:SetConVar( cvar )
	self.volume:SetConVar( cvar )
end

-- function PANEL:VolumeChanged(val)
-- 	val = math.Clamp( tonumber( val ) or 0, self:GetMin(), self:GetMax() )
-- 	if self.volume_text ~= vgui.GetKeyboardFocus() then
-- 		self.volume_text:SetText( self.volume:GetTextValue() )
-- 	end

-- 	self.Slider:SetSlideX( self.volume:GetFraction( val ) )
-- 	self:OnVolumeChanged(val)
-- end

function PANEL:OnVolumeChanged(val)
	-- For override
end

function PANEL:TranslateSliderValues( x, y )
	self:SetVolume( self.volume:GetMin() + ( x * self.volume:GetRange() ) )
	return self.volume:GetFraction(), y
end

function PANEL:GetVolumeText()
	return self.volume_text
end

function PANEL:UpdateNotches()

	local range = self:GetRange()
	self.Slider:SetNotches( nil )

	if ( range < self:GetWide() / 4 ) then
		return self.Slider:SetNotches( range )
	else
		self.Slider:SetNotches( self:GetWide() / 4 )
	end
end

function PANEL:PerformLayout()
	self.Slider:StretchToParent( 0, 0, 0, 0 )
	self.Slider:SetSlideX( self.volume:GetFraction() )
end

derma.DefineControl( "DVolumeBar", "Volume Slider", PANEL, "Panel" )
