local PANEL = {}

function PANEL:Init()

	self.TextArea = self:Add( "DTextEntry" )
	self.TextArea:Dock( RIGHT )
	self.TextArea:SetPaintBackground( false )
	self.TextArea:SetWide( 45 )
	self.TextArea:SetNumeric( true )
	self.TextArea.OnChange = function( textarea, val ) self:SetValue( self.TextArea:GetText() ) end

	self.Slider = self:Add( "DSlider", self )
	self.Slider:SetLockY( 0.5 )
	self.Slider.TranslateValues = function( slider, x, y ) return self:TranslateSliderValues( x, y ) end
	self.Slider:SetTrapInside( true )
	self.Slider:Dock( FILL )
	self.Slider:SetHeight( 16 )
	Derma_Hook( self.Slider, "Paint", "Paint", "NumSlider" )

	self.Scratch = self:Add( "DNumberScratch" )
	self.Scratch:SetImageVisible( false )

	self.Scratch:Dock( FILL )
  self.Scratch:SetVisible(false)
	self.Scratch.OnValueChanged = function() self:ValueChanged( self.Scratch:GetFloatValue() ) end

	self:SetTall( 32 )

	self:SetMin( 0 )
	self:SetMax( 100 )
	self:SetDecimals( 0 )
	self:SetText( "" )

	self.Wang = self.Scratch
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
	self.TextArea:SetConVar( cvar )
end

function PANEL:ValueChanged( val )

	val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )
	if ( self.TextArea != vgui.GetKeyboardFocus() ) then
		self.TextArea:SetValue( self.Scratch:GetTextValue() )
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
	self.Scratch:SetVisible( false )
	self.Slider:StretchToParent( 0, 0, 0, 0 )
	self.Slider:SetSlideX( self.Scratch:GetFraction() )
end

derma.DefineControl( "DNumSliderNoLabel", "DNumSliderNoLabel", PANEL, "Panel" )
