local PANEL = {}

AccessorFunc( PANEL, "m_bDisabled",		"Disabled",			FORCE_BOOL )

Derma_Hook( PANEL, "Paint", "Paint", "MenuBar" )

local colorServerState = Color(255, 150, 0, 255)

function PANEL:Init()
	self:SetDisabled(false)
	self:SetVisible(false)
	self.length = ""

	self.title = vgui.Create("DLabel",self)
	self.title:SetText("")
	self.title:SetContentAlignment(5) -- center
    self.title:Dock(FILL)

    self.seek = vgui.Create("DLabel",self)
    self.seek:SetVisible(false)
    self.seek:SetContentAlignment(5) -- center
    self.seek:Dock(BOTTOM)
    self.seek.Paint = function(panel, w, h)
		surface.SetDrawColor(colorServerState)
		surface.DrawRect(0, 0, w, h-1)
	end
end


function PANEL:SetTSS( bool )
	if bool then
		colorServerState = Color(20, 150, 240, 255) -- server
	else
		colorServerState = Color(255, 150, 0, 255) -- client
	end
    self.seek.Paint = function(panel, w, h)
		surface.SetDrawColor(colorServerState)
		surface.DrawRect(0, 0, w, h-1)
	end
end

function PANEL:SetEnabled(bool)
	self:SetDisabled(!bool)
end

function PANEL:SizeToContents()
	self:InvalidateLayout(true)
end


function PANEL:SetFont( font )
	self.title:SetFont(font)
	self.seek:SetFont(font)
end

function PANEL:SetColor( color )
	self.title:SetColor(color)
	self.seek:SetColor(color)
end

function PANEL:SetTitleColor( color )
	self.title:SetColor(color)
end

function PANEL:SetTitle( title )
	if isbool(title) then
		title = "gMusic Player"
		self.seek:SetVisible(false)
	elseif !self.seek:IsVisible() then
		self.seek:SetVisible(true)
	end
	self.title:SetText(title)
	self.title:SizeToContents()
end

function PANEL:SetSeekTime( timeFloat )
	self.seek:SetText( string.ToMinutesSeconds(timeFloat) .. " : " .. self.length )
	self.seek:SizeToContents()
end

function PANEL:SetSeekLength( lengthFloat )
	self.length = string.ToMinutesSeconds(lengthFloat)
end

function PANEL:DoClick()
	-- override
end

function PANEL:DoRightClick()
	-- override
end

function PANEL:DoMiddleClick()
	-- override
end

-- function PANEL:OnMousePressed( mousecode ) -- before released, not used
-- end

function PANEL:OnMouseReleased( mousecode )
	if mousecode == MOUSE_LEFT then
		self:DoClick()
	elseif mousecode == MOUSE_RIGHT then
		self:DoRightClick()
	elseif mousecode == MOUSE_MIDDLE then
		self:DoMiddleClick()
	end
end



function PANEL:Think()	-- doesn't run if not visible
	if !self:GetDisabled() then
		self:OnThink()
	end
end

function PANEL:OnThink()
	-- override
end

function PANEL:PaintOver(w, h)
	if self:GetDisabled() then
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(0, 0, w, h-1)
	elseif self:IsHovered() then
		surface.SetDrawColor(50, 50, 50, 100)
		surface.DrawRect(0, 0, w, h-1)
	end
end

derma.DefineControl( "DMultiButton", "A Button with multiple buttons", PANEL, "Panel" )