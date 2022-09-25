_G._set_checkbox_as_admin = function(panel, is_checked)
  player_with_admin:do_action(function(self)
    panel:SetChecked(is_checked)
    panel:RefreshConVar()
  end)
end

-- reset server audio states to default
_G._reset_server = function()
  net.Start("sv_reset_audio")
  net.SendToServer()
end

--------------------------------------------------------------------------------
local slider_seek_max = 0

_G._set_slider_seek_max = function(max_seek)
  if max_seek == nil then
    max_seek = 400.25 -- default
  end

  slider_seek_max = max_seek
  AudioChannel:_SetMaxTime(max_seek)
  _dermaBase.sliderseek:SetMax(max_seek)
  _dermaBase.sliderseek:AllowSeek(true)
end

_G._set_slider_size = function(size)
  _dermaBase.sliderseek.seek_val.Slider:SetWide(size)
end

_G._slider_seek_secs = function(seek_secs)
  local slider_mapped = math.Remap(seek_secs, 0, slider_seek_max, 0, 1)
  local slider_raw = slider_mapped * _dermaBase.sliderseek.seek_val.Slider:GetWide()
  _dermaBase.sliderseek:AllowSeek(true)
  _dermaBase.sliderseek.seek_val:SetDragging(true)
  _dermaBase.sliderseek.seek_val:OnCursorMoved(slider_raw)
end

_G._slider_seek = function(slider_pos)
  _dermaBase.sliderseek:AllowSeek(true)
  _dermaBase.sliderseek.seek_val:SetDragging(true)
  _dermaBase.sliderseek.seek_val:OnCursorMoved(slider_pos)
end

_G._sv_channel_reach_end = function()
  _dermaBase.sliderseek.seek_val:OnEndReached(true)
end

_G._cl_channel_reach_end = function()
  _dermaBase.sliderseek.seek_val:OnEndReached(false)
end

_G._set_server_mode = function(is_server)
  _dermaBase.main.is_server_mode = is_server
end

--------------------------------------------------------------------------------
local player_now = {}

_G.LocalPlayer = {}
setmetatable(_G.LocalPlayer, {
  __call = function(self)
    return player_now
  end
})

--------------------------------------------------------------------------------

_G._set_player_connected = function(bool)
  _mock_sending_cl_info = bool
end

_G._get_player_admin = function() return _mock_is_admin end

_G._set_net_players_admin = function(bool)
  _all_players_are_admin = bool
  player_now.is_net_admin = bool
end


--------------------------------------------------------------------------------

local PlayerAdmin = make_copy(Player)
PlayerAdmin.is_admin = true
PlayerAdmin.__internal_id = "admin"

local Player1 = make_copy(Player)
Player1.is_admin = false
Player1.__internal_id = "player1"

local Player2 = make_copy(Player)
Player2.is_admin = false
Player2.__internal_id = "player2"

_G.__mock_all_connected_players = {}
__mock_all_connected_players[1] = PlayerAdmin
__mock_all_connected_players[2] = Player1
-- __mock_all_connected_players[2] = Player2

local function __set_current_player_as(player)
  print(player)
end

_G.player_with_admin = {}
_G.player_with_admin.property = {}
_G.player_with_admin.property.current_admin = 0

_G.player_with_no_admin = {}
_G.player_with_no_admin.property = {}
_G.player_with_no_admin.property.current_admin = 0

_G.player_with_admin.do_action = function(self, callback)
  player_now = PlayerAdmin

  self.property.current_admin = player_now
  callback(self.property)
  self.property.current_admin = 0
end

_G.player_with_no_admin.do_action = function(self, callback)
  player_now = Player1

  self.property.current_admin = player_now
  callback(self.property)
  self.property.current_admin = 0
end


_G.init_sv_shared_settings = function()
  _G.gmusic_sv = {}

  player_with_admin:do_action(function(self)
    net.Start("cl_update_cvars_from_first_admin")
    net.Send(PlayerAdmin)
  end)

end


--[[

player_with_no_admin:do_action(function(self)

end)


----------------


player_with_admin:do_action(function(self)

end)


-----------

player_with_admin:do_action(function(self)
  dermaBase.buttonplay:DoClick(nil, 0)
end)

player_with_no_admin:do_action(function(self)

end)


]]
