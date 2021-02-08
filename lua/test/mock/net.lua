
local last_net = ""
local mock_net = {}
local call_list = {}
mock_net.Receive = function(str_name, callback)
  if call_list[str_name] == nil then
    call_list[str_name] = {}
    call_list[str_name].args = {}

  end
  call_list[str_name].callback = callback
end
mock_net.Start = function(str_name)
  last_net = str_name
  if #call_list[last_net].args > 0 then
    call_list[last_net].args = {}
  end
end
local players = {}
_G._net_set_player_admin = {}

mock_net.SendToServer = function()
  -- local player = _G.LocalPlayer()
  if last_net_received_player == nil then
    last_net_received_player = _G.LocalPlayer()
  end
  local player = last_net_received_player
  players[1] = player

  local is_player_admin = _net_set_player_admin[last_net]
  if is_player_admin == nil then
    last_net_received_player = player
    call_list[last_net].callback(20, player)
    return
  end

  local prev_admin_state = player.is_admin
  player.is_admin = is_player_admin
  last_net_received_player = player
  call_list[last_net].callback(20, player)

  player.is_admin = prev_admin_state
  net_calls_player[last_net] = nil
end

_G.player = {}
_G.player.GetAll = function()
  for _, player in pairs(players) do
    player.was_GetAll = true
  end
  return players
end
mock_net.Send = function(players)
  local player = players[1]
  if player == nil then
    player = players
  end

  local changed_net_player_admin = _net_set_player_admin[last_net]
  local prev_admin_state = player.is_admin

  -- temp player used with edited attrs
  local new_player = make_copy(player)
  if player.was_GetAll == false then
    -- if last_net == "cl_play_live_seek_from_host" then
    --   call_list[last_net].callback(10, _LocalAdmin)
    --   return
    -- end
    if changed_net_player_admin == nil then
      last_net_received_player = player
      call_list[last_net].callback(10, player)
    else
      new_player.is_admin = changed_net_player_admin
      last_net_received_player = new_player
      call_list[last_net].callback(10, new_player)
    end
    -- player.is_admin = prev_admin_state
    return
  end

  player.was_GetAll = false
  -- local prev_net_admin_state = player.is_net_admin

  -- all players will change admin state
  -- but will prioritize _net_set_player_admin if used
  if changed_net_player_admin ~= nil then
    new_player.is_admin = changed_net_player_admin
  else
    new_player.is_admin = player.is_net_admin
  end
  -- all players will change admin state
  -- but will prioritize _net_set_player_admin if used
  -- new_player.is_admin = player.is_net_admin
  call_list[last_net].callback(10, new_player)

  -- player.is_admin = prev_admin_state
  -- player.is_net_admin = prev_net_admin_state
end

mock_net.last_uint = {}
mock_net.last_uint.number = 0
mock_net.last_uint.bits = 0
mock_net.last_double = 0.0
mock_net.last_table = {}
mock_net.last_string = ""
mock_net.last_bool = false
mock_net.last_entity = {}
mock_net.WriteTable = function(tbl)
  mock_net.last_table = tbl
  table.insert(call_list[last_net].args, tbl)
end

--
-- TODO FIX net.Read to do a top-pop mechanic cuz now it works bad
--

mock_net.ReadTable = function()
  mock_net.last_table = table.remove(call_list[last_net].args, 1)
  return mock_net.last_table
end
mock_net.WriteString = function(str)
  mock_net.last_string = str
  table.insert(call_list[last_net].args, str)
end
mock_net.ReadString = function()
  mock_net.last_string = table.remove(call_list[last_net].args, 1)
  return mock_net.last_string
end
mock_net.WriteBool = function(bool)
  mock_net.last_bool = bool
  table.insert(call_list[last_net].args, bool)
end
mock_net.ReadBool = function()
  mock_net.last_bool = table.remove(call_list[last_net].args, 1)
  return mock_net.last_bool
end
mock_net.WriteEntity = function(ent)
  mock_net.last_entity = ent
  table.insert(call_list[last_net].args, ent)
end
mock_net.ReadEntity = function()
  mock_net.last_entity = table.remove(call_list[last_net].args, 1)
  return mock_net.last_entity
end
mock_net.WriteUInt = function(num, num_bits)
  mock_net.last_uint.number = num
  mock_net.last_uint.bits = num_bits
  table.insert(call_list[last_net].args, mock_net.last_uint)
end
mock_net.ReadUInt = function(nr_bits)
  mock_net.last_uint = table.remove(call_list[last_net].args, 1)
  if mock_net.last_uint.bits == nr_bits then
    return mock_net.last_uint.number
  end
  return {}
end
mock_net.WriteDouble = function(num)
  mock_net.last_double = num
  table.insert(call_list[last_net].args, mock_net.last_double)
end
mock_net.ReadDouble = function()
  mock_net.last_double = table.remove(call_list[last_net].args, 1)
  return mock_net.last_double
end

_G.net = mock_net
_G.util.AddNetworkString = function(str_name)
  if call_list[str_name] ~= nil then return end
  call_list[str_name] = {}
  call_list[str_name].args = {}
  call_list[str_name].callback = {}
end