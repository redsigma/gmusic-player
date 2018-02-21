local PANEL = {}

local leftList = {}
local rightList = {}

local midPanelH = 0
function PANEL:Init()

	self.midPanel = vgui.Create("Panel", self)
	self.midPanel:Dock(TOP)
	self.midPanel.Paint = function(panel, w, h)
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawOutlinedRect( 0, h-1, w, h )
	end
	midPanelH = self.midPanel:GetTall() - 1

	self.list1 = vgui.Create("DListView", self)
	self.list1:SetPos(0, self.midPanel:GetTall())
	self.list1:AddColumn( "Folders from ROOT" ).Header.Paint = function(panel, w, h)
		surface.SetDrawColor( 20, 150, 240, 255  )
		surface.DrawRect(0, 0, w, h)
		panel:SetFont("default")
		panel:SetTextColor(Color(255,255,255))
	end
	self.list1.OnRowRightClick = function(line, lineIndex)
		if self.list1:GetLine(lineIndex):IsSelected() then
			self.list1:GetLine(lineIndex):SetSelected(false)
		end
	end


	self.list2 = vgui.Create("DListView", self)
	self.list2:SetPos(self.list1:GetWide(), 0)
	self.list2:AddColumn( "Active Folders" ).Header.Paint = function(panel, w, h)
		surface.SetDrawColor( 20, 150, 240, 255  )
		surface.DrawRect(0, 0, w, h)
		panel:SetFont("default")
		panel:SetTextColor(Color(255,255,255))
	end
	self.list2.OnRowRightClick = function(line, lineIndex)
		if self.list2:GetLine(lineIndex):IsSelected() then
			self.list2:GetLine(lineIndex):SetSelected(false)
		end
	end

	self.btnRebuildMid = self.midPanel:Add("DButton")
	self.btnRebuildMid:SetSize(80, midPanelH)
	self.btnRebuildMid:SetFont("default")
	self.btnRebuildMid:SetTextColor(Color(255,255,255))
	self.btnRebuildMid:SetText("Rebuild List")
	self.btnRebuildMid.DoClick = function() self:OnButtonRebuild() end
	self.btnRebuildMid.Paint = function() end
	self.btnRebuildMid.Paint = function(panel, w, h)
		if self.btnRebuildMid:IsHovered() then
			surface.SetDrawColor(255, 255, 0, 255)
			surface.DrawRect(0, 0, w, h)
		end
	end

	self.btnAddMid = self.midPanel:Add("DButton")
	self.btnAddMid:SetFont("default")
	self.btnAddMid:SetTextColor(Color(255,255,255))
	self.btnAddMid:SetText("Add Folder")
	self.btnAddMid:SetPos(self.btnRebuildMid:GetWide(), 0)
	self.btnAddMid.DoClick = function() self:OnButtonAdd() end
	self.btnAddMid.Paint = function() end
	self.btnAddMid.Paint = function(panel, w, h)
		if self.btnAddMid:IsHovered() then
			surface.SetDrawColor(0, 255, 0, 255)
			surface.DrawRect(0, 0, w, h)
		end
	end

	self.btnRemMid = self.midPanel:Add("DButton")
	self.btnRemMid:SetFont("default")
	self.btnRemMid:SetTextColor(Color(255,255,255))
	self.btnRemMid:SetText("Remove Folder")
	self.btnRemMid.DoClick = function() self:OnButtonRem() end
	self.btnRemMid.Paint = function() end
	self.btnRemMid.Paint = function(panel, w, h)
		if self.btnRemMid:IsHovered() then
			surface.SetDrawColor(255, 150, 0, 255)
			surface.DrawRect(0, 0, w, h)
		end
	end
end

function PANEL:selectFirstLine()
	if !isnumber(self.list1:GetSelectedLine()) then
		self.list1:SelectFirstItem()
	end

	if !isnumber(self.list2:GetSelectedLine()) then
		self.list2:SelectFirstItem()
	end
end

function PANEL:getLeftList()
	return self.list1
end
function PANEL:getRightList()
	return self.list2
end

function PANEL:populateLeftList()
	local stringTable = {}
	for k,v in pairs(leftList) do
		table.insert(stringTable,v:GetColumnText(1))
	end
	return stringTable
end
function PANEL:populateRightList()
	local stringTable = {}
	for k,v in pairs(rightList) do
		table.insert(stringTable,v:GetColumnText(1))
	end
	return stringTable
end


function PANEL:OnButtonRebuild()
	local confirmDialog = vgui.Create( "DFrame" )
	confirmDialog:SetSize( 350, 150 )
	confirmDialog:SetDeleteOnClose( true )
	confirmDialog:ShowCloseButton(false)
	confirmDialog:Center()
	confirmDialog:SetTitle( "Confirm rebuilding the left list!" )
	confirmDialog:MoveToFront()
	confirmDialog.Paint = function(panel, w, h)
		surface.SetDrawColor( 20, 150, 240, 255 )
		surface.DrawRect( 0, 0, w, h )
	end

	confirmDialog.Label = vgui.Create( "RichText", confirmDialog )
	confirmDialog.Label:SetVerticalScrollbarEnabled(false)
	confirmDialog.Label:Dock(FILL)
	confirmDialog.Label:InsertColorChange( 255, 255, 255, 255 )
	confirmDialog.Label:AppendText( "Are you sure you want to rebuild the search list?")

	confirmDialog.Label:InsertColorChange( 255, 255, 255, 255 )
	confirmDialog.Label:AppendText( "\n\nThis might take longer depending on how many folders are there and how fast your cpu is." )
	confirmDialog.Label.Paint = function(panel)
		panel:SetFontInternal( "GModNotify" )
		panel.Paint = nil
	end

	local bottomPanel = vgui.Create("Panel", confirmDialog)
	bottomPanel:Dock(BOTTOM)


	bottomPanel.btnNo = vgui.Create( "DButton", bottomPanel )
	bottomPanel.btnNo:Dock(RIGHT)
	bottomPanel.btnNo:DockMargin(4, 0, 0, 0)
	bottomPanel.btnNo:SetText( "No" )
	bottomPanel.btnNo:SetFont( "GModNotify" )
	bottomPanel.btnNo.Paint = function(panel, w, h)
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawRect( 0, 0, w, h )
	end
	bottomPanel.btnNo.DoClick = function()
		confirmDialog:Close()
	end

	bottomPanel.btnYes = vgui.Create( "DButton", bottomPanel )
	bottomPanel.btnYes:Dock(FILL)
	bottomPanel.btnYes:SetText( "YES" )
	bottomPanel.btnYes:SetFont( "GModNotify" )
	bottomPanel.btnYes.Paint = function(panel, w, h)
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawRect( 0, 0, w, h )
	end
	bottomPanel.btnYes.DoClick = function()
		self:OnRebuild()
		confirmDialog:Close()
	end
end
function PANEL:OnRebuild()
end

function PANEL:OnButtonAdd()
	for k,v in pairs(self.list1:GetSelected()) do
		self.list2:AddLine(v:GetColumnText(1))
		self.list1:RemoveLine(v:GetID())
	end

	leftList, rightList =  self.list1:GetLines(), self.list2:GetLines()
	self:OnAdd()
end
function PANEL:OnAdd()
end

function PANEL:OnButtonRem()
	for k,v in pairs(self.list2:GetSelected()) do
		self.list1:AddLine(v:GetColumnText(1))
		self.list2:RemoveLine(v:GetID())
	end

	leftList, rightList =  self.list1:GetLines(), self.list2:GetLines()
	self:OnRemove()
end
function PANEL:OnRemove()
end


function PANEL:AddLineLeft(var)
	self.list1:AddLine(var)
end
function PANEL:AddLineRight(var)
	self.list2:AddLine(var)
end


function PANEL:clearLeft()
	self.list1:Clear()
end
function PANEL:clearRight()
	self.list2:Clear()
end

function PANEL:PerformLayout()
	local mainX = self:GetWide()
	local mainY = self:GetTall()

	self.list1:SetSize(mainX / 2, mainY)

	self.btnAddMid:SetSize(mainX / 2, midPanelH)
	self.btnRemMid:SetPos(mainX / 2 + self.btnRebuildMid:GetWide(), 0)
	self.btnRemMid:SetSize(mainX - mainX / 2 - self.btnRebuildMid:GetWide(), midPanelH)

	self.list2:SetPos(mainX / 2, self.midPanel:GetTall())
	self.list2:SetSize(mainX - mainX / 2, mainY)
end

derma.DefineControl( "DDoubleListView", "Double List View", PANEL, "Panel" )
