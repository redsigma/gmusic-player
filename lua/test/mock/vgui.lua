_G.derma = {}
_G.derma._New = function(self, controlname)
    local copy = {}
    for k,v in pairs(_G.derma[controlname]) do
        copy[k] = v
    end
    return copy
end
_G.derma.DefineControl = function(controlname, description, panel, base_parent)
    panel.NAME = controlname
    _G.derma[controlname] = panel
    if #base_parent ~= 0 then
        for k,v in pairs(_G.derma[base_parent]) do
            if _G.derma[controlname][k] == nil then
                _G.derma[controlname][k] = v
            end
        end
    end
end
-------------------------------------------------------------------------------
mock_vgui = {}
mock_vgui.__index = mock_vgui

mock_vgui.Create = function(controlname, parent)
    local derma = derma:_New(controlname)
    if derma == nil then
        print ("[ BAD ] Missing", controlname)
        return
    end
    derma.parent = parent
    derma:Init()
    return derma
end
mock_vgui.GetKeyboardFocus = function() end
-------------------------------------------------------------------------------
_G.NODOCK = 0
_G.FILL	= 1
_G.LEFT	= 2
_G.RIGHT = 3
_G.TOP = 4
_G.BOTTOM = 5
BASE = {}
BASE.Init = function(self)
    self.selected = false
    self.visible = false
    self.x = 0
    self.y = 0
    self.w = -1
    self.h = -1
    self.dock_type = _G.NODOCK
    self.color = {}
    self.text = ""
end
BASE.IsValid = function(self) return true end
BASE.SetParent = function(self, new_parent)
    self.parent = new_parent
end
BASE.SetDisabled = function(self, bool) end
BASE.IsVisible = function(self) return self.visible end
BASE.SetVisible = function(self, bool)
    self.visible = bool
end
local item_count = 0
BASE.Add = function(self, controlname)
    local item = vgui.Create(controlname)
    self["item" .. item_count] = item
    item_count = item_count + 1
    return item
end
BASE.Paint = function(self, w ,h) end
BASE.SetFGColor = function(self) end
BASE.GetSkin = function(self)
    local derma_skin_colors = {}
    derma_skin_colors.Colours = {}
    derma_skin_colors.Colours.Label = {}
    derma_skin_colors.Colours.Default = 0
    return derma_skin_colors
end
BASE.SizeToContents = function(self) end
BASE.Remove = function(self) end
BASE.SetContentAlignment = function(self) end
BASE.AlignBottom = function(self) end
BASE.SetFontInternal = function(self, font_name) end
BASE.Dock = function(self, dock_type)
    self.dock_type = dock_type
    if dock_type == _G.FILL then
        self.w = 12
        self.h = 12
    end
end
BASE.DockMargin = function(self) end
BASE.DockPadding = function(self) end
BASE.GetDock = function(self) return self.dock_type end
BASE.SetPos = function(self, x, y) self.x = x self.y = y end
BASE.SetZPos = function(self) end
BASE.SetSize = function(self, w, h) self.w = w self.h = h end
BASE.GetSize = function(self) return self.w, self.h end
BASE.SetText = function(self, text) self.text = text end
BASE.SetTextInset = function(self, x, y) end
BASE.SetCursor = function(self, str) end
BASE.SetHeight = function(self, val)  self.h = val end
BASE.SetWidth = function(self, val)  self.w = val end
BASE.GetText = function(self) return self.text end
BASE.SetText = function(self, text) self.text = text end
BASE.GetTall = function(self) return self.h end
BASE.SetTall = function(self, val) self.h = val end
BASE.GetWide = function(self) return self.w end
BASE.SetWide = function(self, val)  self.w = val end
BASE.GetParent = function(self) return self.parent end
BASE.CursorPos = function(self) return 0, 0 end
BASE.IsSelected = function(self) return self.selected end
BASE.SetSelected = function(self, bool) self.selected = bool end
BASE.SetSelectable = function(self, bool) self.is_selectable = bool end
BASE.InvalidateLayout = function(self, bool) return end
BASE.SetMouseInputEnabled = function(self, bool) self.minput = bool end
BASE.SetKeyboardInputEnabled = function(self, bool) self.kinput = bool end
BASE.ScreenToLocal = function(self, x, y) return x, y end
BASE.MouseCapture = function(self) end
BASE.MoveToFront = function(self) end
BASE.SetFocusTopLevel = function(self) end
BASE.DrawTextEntryText = function(self) end
BASE.GetBGColor = function(self, r, g, b) return self.color end
BASE.SetPaintBackgroundEnabled = function(self) end
BASE.SetPaintBackground = function(self, bool_paint) end
BASE.SetPaintBorderEnabled = function(self) end
BASE.SetConVar = function(self, str_cvar) self.cvar = str_cvar end
derma.DefineControl("Panel", "Panel Mock", BASE, "")

MBASELABEL = {}
MBASELABEL.Init = function() end
derma.DefineControl("Label", "Label Mock", MBASELABEL, BASE.NAME)

MLABEL = {}
MLABEL.Init = function(self) self.color = {} self.toggle_state = false end
MLABEL.SetContentAlignment = function(self) end
MLABEL.SetTextColor = function(self, color) self.color = color end
MLABEL.GetTextColor = function(self) return self.color end
MLABEL.SetColor = MLABEL.SetTextColor
MLABEL.GetColor = MLABEL.GetTextColor
MLABEL.SetFont = function(self) end
MLABEL.SetToggle = function(self, bool) self.toggle_state = bool end
derma.DefineControl("DLabel", "DLabel Mock", MLABEL, BASE.NAME)

MBUTTON = {}
MBUTTON.Init = function() end
MBUTTON.SetImage = function(self) end
derma.DefineControl("DButton", "DButton Mock", MBUTTON, MLABEL.NAME)

MLISTVIEW = {}
MLISTVIEW.Init = function(self)
    self.Columns = {}
    self.Lines = {}
    self.VBar = {}
    for k,v in pairs(BASE) do
        self.VBar[k] = v
    end
end
MLISTVIEW.AddColumn = function(self, panel)
    local column = {}
    for k,v in pairs(BASE) do
        column[k] = v
    end
    column.Header = {}
    for k,v in pairs(MBUTTON) do
        column.Header[k] = v
    end
    table.insert(self.Columns, column)
    return column
end
MLISTVIEW.GetLine = function(self, id) return BASE end
MLISTVIEW.AddLine = function(self, ...)
    -- a line can have sections
    local line = {}
    line.Columns = {}

    for k,column in pairs(self.Columns) do
        local line_section = {}
        line_section.SetTextColor = function(self, text) end
        line_section.COL_NAME = ""
        table.insert(line.Columns, line_section)
    end
    for k, column_text in pairs({ ... }) do
        line.Columns[k].COL_NAME = column_text
    end
    table.insert(self.Lines, line)
    return line
end
MLISTVIEW.Clear = function(self) self.Lines = {} end
MLISTVIEW.GetSelectedLine = function(self) return 1 end
derma.DefineControl("DListView", "DListView Mock", MLISTVIEW, BASE.NAME)

MSCROLLGRIP = {}
MSCROLLGRIP.Init = function(self) end
derma.DefineControl(
    "DScrollBarGrip", "DScrollBarGrip Mock", MSCROLLGRIP, BASE.NAME)

MSCROLLPANEL = {}
MSCROLLPANEL.Init = function(self) end
derma.DefineControl(
    "DScrollPanel", "DScrollPanel Mock", MSCROLLPANEL, BASE.NAME)

MSLIDER = {}
MSLIDER.Init = function(self)
  self.x = -1
  self.y = -1
  self.Knob = MBUTTON
end
MSLIDER.SetLockY = function(self) end
MSLIDER.SetNotches = function(self, num_notches) end
MSLIDER.SetSlideX = function(self, val) self.x = val end
MSLIDER.SetSlideY = function(self, val) self.y = val end
MSLIDER.SetTrapInside = function(self, bool) end
derma.DefineControl("DSlider", "DSlider Mock", MSLIDER, BASE.NAME)

MNUMSCRATCH = {}
MNUMSCRATCH.Init = function(self)
    self.value = 0
    self.fval = 0
    self.max = 0
    self.min = 0
    self.decimals = 0
end
MNUMSCRATCH.SetImageVisible = function(self) end
MNUMSCRATCH.SetFloatValue = function(self, val) self.fval = val end
MNUMSCRATCH.GetFloatValue = function(self) return self.fval end
MNUMSCRATCH.SetDecimals = function(self, num) self.decimals = num end
MNUMSCRATCH.GetDecimals = function(self) return self.decimals end
MNUMSCRATCH.SetValue = function(self, val)
  self.value = val
  self.fval = val * 1.0
end
MNUMSCRATCH.SetMin = function(self, num) self.min = num end
MNUMSCRATCH.GetMin = function(self) return self.min end
MNUMSCRATCH.SetMax = function(self, num) self.max = num end
MNUMSCRATCH.GetMax = function(self) return self.max end
MNUMSCRATCH.GetTextValue = function(self) return "0" end
MNUMSCRATCH.GetFraction = function(self) return 0 end
MNUMSCRATCH.SetTextColor = function(self) end
derma.DefineControl(
    "DNumberScratch", "DNumberScratch Mock", MNUMSCRATCH, BASE.NAME)

MEDITABLE = {}
MEDITABLE.Init = function(self) end
derma.DefineControl(
    "EditablePanel", "EditablePanel Mock", MEDITABLE, BASE.NAME)

MTEXTENTRY = {}
MTEXTENTRY.Init = function(self) self.val = 0 end
MTEXTENTRY.SetEditable = function(self) end
MTEXTENTRY.SetValue = function(self, text) self.val = text end
MTEXTENTRY.GetValue = function(self) return self.val end
MTEXTENTRY.SetFont = function(self) end
derma.DefineControl("DTextEntry", "DTextEntry Mock", MTEXTENTRY, BASE.NAME)
-------------------------------------------------------------------------------
_G.Derma_Hook = function(panel, func_name, hook_name, type)
end

_G.AccessorFunc = function(panel, field, accessor)
    local setter = "Set" .. accessor
    local getter = "Get" .. accessor
    panel[setter] = function(self, val)
        self[field] = val
    end
    panel[getter] = function(self)
        return self[field]
    end
end
-------------------------------------------------------------------------------

_G.vgui = mock_vgui