local PANEL = {}

Derma_Hook( PANEL, "Paint", "Paint", "MenuBar" )

local colorServerState = Color(255, 150, 0, 255)

function PANEL:Init()
	self.missing = false
	self:SetVisible(false)
	self.length = ""
    self.enabled = true

	self.title = vgui.Create("DLabel",self)
	self.title:SetText("")
	self.title:SetContentAlignment(5) -- center
	self.title:Dock(FILL)

	self.seek = vgui.Create("DLabel",self)
	self.seek:SetTextColor(Color(255, 255, 255))
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

function PANEL:GetEnabled()
    return self.enabled
end
function PANEL:SetEnabled(bool)
    self.enabled = bool
end

function PANEL:SizeToContents()
	self:InvalidateLayout(true)
end

function PANEL:IsMissing()
	-- local tmp = self.missing
	-- self.missing = false
	return self.missing
end

function PANEL:SetMissing( bool )
	self.missing = bool
end

function PANEL:SetFont( font )
	self.title:SetFont(font)
	self.seek:SetFont(font)
end

function PANEL:SetColor( color )
	self.title:SetColor(color)
	self.seek:SetColor(color)
end

function PANEL:GetTextColor()
	return self.title:GetColor()
end

function PANEL:SetTextColor( color )
	self.title:SetColor(color)
end

function PANEL:SetText( title )
	if isbool(title) then
		title = "gMusic Player"
		self.seek:SetVisible(false)
	elseif not self.seek:IsVisible() then
		self.seek:SetVisible(true)
	end
	self.title:SetText(title)
	self.title:SizeToContents()
end

function PANEL:SetSeekTime( timeFloat )
	self.seek:SetText(string.ToMinutesSeconds(timeFloat) .. " : " .. self.length)
	self.seek:SizeToContents()
end

function PANEL:SetSeekEnabled(bool)
	self.seek:SetVisible(bool)
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

function PANEL:DoM4Click()
	-- override
end
function PANEL:DoRightLeftClick()
	-- override
end


function PANEL:OnMouseReleased( mousecode )
	if mousecode == MOUSE_LEFT then
		self:DoClick()
	elseif mousecode == MOUSE_RIGHT then
		self:DoRightClick()
	elseif mousecode == MOUSE_MIDDLE then
		self:DoMiddleClick()
	elseif mousecode == MOUSE_4 then
		self:DoM4Click()
	end
end



function PANEL:Think()	-- doesn't run if not visible
	if self:GetEnabled() then
		self:OnThink()
	end
end

function PANEL:OnThink()
	-- override
end

function PANEL:PaintOver(w, h)
	if not self:GetEnabled() then
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(0, 0, w, h-1)
	elseif self:IsHovered() then
		surface.SetDrawColor(50, 50, 50, 100)
		surface.DrawRect(0, 0, w, h-1)
	end
end

derma.DefineControl( "DMultiButton", "A Button with multiple buttons", PANEL, "Panel" )