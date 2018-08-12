local paintMethod = {}
local headerColor = {}
local panelColor = {}

local function init(skinTable)
for skinIndex,skins in pairs(skinTable) do

	headerColor.hue, headerColor.sat, headerColor.bright = ColorToHSV(skins.GwenTexture:GetColor(350,370))
	panelColor.hue, panelColor.sat, panelColor.bright = ColorToHSV(skins.GwenTexture:GetColor(140,10))
	break;
end

return paintMethod
end


local function paintBG(xpos, ypos, w, h, r, g, b, a)
	surface.SetDrawColor( r, g, b, a )
	surface.DrawRect( xpos, ypos, w, h )
end

local function paintHoverBG(panel)
	panel.PaintOver = function(self, w, h)
		if panel:IsHovered() then
			paintBG(0, 0, w, h, 255, 255, 255, 50)
		end
	end
end

local function getColors()
	local colors = {}

	if (panelColor.bright > 0.5 or headerColor.bright > 0.5) then
		colors.bg = Color(20, 150, 240)
		colors.text = Color(255, 255, 255)
		colors.chktext = Color(0, 0, 0)
		colors.bglist = Color(255, 255, 255)
		colors.slider = Color(0, 0, 0, 100)
	else
		colors.bg = Color(15, 110, 175)
		colors.text = Color(255, 255, 255)
		colors.chktext = Color(255, 255, 255)
		colors.bglist = Color(35, 35, 35)
		colors.slider = Color(0, 0, 0, 100)
	end

	return colors
end

local function paintBase(panel)
	local color = getColors().bg
	panel.Paint = function(self, w, h)
		surface.SetDrawColor( color )
		surface.DrawRect( 0, 0, w, h )
	end
end

local function paintList(panel)
	local bgColor = getColors().bg
	local bgList = getColors().bglist
	local colorText = getColors().chktext

	panel:UpdateColors(bgColor, bgList, colorText)

end

local function paintOptions(panel)
	local bgColor = getColors().bg
	local colorText = getColors().chktext
	local bgList = getColors().bglist

	panel.Paint = function(self, w, h)
		surface.SetDrawColor( bgList )
		surface.DrawRect( 0, 0, w, h )
		surface.SetDrawColor(bgColor)
		surface.DrawOutlinedRect( w-1, 0, w, h )
		surface.DrawOutlinedRect( 0, 0, w, 1 )
	end

	panel.VBar.btnGrip.Paint = function(self, w, h)
		surface.SetDrawColor(bgColor)
		surface.DrawRect(0, 0, w, h)
	end

	for k, checkbox in pairs( panel.Items ) do
		checkbox:SetTextColor(colorText)
	end
	for k, category in pairs( panel.Categories ) do
		category.Paint = function(self, w, h)
			surface.SetDrawColor(bgColor)
			surface.DrawRect(0, 0, w, h)
		end
	end
end

local function paintDoubleList(panel)
	local bgHead = getColors().bg
	local bgColor = getColors().bglist
	local colorText = getColors().text

	panel:UpdateColors(bgHead, bgColor, colorText)
end


local function paintButton(panel)
	panel:SetTextColor(getColors().text)
	panel.Paint = function() end
end

local function paintSlider(panel)
	panel:SetSliderColor(getColors().slider)
	panel:SetTextColor(getColors().text)
	panel.Slider.Paint(panel.Slider, panel.Slider:GetWide(), panel.Slider:GetTall())
end

local function paintText(panel)
	panel:SetTextColor(getColors().chktext)
end

local function paintDisabled(panel)
	panel.Paint = function() end
end

paintMethod.setBG 			=	paintBG
paintMethod.setBGHover		=	paintHoverBG
paintMethod.setDisabled 	=	paintDisabled
paintMethod.paintButton 	=	paintButton
paintMethod.paintSlider 	=	paintSlider
paintMethod.paintBase 		=	paintBase
paintMethod.paintList 		=	paintList
paintMethod.paintDoubleList =	paintDoubleList
paintMethod.paintOptions 	=	paintOptions
paintMethod.paintText 		=	paintText

return init