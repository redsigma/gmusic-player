local PANEL = {}

function PANEL:Init()
	self.Offset = 0
	self.scroll = 0
	self.panelSize = 1
	self.barSize = 1

	self.btnGrip = vgui.Create( "DScrollBarGrip", self )

	self:SetSize( 15, 15 )
end

function PANEL:SetEnabled( b )

	if not b then
		self.Offset = 0
		self:SetScroll( 0 )
		self.HasChanged = true
	end

	self:SetMouseInputEnabled( b )
	self:SetVisible( b )

	if self.Enabled ~= b then

		self:GetParent():InvalidateLayout()

		if self:GetParent().OnScrollbarAppear then
			self:GetParent():OnScrollbarAppear()
		end

	end

	self.Enabled = b
end

function PANEL:Value()
	return self.Pos
end

function PANEL:BarScale()

	if self.barSize == 0 then return 1 end

	return self.barSize / ( self.panelSize + self.barSize )

end

function PANEL:SetUp( _barsize_, _canvassize_ )

	self.barSize = _barsize_
	self.panelSize = math.max( _canvassize_ - _barsize_, 1 )

	self:SetEnabled( _canvassize_ > _barsize_ )

	self:InvalidateLayout()

end

function PANEL:OnMouseWheeled( dlta )

	if not self:IsVisible() then return false end

	return self:AddScroll( dlta * -2 )

end

function PANEL:AddScroll( dlta )

	local OldScroll = self:GetScroll()

	dlta = dlta * 25
	self:SetScroll( self:GetScroll() + dlta )


	return OldScroll ~= self:GetScroll()

end

function PANEL:SetScroll( scrll )
	if ( not self.Enabled ) then return end

	self.scroll = math.Clamp( scrll, 0, self.panelSize )

	self:GetParent():InvalidateLayout()
end

function PANEL:GetScroll()
	if not self.Enabled then return 0 end
	return self.scroll
end

function PANEL:GetOffset()
	if not self.Enabled then return 0 end
	return self.scroll * -1
end

function PANEL:Think()
end

function PANEL:OnMouseReleased()
	self.Dragging = false
	self.DraggingCanvas = nil
	self:MouseCapture( false )

	self.btnGrip.Depressed = false
end

function PANEL:OnCursorMoved( x, y )
	if ( not self.Enabled ) then return end
	if ( not self.Dragging ) then return end

	y = y - self.HoldPos

	local TrackSize = self:GetTall() - self.btnGrip:GetTall()

	y = y / TrackSize

	self:SetScroll( y * self.panelSize )
end

function PANEL:Grip()
	if not self.Enabled then return end
	if self.barSize == 0 then return end

	self:MouseCapture( true )
	self.Dragging = true

	local x, y = self.btnGrip:ScreenToLocal( 0, gui.MouseY() )
	self.HoldPos = y

	self.btnGrip.Depressed = true

end

function PANEL:PerformLayout(w, h)
	local prevScroll = self:GetScroll()
	local Scroll = prevScroll / self.panelSize

	local BarSize = math.max( self:BarScale() * h, 30 )
	local Track = h - BarSize
	Track = Track + 1

	Scroll = Scroll * Track

	self.btnGrip:SetPos( 0, Scroll )
	self.btnGrip:SetSize( w, BarSize )
end

derma.DefineControl( "DSimpleScroll", "Another Scrollbar", PANEL, "Panel" )
