_G._set_checkbox_as_admin = function(panel, is_checked)
  call_as_admin(function()
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

_G._channel_reach_end = function(is_server)
  _dermaBase.sliderseek.seek_val:OnEndReached(is_server)
end

_G._set_server_mode = function(is_server)
  _dermaBase.main.is_server_mode = is_server
end

--------------------------------------------------------------------------------
local the_player = {}
_G.LocalPlayer = {}

setmetatable(_G.LocalPlayer, {
  __call = function(self)
    if the_player.IsValid == nil then
      the_player.is_admin = _mock_is_admin
      -- used for net.SendServer
      the_player.is_net_admin = _all_players_are_admin
      the_player.was_GetAll = false

      for k, v in pairs(_G.Player) do
        the_player[k] = v
      end
    end

    return the_player
  end
})

--------------------------------------------------------------------------------
-- used to set custom net.Receive players
_G.last_net_received_player = nil

_G._set_player_admin = function(bool)
  _mock_is_admin = bool
  the_player.is_admin = bool

  if last_net_received_player == nil then
    last_net_received_player = the_player
  end

  last_net_received_player.is_admin = bool
end

_G._set_player_connected = function(bool)
  _mock_sending_cl_info = bool
end

_G._get_player_admin = function() return _mock_is_admin end

_G._set_net_players_admin = function(bool)
  _all_players_are_admin = bool
  the_player.is_net_admin = bool
end

--------------------------------------------------------------------------------
-- the caller/sender of the given net_message gains admin access
-- used to fake admin access. The order of inserted elements matters
_G._net_promote_sender_to_admin = function(net_message)
  table.insert(_G._Net.expected_net_msgs_with_fake_admin, net_message)
end