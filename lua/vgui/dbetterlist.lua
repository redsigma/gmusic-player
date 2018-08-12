local PANEL = {}
local linePos = 0
local prevSelect = nil

local bgHeader = Color(20, 150, 240)
local bgColor = Color(255, 255, 255)
local textColor = Color(255, 255, 255)

AccessorFunc( PANEL, "m_bDirty", "Dirty", FORCE_BOOL )
AccessorFunc( PANEL, "m_bSortable", "Sortable", FORCE_BOOL )

AccessorFunc( PANEL, "m_FontName", "Font" )
AccessorFunc( PANEL, "m_iHeaderHeight", "HeaderHeight" )
AccessorFunc( PANEL, "m_iDataHeight", "DataHeight" )

AccessorFunc( PANEL, "m_bHideHeaders", "HideHeaders" )

Derma_Hook( PANEL, "Paint", "Paint", "ListView" )

function PANEL:Init()
	self.m_FontName = "default"
	self.sort = false
	self.selectedK = nil
	self.m_iHeaderHeight = 0

	self:SetSortable( true )
	self:SetMouseInputEnabled( true )
	self:SetHideHeaders( false )

	self:SetHeaderHeight( 16 )
	self:SetDataHeight( 20 )

	self.Columns = {}
	self.Lines = {}

	self:SetDirty( true )

	self.panelLine = vgui.Create( "Panel", self )
	self.panelLine.Paint = function(panel, w, h)
		surface.SetDrawColor( bgColor )
		surface.DrawRect( 0, 0, w, h )
	end

	self.VBar = vgui.Create( "DSimpleScroll", self )
	self.VBar:SetZPos( 20 )
	self.VBar.Paint = function(panel, w, h)
		surface.SetDrawColor(120, 120, 120)
		surface.DrawRect(0, 0, w, h)
	end

	self.VBar.btnGrip.Paint = function(panel, w, h)
		surface.SetDrawColor(bgHeader)
		surface.DrawRect(0, 0, w, h)
	end

end

function PANEL:RefreshLayout(w, h)
	self:SetSize(w, h)
	self.VBar:SetScroll(self.VBar:GetScroll())
	for k, line in pairs(self.Lines) do
		self.Lines[k]:SetWide(w)
		self.Lines[k].Columns[0]:SetWide(w)
	end
end

function PANEL:SetHeaderHeight(val)
	self.m_iHeaderHeight = val
end
function PANEL:GetHeaderHeight()
	return self.m_iHeaderHeight
end

function PANEL:SetHideHeaders(bool)
	self.m_bHideHeaders = bool
	if bool then
		self.m_iHeaderHeight = 0
	end
end

function PANEL:DisableScrollbar()
	if IsValid( self.VBar) then
		self.VBar:Remove()
	end

	self.VBar = nil
end

function PANEL:ResetColor(index)
	self.Lines[index]:SetTextColor(textColor)
end

function PANEL:HighlightLine(index, color, txtcolor)
	if txtcolor then
		self.Lines[index]:SetTextColor(txtcolor)
	end
	if color then
		self.Lines[index].Paint = function(panel, w, h)
			surface.SetDrawColor(color)
			surface.DrawRect(0, 0, w, h)
		end
	else
		self.Lines[index].Paint = function() end
	end
end

function PANEL:GetLines()
	return self.Lines
end

function PANEL:AddColumn( strName )
	if self.m_bHideHeaders then return end

	local pColumn = vgui.Create( "DBetterColumn", self )
	pColumn:SetTall(self.m_iHeaderHeight)
	pColumn.Paint = function(panel, w, h)
		surface.SetDrawColor(bgHeader)
		surface.DrawRect(0, 0, w, h)
	end
	pColumn:SetText(strName)
	pColumn:SetTextColor(Color(255, 255, 255))
	pColumn:SetContentAlignment( 5 )
	pColumn.DoClick = function(panel)
		self.sort = !self.sort
		self:SetDirty(true)
	end
	pColumn:Dock(TOP)


	table.insert( self.Columns, pColumn )

	self:InvalidateLayout()

	return pColumn
end

function PANEL:RemoveLine( LineID )
	local Line = self:GetLine( LineID )

	self.Lines[ LineID ] = nil

	self:SetDirty( true )
	self:InvalidateLayout()

	Line:Remove()
end

function PANEL:ColumnWidth( i )
	local ctrl = self.Columns[ i ]
	if ( !ctrl ) then return 0 end

	return ctrl:GetWide()

end

function PANEL:FixColumnsLayout()
	local colHeight = self:GetDataHeight()
	local NumLines = #self.Lines + 1

	if ( NumColumns == 0 ) then return end

	local posY = 0

	if self.sort then
		for k, line in pairs(self.Lines) do
			self.Lines[NumLines - k]:SetPos(0, posY)
			posY = posY + colHeight
		end
	else
		for k, line in pairs(self.Lines) do
			self.Lines[k]:SetPos(0, posY)
			posY = posY + colHeight
		end
	end
end


function PANEL:PerformLayout(w, h)
	local Tall = 0
	local YPos = 0

	if IsValid( self.VBar ) then
		self.VBar:SetPos( w - 16, 0 )
		self.VBar:SetSize( 16, h)
		self.VBar:SetUp( self.VBar:GetTall(), self.panelLine:GetTall() + self:GetHeaderHeight() )

		YPos = self.VBar:GetOffset()
		self.VBar:InvalidateLayout()
	end

	if self.m_bHideHeaders then
		Tall = YPos
	else
		Tall = YPos + self:GetHeaderHeight()
	end

	if self.VBar.Enabled then
		self.panelLine:SetSize( w - 16, linePos )
	else
		self.panelLine:SetSize( w, linePos )
	end

	self.panelLine:SetPos( 0, Tall )

	if self:GetDirty() then
		self:SetDirty( false )
		self:FixColumnsLayout()
	end

end

function PANEL:Think()
	if self:GetDirty() then
		self:InvalidateLayout()
	end
end

function PANEL:OnScrollbarAppear()
	self:SetDirty( true )
	self:InvalidateLayout()
end

function PANEL:AddLine( strLine )
	self:SetDirty( true )
	self:InvalidateLayout()

	local Line = vgui.Create( "DBetterLine", self.panelLine )
	Line:SetFont(self.m_FontName)
	Line:SetTextColor(textColor)
	Line.BeforeMousePress = function(panel, index)
		self:BeforeMousePress(index)
	end
	Line.DoClick = function(panel, index)
		if IsValid(self.Lines[prevSelect]) then
			self.Lines[prevSelect]:SetSelected(false)
		end
		prevSelect = index
		self:DoClick(index)
	end
	Line.DoRightClick = function(panel, index, line)
		self:DoRightClick(index, line)
	end
	Line.DoDoubleClickInternal = function(panel, line)
		self:BeforeDoubleClick(line)
	end
	Line.DoDoubleClick = function(panel, index, line)
		self.selectedK = index
		self:DoDoubleClick(index, line)
	end

	Line:SetTall(self.m_iDataHeight)
	Line:SetWide(self:GetWide())

	Line:SetPos(0, linePos)
	linePos = linePos + self.m_iDataHeight

	Line:SetColumnText( 0, strLine )

	local indexID = table.insert( self.Lines, Line )
	Line:SetID( indexID )

	return Line
end

function PANEL:OnMouseWheeled( dlta )
	if ( !IsValid( self.VBar ) ) then return end
	return self.VBar:OnMouseWheeled( dlta )
end

function PANEL:GetSelectedLine()
	-- for k, Line in pairs( self.Lines ) do
	-- 	if Line:IsSelected() then return k end
	-- end
	return self.selectedK
end

function PANEL:GetLine( id )
	return self.Lines[ id ]
end

function PANEL:BeforeMousePress( index )
end

function PANEL:DoClick( index )
end

function PANEL:DoRightClick( index, line )
end

function PANEL:BeforeDoubleClick( line )
end

function PANEL:DoDoubleClick( index, line )
end

function PANEL:Clear()
	for k, v in pairs( self.Lines ) do
		v:Remove()
	end

	linePos = 0
	self.Lines = {}
	self:SetDirty( true )
end

function PANEL:GetSelected()

	local ret = {}

	for k, v in pairs( self.Lines ) do
		if ( v:IsLineSelected() ) then
			table.insert( ret, v )
		end
	end

	return ret

end

function PANEL:SizeToContents()
	self:SetHeight( self.panelLine:GetTall() + self:GetHeaderHeight() )
end

function PANEL:GetLineColor()
	return textColor
end

function PANEL:UpdateColors(bgHead, bgCol, textCol)
	bgHeader = bgHead
	bgColor = bgCol
	textColor = textCol

	for k,line in pairs(self.Lines) do
		line:SetTextColor(textColor)
	end
	for k,column in pairs(self.Columns) do
		column.Paint(column, column:GetWide(), column:GetTall())
	end
	self.VBar.btnGrip.Paint(self.VBar.btnGrip, self.VBar.btnGrip:GetWide(), self.VBar.btnGrip:GetTall())
	self.panelLine.Paint(self.panelLine, self.panelLine:GetWide(), self.panelLine:GetTall())
end

derma.DefineControl( "DBetterListView", "Better List", PANEL, "Panel" )