local PANEL = {}
local textColor = Color(255, 255, 255)
local slideColor = Color(0, 0, 0, 100)

AccessorFunc( PANEL, "m_bMute", "Mute", FORCE_BOOL )

function PANEL:Init()
	self.prevVol = 0

	self.TextArea = self:Add("DLabel")
	self.TextArea:SetMouseInputEnabled( true )
	self.TextArea:SetTextInset( 10, -3 )
	self.TextArea:Dock( RIGHT )
	self.TextArea:SetWide( 45 )
	self.TextArea:SetCursor( "hand" )
	self.TextArea:SetTextColor(textColor)
	self.TextArea.OnChange = function( textarea, val ) self:SetValue( self.TextArea:GetText() ) end
	self.TextArea.DoClick = function()
		self.m_bMute = !self.m_bMute
		if self.m_bMute then
			self.TextArea:SetText("Mute")
		else
			self.TextArea:SetText(self.Scratch:GetTextValue())
		end
		self.prevVol = self.Scratch:GetFraction()
		self:OnVolumeClick(self.prevVol)
	end

	self.Slider = self:Add( "DSlider", self )
	self.Slider:SetLockY( 0.5 )
	self.Slider.TranslateValues = function( slider, x, y ) return self:TranslateSliderValues( x, y ) end
	self.Slider:SetTrapInside( true )
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

	self.Scratch = self:Add( "DNumberScratch" )
	self.Scratch:SetImageVisible( false )

	self.Scratch:SetVisible(false)
	self.Scratch.OnValueChanged = function() self:ValueChanged( self.Scratch:GetFloatValue() ) end

	self:SetTall( 32 )

	self:SetMin( 0 )
	self:SetMax( 100 )
	self:SetDecimals( 0 )
	self:SetText( "" )

	self.Wang = self.Scratch
end

function PANEL:OnVolumeClick(lastVolume)
	-- For override
end

function PANEL:SetTextColor( color )
	textColor = color
	self.TextArea:SetTextColor(color)
	self.Slider.Knob.Paint(self.Slider.Knob, self.Slider.Knob:GetWide(), self.Slider.Knob:GetTall())
end

function PANEL:SetSliderColor(color)
	slideColor = color
end

function PANEL:SetFont( value )
	self.TextArea:SetFont(value)
end

function PANEL:SetMinMax( min, max )
	self.Scratch:SetMin( tonumber( min ) )
	self.Scratch:SetMax( tonumber( max ) )
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

function PANEL:SetMin( min )

	if ( !min ) then min = 0 end

	self.Scratch:SetMin( tonumber( min ) )
	self:UpdateNotches()
end

function PANEL:SetMax( max )

	if ( !max ) then max = 0 end

	self.Scratch:SetMax( tonumber( max ) )
	self:UpdateNotches()
end

function PANEL:SetValue( val )
	val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )
	if ( self:GetValue() == val ) then return end

	self.Scratch:SetValue( val ) -- This will also call ValueChanged
	self:ValueChanged( self:GetValue() ) -- In most cases this will cause double execution of OnValueChanged
end

function PANEL:GetValue()
	return self.Scratch:GetFloatValue()
end

function PANEL:SetDecimals( d )
	self.Scratch:SetDecimals( d )
	self:UpdateNotches()
	self:ValueChanged( self:GetValue() ) -- Update the text
end

function PANEL:GetDecimals()
	return self.Scratch:GetDecimals()
end

function PANEL:IsHovered()
	return self.Scratch:IsHovered() || self.TextArea:IsHovered() || self.Slider:IsHovered() || vgui.GetHoveredPanel() == self
end

function PANEL:SetConVar( cvar )
	self.Scratch:SetConVar( cvar )
end

function PANEL:ValueChanged( val )

	val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )
	if ( self.TextArea != vgui.GetKeyboardFocus() ) then
		self.TextArea:SetText( self.Scratch:GetTextValue() )
	end

	self.Slider:SetSlideX( self.Scratch:GetFraction( val ) )
	self:OnValueChanged( val )
end

function PANEL:OnValueChanged( val )
	-- For override
end

function PANEL:TranslateSliderValues( x, y )

	self:SetValue( self.Scratch:GetMin() + ( x * self.Scratch:GetRange() ) )
	return self.Scratch:GetFraction(), y
end

function PANEL:GetTextArea()
	return self.TextArea
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
	self.Slider:SetSlideX( self.Scratch:GetFraction() )
end

derma.DefineControl( "DNumSliderNoLabel", "DNumSliderNoLabel", PANEL, "Panel" )
