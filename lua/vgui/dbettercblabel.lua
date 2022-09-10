local PANEL = {}

AccessorFunc(PANEL, "m_bInactive", "Inactive", FORCE_BOOL)
AccessorFunc( PANEL, "m_bEnabled",	"Enabled" )
AccessorFunc( PANEL, "m_Text",	"Text" )

local childPos = 0

function PANEL:Init()
	self.cvarText = ""
	self:SetTall( 16 )

	self.box = vgui.Create( "DBetterCheckBox", self )

	self.box.BeforeChange = function( panel )
		self:BeforeChange()
	end

	self.box.BeforeConvarChanged = function( panel, val)
		if self.box:GetAdminOnly() then
			if self.box:GetIsAdmin() then
				self:BeforeConvarChanged(val)
			end
		else
			self:BeforeConvarChanged(val)
		end
	end

	self.box.AfterConvarChanged = function( panel, val)
		if self.box:GetAdminOnly() then
			if self.box:GetIsAdmin() then
				self:AfterConvarChanged(val)
			end
		else
			self:AfterConvarChanged(val)
		end
	end

	self.box.AfterChange = function( panel, val )
		self:AfterChange(val)
	end

	self.box.Paint = function(panel, w, h)
		if panel:GetChecked() then
			surface.SetDrawColor( 0, 255, 0 )
		else
			surface.SetDrawColor( 255, 255, 255 )
		end
		surface.DrawRect( 0, 0, w, h-1 )
	end
	self.box.PaintOver = function(panel, w, h)
		surface.SetDrawColor( 16, 16, 16 )
		surface.DrawOutlinedRect( 0, 0, w, h-1 )
		if panel:GetDisabled() then
			surface.SetDrawColor( 0, 0, 0, 200 )
			surface.DrawRect( 0, 0, w, h-1 )
		end
	end

	self.m_bInactive = false

	self.label = vgui.Create( "DLabel", self )
	self.label:SetPos(self.box:GetWide() + 8, -2 )
	self.label:SetMouseInputEnabled( true )
	self.label.DoClick = function() self:Toggle() end
end

function PANEL:SetEnabled( bEnabled )
	self.m_bEnabled = bEnabled
	if bEnabled then
		self:SetAlpha( 255 )
		self:SetMouseInputEnabled( true )
	else
		self:SetAlpha( 75 )
		self:SetMouseInputEnabled( false )
	end


end
function PANEL:IsEnabled()
	return self.m_bEnabled
end

function PANEL:SetPos(x, y)
	self.x = x
	self.y = y
	self:SizeToContents()
end

function PANEL:AllowContinue(bool)
	self.box:SetBeforeBool(bool)
end

function PANEL:BeforeConvarChanged(val)
end

function PANEL:AfterConvarChanged(val)
end

function PANEL:BeforeChange()
	-- override before a value has changed. must return bool to continue
	-- must set the AllowContinue method
end

function PANEL:AfterChange( bool )
	-- override after a value has changed
end

function PANEL:GetbID()
	return self.box:GetbID()
end

function PANEL:SetAdminOnly( bool )
	self.box:SetAdminOnly( bool )
end

function PANEL:SetCheckedSilent( val )
	self.box:SetCheckedSilent( val )
end

function PANEL:SetChecked( val )
	self.box:SetChecked( val )
end

function PANEL:GetChecked( val )
	return self.box:GetChecked()
end

function PANEL:DoClick()
	self.box:Toggle()
end


function PANEL:ToggleOne()
	self.box:ToggleOne()
end

function PANEL:Toggle()
	if not self.box:GetDisabled() then
		self.box:Toggle()
	end
end

function PANEL:SizeToContents()
	self:InvalidateLayout( true ) -- update DLabel and the X
	self:SetWide( self.label.x + self.label:GetWide() )
	self:SetTall( self.box:GetTall() + 4 )
	self:InvalidateLayout() -- update the children
end

function PANEL:PerformLayout()
	self.label:SizeToContents()
end

function PANEL:SetTextColor( color )
	self.label:SetTextColor( color )
end

function PANEL:SetText( text )
	self.m_Text = text
	self.label:SetText( text )
	self:SizeToContents()
end

function PANEL:GetText()
	return self.m_Text
end

function PANEL:SetFont( font )
	self.label:SetFont( font )
	self:SizeToContents()
end

function PANEL:SetInactive(bool)
	if bool then
		self.PaintOver = function(panel, w, h)
			surface.SetDrawColor(0,0,0,150)
			surface.DrawRect(self.box:GetWide(), 0, w + 6, self.box:GetTall() - 1)
		end
	else
		self.PaintOver = function() end
	end
	self.m_bInactive = bool
end

function PANEL:GetCheckedi(index)
	if self.box.child[index] then
		return self.box.child[index]:GetChecked()
	end
	return false
end

function PANEL:GetCvarText()
	return self.cvarText
end

function PANEL:SetConVar( strCvar, defVal, helpText ) -- defVal override default check of the checkbox
	local tmp = CreateClientConVar(strCvar , defVal, true, false, helpText)
	self.cvarText = strCvar

	self.box:SetConVar(strCvar)
	self.box:PersistConvar(tmp, true)
end

function PANEL:SetCustomConVar( strCvar, defVal, boolConvar, helpText ) -- defVal override default check of the checkbox
	local tmp = CreateClientConVar(strCvar , defVal, true, false, helpText)
	self.cvarText = strCvar

	cvars.AddChangeCallback( strCvar, function( convar , oldValue , newValue  )
		self:OnCustomCvarChange(tonumber(newValue))
		self:UpdateThink()
	end )
	self.box:PersistConvar(tmp, boolConvar)
end

function PANEL:OnCustomCvarChange(newValue)
end

function PANEL:OnToggleOnce(id)
	-- For override
end

function PANEL:SetIsAdmin(isAdmin)
	self.box:SetIsAdmin(isAdmin)
end

function PANEL:addCheckbox(index, checkbox)
	self.box:addCheckbox(index, checkbox)
end

function PANEL:SetID(val)
	self.box:SetID(val)
end

function PANEL:GetID()
	return self.box.id
end

function PANEL:UpdateSize()
	if IsValid(self.box.child[1]) then
		for k,checkbox in pairs(self.box.child) do
			if k == 1 then
				childPos = 8
			else
				childPos = childPos + 8 + self.box.child[k - 1]:GetWide()
			end
			checkbox.x = childPos
		end
	end
end


function PANEL:UpdateThink()
	self.box:ConVarNumberThink()
end

function PANEL:Paint()
end

derma.DefineControl( "DBetterCheckBoxLabel", "CheckboxCustomLabel", PANEL, "DPanel" )