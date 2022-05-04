-- TODO how about you copy paste the code from here for actual real code
-- - you might need to adapt it for the TYPE thing
-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/net.lua
local last_net = ""
local mock_net = {}
local call_list = {}
--------------------------------------------------------------------------------
_G._Net = {}
_G._Net.expected_net_msgs_with_fake_admin = {}

--------------------------------------------------------------------------------
local function make_player_admin_if_needed(player)
  local player_clone = make_copy(player)

  for k, net_message in pairs(_Net.expected_net_msgs_with_fake_admin) do
    if net_message == last_net then
      _Net.expected_net_msgs_with_fake_admin[k] = nil
      player_clone.is_admin = true
      break
    end
  end

  return player_clone
end

--------------------------------------------------------------------------------
mock_net.Receive = function(str_name, callback)
  if call_list[str_name] == nil then
    call_list[str_name] = {}
    call_list[str_name].args = {}
  end

  call_list[str_name].callback = callback
end

mock_net.Start = function(net_message_name)
  last_net = net_message_name

  if #call_list[last_net].args > 0 then
    call_list[last_net].args = {}
  end
end

local players = {}

mock_net.SendToServer = function()
  local is_first_sender = last_net_received_player == nil

  if is_first_sender then
    last_net_received_player = _G.LocalPlayer()
  end

  players[1] = last_net_received_player
  local expected_player = make_player_admin_if_needed(last_net_received_player)
  call_list[last_net].callback(20, expected_player)
end

_G.player = {}
_G.player.GetAll = function() return players end

mock_net.Send = function(all_players)
  local player = all_players[1]
  local is_only_one_player = player == nil

  if is_only_one_player then
    player = all_players
  end

  local expected_player = make_player_admin_if_needed(player)
  call_list[last_net].callback(10, expected_player)
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
  if mock_net.last_uint.bits == nr_bits then return mock_net.last_uint.number end

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