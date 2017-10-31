local PANEL = {}
AccessorFunc(PANEL, "m_bIsMenuComponent", "IsMenu", FORCE_BOOL)
AccessorFunc(PANEL, "m_bDraggable", "Draggable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bSizable", "Sizable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bScreenLock", "ScreenLock", FORCE_BOOL)
AccessorFunc(PANEL, "m_iMinWidth", "MinWidth")
AccessorFunc(PANEL, "m_iMinHeight", "MinHeight")

function PANEL:Init()
	self:SetSize(100, 100)
	self:SetFocusTopLevel(false)
	self:SetCursor("sizeall")
	self.buttonClose = vgui.Create("DButton", self)
	self.buttonClose:SetFont("default")
	self.buttonClose:SetText("X")
	self.buttonClose:SetSize(20, 20)
	self.buttonClose:SetTextColor(Color(255, 255, 255))

	self.buttonClose.DoClick = function(button)
		self:Close()
	end

	self.buttonClose.Paint = function(panel, w, h)
		surface.SetDrawColor(255, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)
	end

	self.labelTitle = vgui.Create("DLabel", self)
	self.labelTitle:SetPos(0, 0)
	self.labelTitle:SetFont("default")
	self.labelTitle:SetTextColor(Color(255, 255, 255))

	self.labelTitle.Paint = function()
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawRect(0, 0, self.labelTitle:GetWide(), self.labelTitle:GetTall())
	end

	self:SetDraggable(true)
	self:SetSizable(true)
	self:SetScreenLock(false)

	self:SetTitle("Window")
	self:SetMinWidth(300)
	self:SetMinHeight(200)

	-- This turns off the engine drawing
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)

	self:DockPadding(0, 0, 0, 0)
end

function PANEL:SetBGColor(r, g, b)
	self.labelTitle.Paint = function()
		surface.SetDrawColor(r, g, b, 255)
		surface.DrawRect(0, 0, self.labelTitle:GetWide(), self.labelTitle:GetTall())
	end
end

function PANEL:SetSizeDynamic(width, height)
	if (ScrW() < 1024) then
		self:SetSize(ScrW() - width, height)
	else
		self:SetSize(ScrW() - 120, 400)
	end
end

function PANEL:ShowCloseButton(bShow)
	self.btnClose:SetVisible(bShow)
end

function PANEL:GetTitle()
	return self.labelTitle:GetText()
end

function PANEL:SetTitle(strTitle)
	self.labelTitle:SetText(strTitle)
end

function PANEL:Close()
	self:SetVisible(false)
	gui.EnableScreenClicker(false)
	self:OnClose()
end

function PANEL:OnClose()
end

function PANEL:Center()
	self:InvalidateLayout(true)
	self:CenterVertical()
	self:CenterHorizontal()
end

function PANEL:IsActive()
	if (self:HasFocus()) then
		return true
	end

	if (vgui.FocusedHasParent(self)) then
		return true
	end

	return false
end

function PANEL:Think()
	local mousex = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
	local mousey = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

	if (self.Dragging) then
		local x = mousex - self.Dragging[1]
		local y = mousey - self.Dragging[2]

		-- Lock to screen bounds if screenlock is enabled
		if (self:GetScreenLock()) then
			x = math.Clamp(x, 0, ScrW() - self:GetWide())
			y = math.Clamp(y, 0, ScrH() - self:GetTall())
		end

		self:SetPos(x, y)
	end

	if (self.Sizing) then
		local x = mousex - self.Sizing[1]
		local y = mousey - self.Sizing[2]
		local px, py = self:GetPos()

		if (x < self.m_iMinWidth) then
			x = self.m_iMinWidth
		elseif (x > ScrW() - px and self:GetScreenLock()) then
			x = ScrW() - px
		end

		if (y < self.m_iMinHeight) then
			y = self.m_iMinHeight
		elseif (y > ScrH() - py and self:GetScreenLock()) then
			y = ScrH() - py
		end

		self:SetSize(x, y)
		self:SetCursor("sizenwse")

		return
	end

	if (self.Hovered and self.m_bSizable and mousex > (self.x + self:GetWide() - 20) and mousey > (self.y + self:GetTall() - 20)) then
		self:SetCursor("sizenwse")

		return
	end

	if (self.Hovered and self:GetDraggable() and mousey < (self.y + 24)) then
		self:SetCursor("sizeall")

		return
	end

	self:SetCursor("arrow")

	-- Don't allow the frame to go higher than 0
	if (self.y < 0) then
		self:SetPos(self.x, 0)
	end
end

function PANEL:Paint(w, h)
	derma.SkinHook("Paint", "Frame", self, w, h)

	return true
end

function PANEL:OnMousePressed()
	if (self.m_bSizable and gui.MouseX() > (self.x + self:GetWide() - 20) and gui.MouseY() > (self.y + self:GetTall() - 20)) then
		self.Sizing = {gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall()}
		self:MouseCapture(true)

		return
	end

	if (self:GetDraggable() and gui.MouseY() < (self.y + 24)) then
		self.Dragging = {gui.MouseX() - self.x, gui.MouseY() - self.y}
		self:MouseCapture(true)

		return
	end
end

function PANEL:OnMouseReleased()
	self.Dragging = nil
	self.Sizing = nil
	self:MouseCapture(false)
end

function PANEL:PerformLayout()
	self.buttonClose:SetPos(self:GetWide() - self.buttonClose:GetWide(), 0)
	self.labelTitle:SetSize(self:GetWide() - 20, 20)
end

derma.DefineControl("DgMPlayerFrame", "Music Player", PANEL, "EditablePanel")
