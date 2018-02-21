local PANEL = {}

AccessorFunc(PANEL, "m_bInactive", "Inactive", FORCE_BOOL)

function PANEL:Init()
	self:SetTall( 16 )

	self.box = vgui.Create( "DBetterCheckBox", self )
	self.box.BeforeChange = function( panel )
		self:BeforeChange()
	end

	self.box.BeforeConvarChanged = function( panel, val)
		self:BeforeConvarChanged(val)
	end	

	self.box.AfterConvarChanged = function( panel, val)
		self:AfterConvarChanged(val)
	end

	self.box.AfterChange = function( panel, val )
		self:AfterChange(val)
	end

	self.box.Paint = function(self, w, h)
		if self:GetChecked() then
			surface.SetDrawColor( 0, 255, 0 ) 
		else						
			surface.SetDrawColor( 255, 255, 255 ) 
		end
		surface.DrawRect( 0, 0, w, h-1 )
	end
	self.box.PaintOver = function(self, w, h)
		surface.SetDrawColor( 16, 16, 16 )
		surface.DrawOutlinedRect( 0, 0, w, h-1 )
		if self:GetDisabled() then 	
			surface.SetDrawColor( 0, 0, 0, 200 ) 
			surface.DrawRect( 0, 0, w, h-1 )
		end
	end

	self.label = vgui.Create( "DLabel", self )
	self.label:SetPos(self.box:GetWide()+8, -2 )
	self.label:SetMouseInputEnabled( true )
	self.label.DoClick = function() self:Toggle() end
end

function PANEL:SetPos(x, y)
	self.box:SetPos(x,y)
	self.label:SetPos(self.box:GetWide()+8+x, -2)
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
	-- must set the AllowContinue method cuz freking gmod doesn't know the way ( aka return true didn't worked) 
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

function PANEL:SetValue( val )
	self.box:SetValue( val )
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

function PANEL:Toggle()
	if !self.box:GetDisabled() then
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
	self.label:SetText( text )
	self:SizeToContents()
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

function PANEL:GetText()
	return self.label:GetText()
end


function PANEL:SetConVar( strCvar, defVal, helpText ) -- defVal override default check of the checkbox
	local tmp = CreateClientConVar(strCvar , defVal, true, false, helpText)

	self.box:SetConVar(strCvar)
	self.box:PersistConvar(tmp)
end

function PANEL:SetIsAdmin(isAdmin)
	self.box:SetIsAdmin(isAdmin)
end

function PANEL:UpdateThink()
	self.box:ConVarNumberThink()
end

function PANEL:Paint()
end

derma.DefineControl( "DBetterCheckBoxLabel", "CheckboxCustomLabel", PANEL, "DPanel" )