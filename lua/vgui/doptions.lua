
local PANEL = {}
AccessorFunc(PANEL, "m_bDefFont", "DefaultFont", FORCE_BOOL)
AccessorFunc( PANEL, "m_bSizeToContents",	"AutoSize", FORCE_BOOL)

local itemCount = 0
local categCount = 0

local bgHeader = Color(20, 150, 240)
local textColor = Color(0, 0, 0)

function PANEL:Init()

	self.Categories = {}
	self.Items = {}

	self:SetMouseInputEnabled( true )
	self:SetKeyboardInputEnabled( true )
	self:SetDefaultFont("default")

	self.panel = vgui.Create( "Panel", self )

	self.VBar = vgui.Create( "DSimpleScroll", self )
	self.VBar:SetZPos( 20 )
	self.VBar.Paint = function(panel, w, h)
		surface.SetDrawColor(120, 120, 120)
		surface.DrawRect(0, 0, w, h)
	end

	self.VBar.btnGrip.Paint = function(panel, w, h)
		surface.SetDrawColor(bgHeader)
		surface.DrawRect(0, 0, w, h)
	end

end

function PANEL:RefreshLayout(w, h)
	self:SetSize(w, h)
	self.VBar:SetScroll(self.VBar:GetScroll())
	for k, line in pairs(self.Categories) do
		self.Categories[k]:SetWide(w)
	end
end

function PANEL:RefreshCategoryLayout(w)
	self.VBar:SetScroll(self.VBar:GetScroll())
	for k, line in pairs(self.Categories) do
		self.Categories[k]:SetWide(w)
	end
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
	for k, checkbox in pairs( self.Items ) do
		checkbox:SetIsAdmin(isAdmin)
		checkbox:UpdateThink()
		checkbox:SetIsAdmin(nil)
	end
end


function PANEL:Category( strLabel )
	local cat = vgui.Create( "DLabel", self.panel )
	cat:SetPos(0, itemCount + categCount)
	cat:SetWide(self:GetWide())
	cat:SetContentAlignment(5)
	cat:SetFont(self:GetDefaultFont())
	cat:SetTextColor(Color(255, 255, 255))
	cat:SetText(strLabel)
	cat.Paint = function(panel, w, h)
		surface.SetDrawColor(20, 150, 240)
		surface.DrawRect(0, 0, w, h)
	end

	categCount = categCount + 6
	itemCount = itemCount + cat:GetTall() + categCount
	table.insert( self.Categories, cat )

	return cat
end


function PANEL:CheckBox( isChecked, strLabel, adminOnly )
	local left = vgui.Create( "DBetterCheckBoxLabel", self.panel )
	left:SetPos(8, itemCount)
	left:SetFont(self:GetDefaultFont())
	left:SetChecked(isChecked)
	left:SetAdminOnly(adminOnly)
	left:SetTextColor(textColor)
	left:SetText( strLabel )

	itemCount = itemCount + left:GetTall()
	table.insert( self.Items, left )

	return left
end


function PANEL:MultiCheckBox( nrChecked, strLabel, adminOnly, optionNumber )
	local multiCheck = vgui.Create( "Panel", self.panel )
	multiCheck:SetPos(8, itemCount)

	local left = vgui.Create( "DBetterCheckBoxLabel", multiCheck )
	left.Toggle = function() end
	left.box:SetVisible(false)
	left.label:SetPos(0, 0)
	left:SetFont(self:GetDefaultFont())
	left:SetAdminOnly(adminOnly)
	left:SetTextColor(textColor)
	left:SetText( strLabel )

	multiCheck:SetSize(left:GetWide() + 100, 40)

	if optionNumber then
		for i = 1, optionNumber do
			local option = vgui.Create( "DBetterCheckBoxLabel", multiCheck )
			option:SetID(i)
			option.box.DoClick = option.box.ToggleOne
			option.Toggle = option.ToggleOne
			left:addCheckbox(i, option)
			option:SetFont(self:GetDefaultFont())
			option:SetTextColor(textColor)
			option.y = 20
		end
		if nrChecked then
			if !isnumber(nrChecked) then nrChecked = 1 end
			left.box.child[tonumber(nrChecked)]:SetChecked(true)
		end

		 for k,optionCheckbox in pairs(left.box.child) do
			optionCheckbox.box.child = left.box.child
		 end
	end

	itemCount = itemCount + multiCheck:GetTall()
	table.insert( self.Items, left )

	return left, left.box.child
end

function PANEL:Rebuild()
end

function PANEL:OnMouseWheeled( dlta )
	if ( !IsValid( self.VBar ) ) then return end
	return self.VBar:OnMouseWheeled( dlta )
end

function PANEL:PerformLayout(w, h)
	local YPos = 0

	if IsValid( self.VBar ) then
		self.VBar:SetPos( w - 16, 0 )
		self.VBar:SetSize( 16, h)
		self.VBar:SetUp( self.VBar:GetTall(), self.panel:GetTall() )

		YPos = self.VBar:GetOffset()
		self.VBar:InvalidateLayout()
	end

	if self.VBar.Enabled then
		self.panel:SetSize( w - 16, itemCount )
	else
		self.panel:SetSize( w, itemCount )
	end

	self.panel:SetPos( 0, YPos )
end

function PANEL:UpdateColors(bgHead, bgCol, textCol)
	bgHeader = bgHead
	bgColor = bgCol
	textColor = textCol

	for k,line in pairs(self.Lines) do
		line:SetTextColor(textColor)
	end
	for k,column in pairs(self.Columns) do
		column.Paint(column, column:GetWide(), column:GetTall())
	end
	self.VBar.btnGrip.Paint(self.VBar.btnGrip, self.VBar.btnGrip:GetWide(), self.VBar.btnGrip:GetTall())
	self.panelLine.Paint(self.panelLine, self.panelLine:GetWide(), self.panelLine:GetTall())
end

derma.DefineControl( "DOptions", "Settings Page", PANEL, "Panel" )
