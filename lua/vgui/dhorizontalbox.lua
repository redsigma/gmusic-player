local PANEL = {}

function PANEL:Init()

  self:SetSize(0, 0)

  -- This turns off the engine drawing
  self:SetPaintBackgroundEnabled(false)
  self:SetPaintBorderEnabled(false)
  self:DockPadding(0, 0, 0, 0)
end

function PANEL:ResizeWithPanel(width_panel, height_panel)
  local width_root, height_root = self:GetSize()

  if height_panel < height_root then
    height_panel = height_root
  end

  local final_width = width_root + width_panel
  local final_height = height_panel

  self:SetSize(final_width, final_height)

end

function PANEL:SizeToContentsX()
  local box_items = self:GetChildren()
  local total_width = 0

  for _, panel in pairs(box_items) do
    local w, h = panel:GetSize()
    total_width = total_width + w
  end

  self:SetWidth(total_width)
end

function PANEL:Add(panel)
  panel:SetParent(self)
  panel:Dock(LEFT)

  panel:SizeToContents()

  local panel_width, panel_height = panel:GetSize()
  panel_width = panel_width + 8
  panel_height = panel_height + 4
  panel:SetSize(panel_width, panel_height)
  self:ResizeWithPanel(panel_width, panel_height)

end

derma.DefineControl("DHBox", "Horizontal Box", PANEL, "Panel")