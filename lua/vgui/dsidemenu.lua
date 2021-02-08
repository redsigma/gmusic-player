local PANEL = {}
AccessorFunc(PANEL, "ActiveButton", "ActiveButton")

-- TODO
-- - rename this vgui element
-- - it acts as a container that stores the other panels, besides the sidebar
function PANEL:Init()
  self.sidebar = vgui.Create("DScrollPanel", self)
  self.sidebar:SetWidth(100)
  self.sidebar:SetZPos(1)
  self.sidebar:MoveToFront()
  -- stores all the panels linked to each button
  self.sheet_list = vgui.Create("Panel", self)
  self.sheet_items = {}
  self:SetSize(self:GetParent():GetSize())
end

function PANEL:OnSideBarToggle(wide)
end

--For override
function PANEL:ToggleSideBar()
  if self.sidebar:IsVisible() then
    self.sidebar:SetVisible(false)
    self:OnSideBarToggle(0)
    self:InvalidateLayout()
  else
    self.sidebar:SetVisible(true)
    self:OnSideBarToggle(self.sidebar:GetWide())
  end
end

function PANEL:GetSideBarItems()
  return self.sheet_items
end

function PANEL:UseButtonOnlyStyle()
  self.ButtonOnly = true
end

function PANEL:AddSheet(label, panel, material)
  if (not IsValid(panel)) then return end
  local Sheet = {}

  if (self.ButtonOnly) then
    Sheet.Button = vgui.Create("DImageButton", self.sidebar)
  else
    Sheet.Button = vgui.Create("DButton", self.sidebar)
  end

  Sheet.Button:SetImage(material)
  Sheet.Button.Target = panel
  Sheet.Button:Dock(TOP)
  Sheet.Button:SetText(label)
  Sheet.Button:DockMargin(0, 1, 0, 0)

  Sheet.Button.DoClick = function()
    self:SetActiveButton(Sheet.Button)
  end

  Sheet.Panel = panel
  Sheet.Panel:SetParent(self.sheet_list)
  Sheet.Panel:SetVisible(false)

  if (self.ButtonOnly) then
    Sheet.Button:SizeToContents()
  end

  table.insert(self.sheet_items, Sheet)

  if (not IsValid(self.ActiveButton)) then
    self:SetActiveButton(Sheet.Button)
  end
end

function PANEL:SetActiveButton(active)
  if (self.ActiveButton == active) then return end

  if (self.ActiveButton and self.ActiveButton.Target) then
    self.ActiveButton.Target:SetVisible(false)
    self.ActiveButton:SetSelected(false)
    self.ActiveButton:SetToggle(false)
  end

  self.ActiveButton = active
  active.Target:SetVisible(true)
  active:SetSelected(true)
  active:SetToggle(true)
  self.sheet_list:InvalidateLayout()
end

function PANEL:TogglePanelsVisible(bool)
  if bool == nil then
    bool = not self.sheet_list:IsVisible()
  end

  self.sheet_list:SetVisible(bool)
end

function PANEL:IsVisible()
  return self.sheet_list:IsVisible()
end

function PANEL:IsSideBarVisible()
  return self.sidebar:IsVisible()
end

function PANEL:PerformLayout(width, height)
  if self.sidebar:IsVisible() then
    self.sheet_list:SetSize(width - 100, height)
  else
    self.sheet_list:SetSize(width, height)
  end
end

derma.DefineControl("DSideMenu", "", PANEL, "Panel")