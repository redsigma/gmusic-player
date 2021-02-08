local PANEL = {}

local function is_player_admin()
  local player = LocalPlayer()

  if not IsValid(player) then
    return false
  else
    return player:IsAdmin()
  end
end

function PANEL:SetValue(val)
  local bVal = false

  if isbool(val) then
    bVal = val
  elseif isnumber(val) then
    bVal = tobool(val)
  end

  if not self.is_admin_only then
    self.is_checked = bVal
    self:RefreshConVar()

    return
  end

  if is_player_admin() then
    self.is_checked = bVal
  end

  self:RefreshConVar()
end

function PANEL:Init()
  self.child = {}
  self.id = 0
  self.is_admin_only = false
  self:SetSize(15, 15)
  self:SetText("")
  self.is_checked = false
  self.cvar = nil
end

function PANEL:addCheckbox(index, checkbox)
  self.id = index
  self.child[index] = checkbox
end

function PANEL:SetID(val)
  self.id = val
end

function PANEL:SetAdminOnly(bVal)
  self.is_admin_only = bVal
end

-- Only admins are allowed to click on checkbox
function PANEL:IsAdminOnly()
  return self.is_admin_only
end

function PANEL:AfterChange(val)
end

-- override after a value has changed
function PANEL:OnCvarWrong(oldValue, newValue)
end

-- override if any problem happened
function PANEL:PersistConvar(newCvar)
  self.cvar = newCvar

  if not ConVarExists(self.cvar:GetName()) then
    self.cvar:SetInt(self.cvar:GetDefault())
  end

  cvars.AddChangeCallback(self.cvar:GetName(), function(convar, oldValue, newValue)
    local val_change = 0

    if self.is_admin_only and not is_player_admin() then
      val_change = tonumber(oldValue)

      if isnumber(val_change) then
        self:SetValue(val_change)
      else
        self.cvar:SetString("1") -- force admin only if fail
      end

      return
    end

    val_change = tonumber(newValue)

    if isnumber(val_change) then
      self:AfterChange(val_change)
    else
      self:OnCvarWrong(oldValue, newValue)
    end
  end)
end

-- Actual call that commits cvar changes
function PANEL:ConVarChanged(strNewValue)
  if (not self.m_strConVar) then return end
  RunConsoleCommand(self.m_strConVar, strNewValue)
  self:AfterChangeDelayed(strNewValue)
end

function PANEL:RefreshConVar()
  if self.is_checked then
    self.cvar:SetString("1")
  else
    self.cvar:SetString("0")
  end
end

function PANEL:IsDepressed()
  return self.Depressed
end

-- TODO I think it acts as a slient check cuz SetValue triggers cvar change
function PANEL:SetChecked(bool)
  self.is_checked = bool
end

function PANEL:GetChecked()
  return self.is_checked
end

function PANEL:DoClick()
  self:Toggle()
end

function PANEL:Toggle()
  if self.is_checked then
    self:SetValue(false)
  else
    self:SetValue(true)
  end
end

function PANEL:SetConVar(strConVar)
  self.m_strConVar = strConVar
end

-- TODO Think only every 0.1 seconds?
function PANEL:ConVarStringThink()
  if (not self.m_strConVar) then return end
  local strValue = GetConVarString(self.m_strConVar)
  if (self.m_strConVarValue == strValue) then return end
  self.m_strConVarValue = strValue
  self:SetValue(self.m_strConVarValue)
end

function PANEL:ConVarNumberThink()
  if (not self.m_strConVar) then return end -- if nil return false
  local strValue = GetConVar(self.cvar:GetName()):GetInt()
  -- In case the convar is a "nan"
  if (strValue ~= strValue) then return end
  if (self.m_strConVarValue == strValue) then return end
  self.m_strConVarValue = strValue
  self:SetValue(self.m_strConVarValue)
end

-- Make checkbox unclickable if not admin
function PANEL:Think()
  if not self:IsVisible() then return end

  if self.is_admin_only then
    if is_player_admin() then
      if self:GetDisabled() then
        self:SetEnabled(true)
      end
    else
      if not self:GetDisabled() then
        self:SetEnabled(false)
      end
    end
  end

  self:ConVarNumberThink()
end

derma.DefineControl("DBetterCheckBox", "CheckboxCustom", PANEL, "DButton")