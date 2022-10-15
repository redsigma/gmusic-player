local mock_hook = {}
local list_hook = {}

mock_hook.Add = function(str_internal, name, callback)
    list_hook[str_internal] = {}
    setmetatable(list_hook[str_internal],
        { __call = function(self, ply) callback(ply) end })
end
mock_hook.Remove = function(str_internal, name)
 -- TODO look in list and remove
 -- check original lua for implementation details
end

mock_hook.GetTable = function()
    return {}
end
mock_hook._Run = function(name)
    list_hook[name](_G.LocalPlayer())
end
_G.hook = mock_hook

