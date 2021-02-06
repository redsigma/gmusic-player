local PANEL = {}

AccessorFunc( PANEL, "m_bChecked", "Checked", FORCE_BOOL )
AccessorFunc( PANEL, "m_bAdminOnly", "AdminOnly", FORCE_BOOL)

Derma_Hook( PANEL, "Paint", "Paint", "CheckBox" )
Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "CheckBox" )
Derma_Hook( PANEL, "PerformLayout", "Layout", "CheckBox" )

Derma_Install_Convar_Functions( PANEL )

function PANEL:SetValue( val )
	local bVal
	if isbool(val) then	bVal = val
	elseif isnumber(val) then bVal = tobool(val) end

	if self:GetAdminOnly() then
		if self:GetIsAdmin() then
			self:SetChecked( bVal )
			self.m_bValue = bVal

			self:UpdateConVar()
		else
			self:RevertConVar()
		end
	else
		self:SetChecked( bVal )
		self.m_bValue = bVal

		self:UpdateConVar()
	end
end

function PANEL:Init()
	self.child = {}
	self.id = 0

	self.isAdmin = nil
	self:SetSize( 15, 15 )
	self:SetText( "" )
	self.m_bChecked = false
	self.cvar = nil
end

function PANEL:addCheckbox(index, checkbox)
	self.id = index
	self.child[index] = checkbox
end

function PANEL:SetID(val)
	self.id = val
end

function PANEL:AfterChange( val )
	-- override after a value has changed
end

function PANEL:OnCvarWrong(oldValue, newValue)
	-- override if any problem happened
end

function PANEL:PersistConvar(newCvar)
	self.cvar = newCvar
	if !ConVarExists(self.cvar:GetName()) then
		self.cvar:SetInt(self.cvar:GetDefault())
	end
	cvars.AddChangeCallback( self.cvar:GetName(), function( convar , oldValue , newValue  )
		local tmp = tonumber(newValue)
		if isnumber(tmp) then
			self:OnCvarChange(oldValue, tmp)

			self:SetValue(tmp)
			self:AfterChange(tmp)
		else
			self:OnCvarWrong(oldValue, newValue)
		end
	end )
end


function PANEL:ConVarChanged(strNewValue)

	if ( !self.m_strConVar ) then return end
	RunConsoleCommand( self.m_strConVar, strNewValue )
end


function PANEL:UpdateConVar()
	if self:GetChecked() then
		self:ConVarChanged( "1" )
	else
		self:ConVarChanged( "0" )
	end
end

function PANEL:RevertConVar()
	if self:GetChecked() then
		self.cvar:SetString("1")
	else
		self.cvar:SetString("0")
	end
end


function PANEL:IsEditing()
	return self.Depressed
end

function PANEL:OnCvarChange(oldval, newval)
end

function PANEL:SetCheckedSilent(bool)
	self.m_bChecked = bool
end

function PANEL:SetChecked(bool)
	self.m_bChecked = bool
end

function PANEL:GetChecked()
	return self.m_bChecked
end

function PANEL:SetIsAdmin( isAdmin )
	self.isAdmin = isAdmin
end

function PANEL:GetIsAdmin()
	if isbool(self.isAdmin) then
		return self.isAdmin
	else
		return LocalPlayer():IsAdmin()
	end
end

function PANEL:DoClick()
	self:Toggle()
end

function PANEL:Toggle()
	if self:GetChecked() then
		self:SetValue( false )
	else
		self:SetValue( true )
	end
end
function PANEL:ToggleOne()
	for k,checkbox in pairs(self.child) do
		if k == self.id then
			self:Toggle()
			self:GetParent():GetParent():GetChildren()[1]:OnToggleOnce(self.id)
		else
			checkbox:SetCheckedSilent(false)
		end
	end
end

function PANEL:ConVarNumberThink()

	if ( !self.m_strConVar ) then -- if nil return false
	 return end

	local strValue = GetConVar(self.cvar:GetName()):GetInt()

	-- In case the convar is a "nan"
	if ( strValue != strValue ) then return end
	if ( self.m_strConVarValue == strValue ) then return end

	self.m_strConVarValue = strValue
	self:SetValue( self.m_strConVarValue )

end

function PANEL:Think()
	if self:IsVisible() then
		if self:GetAdminOnly() then
			if self:GetIsAdmin() then
				if self:GetDisabled() then self:SetEnabled(true) end
			else
				if !self:GetDisabled() then self:SetEnabled(false) end
			end
		end
	end

	-- self:ConVarNumberThink()
end


derma.DefineControl( "DBetterCheckBox", "CheckboxCustom", PANEL, "DButton" )