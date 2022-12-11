local PANEL = {}

function PANEL:Init()
  self:MouseCapture(false)
  self:SetSize(0, 0)

  self.boxes = {}
  self.nonboxes = {}
  self.minimum_width = 0

  -- workaround for clipping
  self.minimum_width_initial = 0

  -- keep ref to panel to get its pos
  self.panel_ref = nil

  -- This turns off the engine drawing
  self:SetPaintBackgroundEnabled(false)
  self:SetPaintBorderEnabled(false)
  self:DockPadding(0, 0, 0, 0)
end

-- TODO remove cuz i dont think you need this
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

function PANEL:Add(item_panel, minimum_size_to_cover)

  item_panel:SetParent(self)
  item_panel:Dock(LEFT)

  item_panel:SizeToContents()

  local width, height = self:GetSize()

  local is_box = item_panel.ClassName == "DHBox"
  if is_box then

    local has_valid_minimum_size = nil ~= minimum_size_to_cover
    and minimum_size_to_cover > 0
    and minimum_size_to_cover < 1

    if has_valid_minimum_size then
      item_panel.minimum_width = minimum_size_to_cover
      item_panel.minimum_width_initial = minimum_size_to_cover
    end

    table.insert(self.boxes, item_panel)
    return
  end
  table.insert(self.nonboxes, item_panel)
end

function PANEL:SortBoxesBySize()
  table.sort(self.boxes, function(a, b)

    local is_box_a = a.ClassName == "DHBox"
    local is_box_b = b.ClassName == "DHBox"

    if is_box_a and is_box_b then
      return a.minimum_width > b.minimum_width
    end
    return false
  end)
end

function PANEL:SetSizeWithPanel(new_width, new_height)

  if not self.panel_ref then
    return
  end

  local size_fill_multiplier = 0.3
  local size_to_fill = new_width * size_fill_multiplier
  local remaining_size = new_width - size_to_fill

  local new_pos = remaining_size + self.panel_ref:GetX()

  self:SetSize(size_to_fill, new_height)
  self:SetX(new_pos)

  if self.panel_ref then
    self.panel_ref:SetWidth(remaining_size)
  end
end

function PANEL:SetPosNearPanel(panel)
  self.panel_ref = panel
end

function PANEL:UpdateLayout()
  self:SortBoxesBySize()

  local width, height = self:GetSize()

  local len_subpanels = #self.boxes + #self.nonboxes
  local width_per_panel = width / len_subpanels

  local remaining_width = width
  for _, subpanel in pairs(self.boxes) do
    local panel_width = width_per_panel

    if subpanel.minimum_width > 0 then
      panel_width = subpanel.minimum_width * width
    end

    if panel_width > remaining_width then
      panel_width = remaining_width
    end
    remaining_width = remaining_width - panel_width

    subpanel:SetSize(panel_width, height)
  end

  for _, subpanel in pairs(self.nonboxes) do
    local panel_width = width_per_panel

    if panel_width > remaining_width then
      panel_width = remaining_width
    end
    remaining_width = remaining_width - panel_width

    subpanel:SetSize(panel_width, height)
  end

end


function PANEL:UpdateSizeContents()
  local width, height = self:GetSize()

  local len_subpanels = #self.boxes + #self.nonboxes
  local width_per_panel = width / len_subpanels

  local remaining_width = width


  for k, subpanel in pairs(self.boxes) do
    local panel_width = width_per_panel

    if subpanel.minimum_width > 0 then
        panel_width = subpanel.minimum_width * width
    end

    if panel_width > remaining_width then
      panel_width = remaining_width
    end
    remaining_width = remaining_width - panel_width

    -- prevent clipping by giving more space to the right-side box
    if k > 1 then
      if panel_width < 150 then
        self.boxes[k - 1].minimum_width = self.boxes[k - 1].minimum_width - 0.005
      else
        if self.boxes[k - 1].minimum_width < self.boxes[k - 1].minimum_width_initial then
          self.boxes[k - 1].minimum_width = self.boxes[k - 1].minimum_width + 0.005
        end
      end
    end

    subpanel:SetSize(panel_width, height)
    subpanel:UpdateSizeContents()

  end

  for _, subpanel in pairs(self.nonboxes) do
    local panel_width = width_per_panel

    if panel_width > remaining_width then
      panel_width = remaining_width
    end
    remaining_width = remaining_width - panel_width

    subpanel:SetSize(panel_width, height)

  end

end


function PANEL:__debug_panel(r, g, b)
  r = r or 255
  g = g or 0
  b = b or 0
  self.PaintOver = function(panel, w, h)
    surface.SetDrawColor(r, g, b, 70)
    surface.DrawRect(0, 0, w, h)
  end
end

derma.DefineControl("DHBox", "Horizontal Box", PANEL, "Panel")