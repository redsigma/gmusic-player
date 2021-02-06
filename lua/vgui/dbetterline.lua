
local PANEL2 = {}

function PANEL2:Init()
	self:SetTextInset( 5, 0 )
end

derma.DefineControl( "DPureLabel", "", PANEL2, "DLabel" )

local PANEL = {}

Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "ListViewLine" )

AccessorFunc( PANEL, "m_FontName", "Font" )
AccessorFunc( PANEL, "m_iID", "ID" )
AccessorFunc( PANEL, "m_bAlt", "AltLine" )
AccessorFunc( PANEL, "m_bDoubleClicking", "DoubleClickingEnabled", FORCE_BOOL )

local delta = 0

function PANEL:Init()

	self.col = Color(255, 255, 255)
	self.m_FontName = "default"
	self:SetSelectable( true )
	self:SetMouseInputEnabled( true )
	self:SetDoubleClickingEnabled( true )


	self.Columns = {}
end

function PANEL:SetTextColor(color)
	self.col = color
	for k, label in pairs(self.Columns) do
		label:SetTextColor(self.col)
	end
end

function PANEL:GetTextColor()
	return self.col
end

function PANEL:BeforeMousePress(index)
end

function PANEL:OnMousePressed( mcode )
	self:BeforeMousePress(self.m_iID)

	if mcode == MOUSE_LEFT then
		self:DoClick(self.m_iID)
	end
	if mcode == MOUSE_RIGHT then
		self:DoRightClick(self.m_iID, self)
	end
	if mcode == MOUSE_LEFT && self.m_bDoubleClicking then
		if ( delta && SysTime() - delta < 0.2 ) then
			self:DoDoubleClickInternal(self)
			self:DoDoubleClick(self.m_iID, self)
			return
		end
		delta = SysTime()
	end

end

function PANEL:DoClick(indexID)
end

function PANEL:DoRightClick(indexID, self)
end

function PANEL:DoDoubleClickInternal(line)
end

function PANEL:DoDoubleClick(index, line)
end

function PANEL:SetSelected( b )

	self.m_bSelected = b
	for id, column in pairs( self.Columns ) do
		column:ApplySchemeSettings()
	end

end

function PANEL:IsLineSelected()
	return self.m_bSelected
end

function PANEL:SetColumnText( i, strText )

	if ( type( strText ) == "Panel" ) then

		if ( IsValid( self.Columns[ i ] ) ) then self.Columns[ i ]:Remove() end

		strText:SetParent( self )
		self.Columns[ i ] = strText
		self.Columns[ i ].Value = strText
		return

	end

	if ( !IsValid( self.Columns[ i ] ) ) then

		self.Columns[ i ] = vgui.Create( "DPureLabel", self )
		self.Columns[ i ]:SetWide(self:GetWide())
		self.Columns[ i ]:SetMouseInputEnabled( false )
		self.Columns[ i ]:SetFont(self.m_FontName)
		self.Columns[ i ]:SetTextColor(self.col)
	end

	self.Columns[ i ]:SetText( tostring( strText ) )
	self.Columns[ i ].Value = strText
	return self.Columns[ i ]

end

function PANEL:GetColumnText( i )
	if ( !self.Columns[ i ] ) then return "" end
	return self.Columns[ i ].Value

end

function PANEL:PerformLayout()
end

derma.DefineControl( "DBetterLine", "A better line from the BetterListView", PANEL, "Panel" )
