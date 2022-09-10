local paintMethod = {}
local headerColor = { hue = 0, sat = 0, bright = 0 }
local panelColor = { hue = 0, sat = 0, bright = 0 }

local function init(skinTable)
for skinIndex,skins in pairs(skinTable) do

	headerColor.hue, headerColor.sat, headerColor.bright = ColorToHSV(skins.GwenTexture:GetColor(350,370))
	panelColor.hue, panelColor.sat, panelColor.bright = ColorToHSV(skins.GwenTexture:GetColor(140,10))
	break;
end

return paintMethod
end

local function getColors()
	local colors = {}

  local threshold_dark_mode = 0.5
  local has_white_theme = panelColor.bright < threshold_dark_mode or headerColor.bright < threshold_dark_mode

  colors.fallback_text = Color(255, 255, 255)

  if has_white_theme then
    colors.bg = Color(20, 150, 240)
    colors.text = Color(0, 0, 0)
    colors.bglist = Color(255, 255, 255)
    colors.slider = Color(0, 0, 0, 100)
  else
    colors.bg = Color(15, 110, 175)
    colors.text = Color(255, 255, 255)
    colors.bglist = Color(35, 35, 35)
    colors.slider = Color(0, 0, 0, 100)
  end

	return colors
end

local function paintBaseList(panel)
	panel.Paint = function(self, w, h)
		surface.SetDrawColor( getColors().bglist )
		surface.DrawRect( 0, 0, w, h )
	end
end

local function paintHoverBG(panel)
	panel.PaintOver = function(self, w, h)
		if panel:IsHovered() then
			surface.SetDrawColor( Color(255, 255, 255, 50) )
			surface.DrawRect( 0, 0, w, h )
		end
	end
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
	local colorText = getColors().text

	panel:UpdateColors(bgColor, bgList, colorText)

end

local function paintOptions(panel)
	local bgColor = getColors().bg
	local colorText = getColors().text
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
	panel:SetTextColor(getColors().fallback_text)
	panel.Paint = function() end
end

local function paintSlider(panel)
	panel:SetSliderColor(getColors().slider)
	panel:SetTextColor(getColors().fallback_text)
	panel.Slider.Paint(panel.Slider, panel.Slider:GetWide(), panel.Slider:GetTall())
end

local function paintText(panel)
	panel:SetTextColor(getColors().text)
end

local function paintDisabled(panel)
	panel.Paint = function() end
end

paintMethod.setBGHover		=	paintHoverBG
paintMethod.setDisabled 	=	paintDisabled
paintMethod.paintButton 	=	paintButton
paintMethod.paintSlider 	=	paintSlider
paintMethod.paintBase 		=	paintBase
paintMethod.paintBaseList 	=	paintBaseList
paintMethod.paintList 		=	paintList
paintMethod.paintDoubleList =	paintDoubleList
paintMethod.paintOptions 	=	paintOptions
paintMethod.paintText 		=	paintText
paintMethod.getColors 		=	getColors
return init