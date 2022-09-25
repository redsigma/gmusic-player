-- TODO how about you copy paste the code from here for actual real code
-- - you might need to adapt it for the TYPE thing
-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/net.lua
local last_net = ""
local mock_net = {}
local call_list = {}
--------------------------------------------------------------------------------
_G._Net = {}

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

--[[
  @note - simulate `players.GetAll()`
]]
local all_connected_players = {}
_G.player = {}
_G.player.GetAll = function() return __mock_all_connected_players end

--[[
  @note - remember previous player that made the .net call
]]
local last_net_received_player = nil

mock_net.SendToServer = function()
  last_net_received_player = _G.LocalPlayer()

  call_list[last_net].callback(20, last_net_received_player)
end

mock_net.Send = function(all_players)
  local player = all_players[1]
  local is_only_one_player = player == nil

  if is_only_one_player then
    player = all_players
  end

  call_list[last_net].callback(10, player)
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