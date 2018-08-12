local PANEL = {}

AccessorFunc( PANEL, "m_colText",		"TextColor" )
AccessorFunc( PANEL, "m_FontName",		"Font" )

AccessorFunc( PANEL, "m_bDoubleClicking",		"DoubleClickingEnabled",	FORCE_BOOL )
AccessorFunc( PANEL, "m_bAutoStretchVertical",	"AutoStretchVertical",		FORCE_BOOL )

function PANEL:Init()
	self:SetMouseInputEnabled( true )
	self:SetKeyboardInputEnabled( false )
	self:SetDoubleClickingEnabled( true )

	self:SetPaintBackgroundEnabled( false )
	self:SetPaintBorderEnabled( false )

	self:SetFont( "DermaDefault" )
	self:SetTextColor( self:GetSkin().Colours.Label.Default )

	self.PaintOver = function (panel, w, h)
		if self:IsHovered() then
			surface.SetDrawColor(255, 255, 255, 50)
			surface.DrawRect(0, 0, w, h)
		end
	end
end

function PANEL:SetFont( strFont )

	self.m_FontName = strFont
	self:SetFontInternal( self.m_FontName )

end

function PANEL:SetTextColor( color )
	self.m_colText = color
	self:UpdateFGColor()
end

function PANEL:UpdateFGColor()
	if ( !self.m_colText ) then return end
	self:SetFGColor( self.m_colText.r, self.m_colText.g, self.m_colText.b, self.m_colText.a )
end


function PANEL:Think()

	if ( self:GetAutoStretchVertical() ) then
		self:SizeToContentsY()
	end

end

function PANEL:PerformLayout()
	self:UpdateFGColor()
end

function PANEL:OnMousePressed( mousecode )
	if ( mousecode == MOUSE_LEFT && !dragndrop.IsDragging() && self.m_bDoubleClicking ) then

		if self.LastClickTime && SysTime() - self.LastClickTime < 0.2 then

			self:DoDoubleClickInternal()
			self:DoDoubleClick()
			return
		end
		self.LastClickTime = SysTime()
	end

	self:MouseCapture( true )
	self.Depressed = true
	self:OnDepressed()
	self:InvalidateLayout( true )

	self:DragMousePress( mousecode )
end

function PANEL:OnMouseReleased( mousecode )
	self:MouseCapture( false )

	if !self.Depressed then return end

	self.Depressed = nil
	self:OnReleased()
	self:InvalidateLayout( true )

	if self:DragMouseRelease( mousecode ) then
		return
	end

	if self:IsSelectable() && mousecode == MOUSE_LEFT then

		local canvas = self:GetSelectionCanvas()
		if canvas then
			canvas:UnselectAll()
		end

	end

	if !self.Hovered then return end

	self.Depressed = true

	if mousecode == MOUSE_RIGHT then
		self:DoRightClick()
	end

	if mousecode == MOUSE_LEFT then
		self:DoClickInternal()
		self:DoClick()
	end

	if mousecode == MOUSE_MIDDLE then
		self:DoMiddleClick()
	end

	if mousecode == MOUSE_4 then
		self:DoLeftTilt()
	end

	if mousecode == MOUSE_5 then
		self:DoRightTilt()
	end

	self.Depressed = nil

end

function PANEL:OnReleased()
end

function PANEL:OnDepressed()
end


function PANEL:DoClick()
end

function PANEL:DoRightClick()
end

function PANEL:DoMiddleClick()
end

function PANEL:DoLeftTilt()
end

function PANEL:DoRightTilt()
end

function PANEL:DoClickInternal()
end

function PANEL:DoDoubleClick()
end

function PANEL:DoDoubleClickInternal()
end


derma.DefineControl( "DBetterColumn", "A Better Column", PANEL, "Label" )