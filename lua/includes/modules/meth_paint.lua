local paintMethod = {}

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

local function paintDisabled(obj)
	obj.Paint = function() end
end

paintMethod.setBG 		=	paintBG
paintMethod.setBGHover	=	paintHoverBG
paintMethod.setDisabled =	paintDisabled

return paintMethod