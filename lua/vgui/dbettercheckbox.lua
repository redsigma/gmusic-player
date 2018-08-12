local PANEL = {}

AccessorFunc( PANEL, "m_bChecked", "Checked", FORCE_BOOL )
AccessorFunc( PANEL, "m_bAdminOnly", "AdminOnly", FORCE_BOOL)
AccessorFunc( PANEL, "m_bFrekingBool", "BeforeBool", FORCE_BOOL)


Derma_Hook( PANEL, "Paint", "Paint", "CheckBox" )
Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "CheckBox" )
Derma_Hook( PANEL, "PerformLayout", "Layout", "CheckBox" )


Derma_Install_Convar_Functions( PANEL )

function PANEL:SetValue( val )
	if self:GetAdminOnly() then
		if self:GetIsAdmin() then
			if ( tonumber( val ) == 0 ) then val = 0 end
			val = tobool( val )

			self:SetChecked( val )
			self.m_bValue = val

			self:UpdateConVar()
		else
			self:RevertConVar()
		end
	else
		if ( tonumber( val ) == 0 ) then val = 0 end
		val = tobool( val )
		self:SetChecked( val )
		self.m_bValue = val

		self:UpdateConVar()
	end
end

function PANEL:Init()
	self.child = {}
	self.id = 0

	self.isAdmin = nil
	self:SetSize( 15, 15 )
	self:SetText( "" )
	self.bID = false
	self:SetBeforeBool(true)
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

function PANEL:AfterConvarChanged(val)
	-- override before convar has changed
end

function PANEL:PreAfterConvarChanged(val)
	self:AfterChange(val)
	self:Think()
	self:AfterConvarChanged(val)
end

function PANEL:PersistConvar( newCvar, booleanize )
	self.cvar = newCvar
	if !ConVarExists(self.cvar:GetName()) then
		self.cvar:SetInt(self.cvar:GetDefault())
	end
	if booleanize then
		cvars.AddChangeCallback( self.cvar:GetName(), function( convar , oldValue , newValue  )
			self:PreAfterConvarChanged(tobool(tonumber(newValue)))
		end )
	else
		cvars.AddChangeCallback( self.cvar:GetName(), function( convar , oldValue , newValue  )
			self:PreAfterConvarChanged(tonumber(newValue))
		end )
	end


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

function PANEL:SetCheckedSilent(bool)
	self.m_bChecked = bool
	self.bID = bool
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

function PANEL:BeforeChange()
	-- override before a value has changed
	-- must use the SetBeforeBool method to continue
end

function PANEL:BeforeConvarChanged(val)
end

function PANEL:SetChecked(bool)
	self:BeforeConvarChanged(bool)
	self.m_bChecked = bool
	self.bID = bool
end

function PANEL:GetbID()
	return self.bID
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
	self:BeforeChange()
	if self:GetBeforeBool() then
		if self:GetChecked() then
			self:SetValue( false )
		else
			self:SetValue( true )
		end
		self:AfterChange( self:GetChecked() )
	else
		self:SetBeforeBool(true) -- reset it after check to prevent glitches
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

	self:ConVarNumberThink()
end


derma.DefineControl( "DBetterCheckBox", "CheckboxCustom", PANEL, "DButton" )