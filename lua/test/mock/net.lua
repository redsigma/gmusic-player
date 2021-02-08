
local last_net = ""
local mock_net = {}
local call_list = {}
mock_net.Receive = function(str_name, callback)
    if call_list[str_name] == nil then
        call_list[str_name] = {}
    end
    call_list[str_name].args = {}
    setmetatable(call_list[str_name], {  __call = callback })
end
mock_net.Start = function(str_name)
    last_net = str_name
end
mock_net.SendToServer = function()
    call_list[last_net](20, _G.LocalPlayer())
end
mock_net.Send = function()
    call_list[last_net](10, _G.LocalPlayer())
end

local last_uint = {}
last_uint.number = 0
last_uint.bits = 0
mock_net.last_uint = last_uint
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
    return mock_net.last_table
end
mock_net.WriteString = function(str)
    mock_net.last_string = str
    table.insert(call_list[last_net].args, str)
end
mock_net.ReadString = function()
    return mock_net.last_string
end
mock_net.WriteBool = function(bool)
    mock_net.last_bool = bool
    table.insert(call_list[last_net].args, bool)
end
mock_net.ReadBool = function()
    return mock_net.last_bool
end
mock_net.WriteEntity = function(ent)
    mock_net.last_entity = ent
    table.insert(call_list[last_net].args, ent)
end
mock_net.ReadEntity = function()
    return mock_net.last_entity
end
mock_net.WriteUInt = function(num, num_bits)
    mock_net.last_uint.number = num
    mock_net.last_uint.bits = num_bits
    table.insert(call_list[last_net].args, mock_net.last_uint)
end
mock_net.ReadUInt = function(nr_bits)
    if mock_net.bits == nr_bits then
        return mock_net.last_uint
    end
    return {}
end

_G.net = mock_net
_G.util.AddNetworkString = function(str)
    call_list[str] = {}
    call_list[str].args = {}
end