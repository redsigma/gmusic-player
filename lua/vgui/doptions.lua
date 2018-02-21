
local PANEL = {}
AccessorFunc(PANEL, "m_bDefFont", "DefaultFont", FORCE_BOOL)
AccessorFunc( PANEL, "m_bSizeToContents",	"AutoSize", FORCE_BOOL)
AccessorFunc( PANEL, "m_iSpacing",			"Spacing" )
AccessorFunc( PANEL, "m_Padding",			"Padding" )

function PANEL:Init()

	self.Items = {}

	self:SetSpacing( 4 )
	self:SetPadding( 10 )

	self:SetMouseInputEnabled( true )
	self:SetKeyboardInputEnabled( true )
	self:SetDefaultFont("default")
end

function PANEL:SetDefaultFont(font)
	self.m_bDefFont = font
end

function PANEL:Clear()
	for k, v in pairs( self.Items ) do
		if ( IsValid(v) ) then v:Remove() end
	end
	self.Items = {}
end

function PANEL:SyncItems(isAdmin)

	for k, v in pairs( self.Items ) do
		if isfunction(getmetatable(v).GetChild(v,0).GetbID) then
			getmetatable(v).GetChild(v,0):SetIsAdmin(isAdmin)
			getmetatable(v).GetChild(v,0):UpdateThink()
			getmetatable(v).GetChild(v,0):SetIsAdmin(nil)
		end
	end
end

function PANEL:AddItem( left, right )
	self:InvalidateLayout()

	local Panel = vgui.Create( "DSizeToContents", self )
	Panel:SetSizeX( false )
	Panel:Dock( TOP )
	Panel:InvalidateLayout()

	if ( IsValid( right ) ) then

		left:SetParent( Panel )
		left:InvalidateLayout( true )

		right:SetParent( Panel )
		right:SetPos( 110, 0 )
		right:InvalidateLayout( true )

	elseif ( IsValid( left ) ) then
		left:SetParent( Panel )

	end

	table.insert( self.Items, Panel )
end

function PANEL:Category( strLabel )
	local panelCat = vgui.Create( "Panel", self )
	panelCat:Dock(FILL)
	panelCat.Paint = function(panel, w, h)
		surface.SetDrawColor(20, 150, 240)
		surface.DrawRect(0, 0, w, h)
	end

	local cat = vgui.Create( "DLabel", panelCat )
	cat:SetFont(self:GetDefaultFont())
	cat:SetText(strLabel)
	cat:Dock(FILL)
	cat:SetContentAlignment(5)
	cat:SetColor(Color(255, 255, 255))

	self:AddItem( panelCat, nil )

	return cat
end


function PANEL:CheckBox( isChecked, strLabel, adminOnly ) -- strConVar not used for now
	local left = vgui.Create( "DBetterCheckBoxLabel", self )
	left:SetFont(self:GetDefaultFont())
	left:SetChecked(isChecked)
	left:SetAdminOnly(adminOnly)
	left:SetTextColor(Color(0,0,0))
	left:SetText( strLabel )
	left:Dock( LEFT )
	left:DockMargin( 10, 5, 0, 0 )

	self:AddItem( left, nil )

	return left
end


function PANEL:PanelSelect()
	local left = vgui.Create( "DPanelSelect", self )
	self:AddItem( left, nil )
	return left
end

function PANEL:Rebuild()
end

derma.DefineControl( "DOptions", "Settings Page", PANEL, "Panel" )
