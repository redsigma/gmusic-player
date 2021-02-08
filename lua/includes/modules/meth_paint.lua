--[[
    Painter used to color the panels. Color values are shared among all
    panels
--]]
local painter = {}
local white = Color(230, 230, 230)

local function change_theme(self, enable_dark_mode)
	if enable_dark_mode then
		self.colors.bg = Color(15, 110, 175)
		self.colors.bghover = Color(230, 230, 230, 50)
		self.colors.text = white
		self.colors.bglist = Color(35, 35, 35)
		self.colors.slider = Color(0, 0, 0, 100)
	else
		self.colors.bg = Color(20, 150, 240)
		self.colors.bghover = Color(30, 30, 30, 130)
		self.colors.text = Color(0, 0, 0)
		self.colors.bglist = Color(245, 245, 245)
		self.colors.slider = Color(0, 0, 0, 100)
	end

    self:OnUpdateUI()

	return self.colors
end

local function init()
    painter.colors = {}
    painter:change_theme(false)
    return painter
end

--[[
    Callback for custom use
--]]
local function OnUpdateUI(self)
end

local function paintBG(self, panel, color)
    local bg_color = self.colors.bg
	panel.Paint = function(self, w, h)
		if istable(color) then
			surface.SetDrawColor(color)
		else
			surface.SetDrawColor(bg_color)
		end
		surface.DrawRect( 0, 0, w, h )
	end
end

local function paintThemeBG(self, panel)
	self:paintBG(panel, self.colors.bglist)
end

local function paintHoverBG(self, panel, color)
	panel.PaintOver = function(self, w, h)
		if panel:IsHovered() then
			if istable(color) then
				surface.SetDrawColor(color)
			else
				surface.SetDrawColor(self.colors.bghover)
			end
			surface.DrawRect( 0, 0, w, h )
		end
	end
end

local function paintBGArea(self, panel, startx, starty, endx, endy)
	panel.Paint = function(self, w, h)
		surface.SetDrawColor(self.colors.bg)
		surface.DrawRect(startx, starty, endx, endy)
	end
end

local function paintHoverBGArea(self, panel)
	panel.PaintOver = function(self, w, h)
		if panel:IsHovered() then
			surface.SetDrawColor(self.colors.bghover)
			surface.DrawRect(startx, starty, endx, endy)
		end
	end
end

local function paintList(self, panel)
	panel:PaintList(self.colors.bglist)
end
local function paintHoverList(self, panel)
	panel:SetHoverBGColor(self.colors.bghover)
end

local function paintColumn(self, panel)
	panel:PaintColumn(self.colors.bg)
end

local function paintHoverColumn(self, panel, hoverColor)
	if istable(hoverColor) then panel:PaintHoverColumn(hoverColor)
	else panel:PaintHoverColumn(self.colors.bghover) end
end

local function paintScroll(self, panel, bgGrip, colorArrows)
	if istable(colorArrows) then
        panel:PaintScroll(self.colors.bg, bgGrip, colorArrows)
	else
        panel:PaintScroll(self.colors.bg, bgGrip, self.colors.text)
    end
end

local function paintSlider(self, panel)
	panel:SetSliderColor(self.colors.slider)
	panel:SetTextColor(white)
	panel.Slider.Paint(panel.Slider, panel.Slider:GetWide(), panel.Slider:GetTall())
end

local function paintText(self, panel)
    -- local set_inactive_color = panel.SetDefaultTexColor
    -- if set_inactive_color ~= nil then
    --     set_inactive_color(self, self.colors.text)
    -- end
	panel:SetTextColor(self.colors.text)
end

local function paintNone(self, table)
	if istable(table) then
		for _, panel in pairs(table) do
			panel.Paint = function() end
		end
	end
end

painter.change_theme		=	change_theme
painter.OnUpdateUI          =   OnUpdateUI
painter.paintNone 			=	paintNone

painter.paintSlider 		=	paintSlider
painter.paintThemeBG 		=	paintThemeBG
painter.paintScroll 		=	paintScroll

painter.paintBG 			=	paintBG
painter.paintHoverBG 		=	paintHoverBG
painter.paintBGArea 		=	paintBGArea
painter.paintHoverBGArea	=	paintHoverBGArea
painter.paintText 			=	paintText

painter.paintList 			=	paintList
painter.paintHoverList 		=	paintHoverList
painter.paintColumn 		=	paintColumn
painter.paintHoverColumn 	=	paintHoverColumn

return init
