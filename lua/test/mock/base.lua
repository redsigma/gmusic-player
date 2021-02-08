-- Base
--------------------------------------------------------------------------------
_G.include = function(path_no_ext)
    local str = string.gsub(path_no_ext, ".lua", "")
    return require(str)
end
_G.AddCSLuaFile = function(file)
    include(file)
end

_G.HUD_PRINTNOTIFY	= 1
_G.HUD_PRINTCONSOLE	= 2
_G.HUD_PRINTTALK	= 3
_G.HUD_PRINTCENTER  = 4
_G.Player = {}
_G.Player.IsValid = function(self) return true end
_G.Player.IsAdmin = function(self)
    return self.is_admin
end
_G.Player.PrintMessage = function(self, ...)
    local args = { ... }
    local str_result = ""
	for _, v in ipairs( args ) do
        if isstring(v) then
            str_result = str_result .. " " .. v
        end
        if isnumber(v) then
            if _ == 1 and v == _G.HUD_PRINTCONSOLE then
                str_result = str_result .. "CONSOLE:"
            else
                str_result = str_result .. " " .. v
            end
        end
        if isbool(v) then
            if v then
                str_result = str_result .. " true"
            else
                str_result = str_result .. " false"
            end
        end
	end
    print(str_result)
end
_G.LocalPlayer = {}
local _mock_is_admin = false
setmetatable(_G.LocalPlayer, { __call = function(self)
    local player = {}
    player.is_admin = _mock_is_admin
    for k,v in pairs(_G.Player) do
        player[k] = v
    end
    return player
end })
_G._set_player_admin = function(bool)
    _mock_is_admin = bool
end

_G.Color = function(r,g,b)
    local color = {}
    color.r = r
    color.g = g
    color.b = b
    return color
end
_G.ScrW = function()
    return 800
end
_G.ScrH = function()
    return 600
end
_G.timer = {}
_G.timer.Create = function() end
_G.timer.Start = function() end
_G.timer.Pause = function() end
_G.timer.Stop = function() end

_G.surface = {}
_G.surface.CreateFont = function(name, table) end
_G.surface.SetDrawColor = function() end
_G.surface.DrawRect = function() end

-- Cvar
--------------------------------------------------------------------------------
_G.ConVar = {}
_G.ConVar.GetName = function(self)
    return self.name
end
_G.ConVar.SetInt = function(self, val)
    self.oldvalue = self.value
    self.value = val
end
_G.ConVar.GetInt = function(self)
    return self.value
end
_G.ConVar.GetFloat = function(self)
    return self.value
end
_G.ConVar.GetBool = function(self)
    if self.value == 0 then
        return false
    else
        return true
    end
end
_G.ConVar.SetString = function(self, val_str)
    local tmp = self.value
    self.value = tonumber(val_str) or nil
    if self.value == nil then
        self.value = tmp
    else
        self.oldvalue = tmp
    end
end
setmetatable(_G.ConVar, {  __call = function()
    local cvar = {}
    for k, v in pairs(_G.ConVar) do
        cvar[k] = v
    end
    return cvar
end })
local cvar_list = {}
_G.CreateClientConVar = function(name, default_val, will_save, info, help_text)
    local cvar = ConVar()
    cvar.name = name
    cvar.value = 0
    cvar.oldvalue = 0
    cvar.default = default_val
    cvar.should_save = will_save
    cvar.info = info
    cvar.help = help_text
    cvar_list[name] = cvar
    return cvar
end
_G.ConVarExists = function(name)
    for cvar_name, values in pairs(cvar_list) do
        if cvar_name == name then return true end
    end
    return false
end
_G.GetConVar = function(cvar_name)
    local convar = cvar_list[cvar_name]
    if convar == nil then
        print("[ BAD ] Missing cvar", cvar_name)
    end
    return convar
end
_G.cvars = {}
_G.cvars.AddChangeCallback = function(cvar_name, callback)
    local cvar = cvar_list[cvar_name]
    callback(cvar.name, callback(cvar_name, cvar.oldvalue, cvar.value))
end
_G.RunConsoleCommand = function(cvar_name, str_val)
    cvar_list[cvar_name]:SetString(str_val)
end
_G.concommand = {}
_G.concommand.Add = function(cmd_name, callback) end
--------------------------------------------------------------------------------

-- Math
--------------------------------------------------------------------------------
_G.math.Clamp = function(input, min, max)
    math.min(math.max(input, min), max)
end
_G.math.Round = function(num, idp)
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end
--------------------------------------------------------------------------------

-- String
--------------------------------------------------------------------------------
_G.string.FormattedTime = function(seconds, format)
	if not seconds then seconds = 0 end
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor( (seconds / 60) % 60)
	local millisecs = ( seconds - math.floor(seconds) ) * 100
	seconds = math.floor(seconds % 60)

	if format then
		return string.format(format, minutes, seconds, millisecs)
	else
		return { h = hours, m = minutes, s = seconds, ms = millisecs }
	end
end
_G.string.ToMinutesSeconds = function(seconds)
    return _G.string.FormattedTime(seconds, "%02i:%02i" )
end
_G.string.GetFileFromFilename = function(path)
	if not path:find("\\") and not path:find("/") then return path end
	return path:match("[\\/]([^/\\]+)$") or ""
end
_G.string.StripExtension = function(path)
    local i = path:match(".+()%.%w+$")
    if i then return path:sub(1, i - 1) end
    return path
end
_G.string.Totable = function(str)
	local tbl = {}
	for i = 1, string.len(str) do
		tbl[i] = string.sub(str, i, i)
	end
	return tbl
end
_G.string.Explode = function(separator, str, pattern)
	if separator == "" then return string.ToTable(str) end
	if pattern == nil then pattern = false end

	local ret = {}
	local current_pos = 1

	for i = 1, string.len(str) do
		local start_pos, end_pos =
            string.find(str, separator, current_pos, not pattern)
		if not start_pos then break end
		ret[i] = string.sub(str, current_pos, start_pos - 1)
		current_pos = end_pos + 1
	end

	ret[#ret + 1] = string.sub(str, current_pos)
	return ret
end
_G.string.TrimRight = function(s, char)
    if char then char = char:PatternSafe()
    else char = "%s" end
    return string.match( s, "^(.-)" .. char .. "*$" ) or s
end
_G.string.Trim = function(s, char)
	if char then char = char:PatternSafe()
    else char = "%s" end
	return string.match( s, "^" .. char .. "*(.-)" .. char .. "*$" ) or s
end
_G.string.TrimLeft = function(s, char)
	if char then char = char:PatternSafe()
    else char = "%s" end
	return string.match( s, "^" .. char .. "*(.+)$" ) or s
end
--------------------------------------------------------------------------------

-- Validity
--------------------------------------------------------------------------------
_G.IsValid = function(obj)
    if obj ~= nil and obj.IsValid ~= nil then
        return obj:IsValid()
    end
    return false
end
_G.isstring = function(str)
    return type(str) == 'string'
end
_G.istable = function(table)
    return type(table) == 'table'
end
_G.isnumber = function(nr)
    return type(nr) == 'number'
end
_G.isentity = function(ent)
    return type(ent) == 'table' and ent.IsValid ~= nil
end
_G.isfunction = function(func)
    return type(func) == 'function'
end
_G.isbool = function(bool)
    return type(bool) == 'boolean'
end
_G.tobool = function(val)
    if type(val) == 'string' and #val > 0 then
        if val == "0" then return false else return true end
    end
    if type(val) == 'number' then
        if tonumber(val) == 0 then return false else return true end
    end
    return val
end
--------------------------------------------------------------------------------

-- Chat
--------------------------------------------------------------------------------
_G.chat = {}
_G.chat.AddText = function(...)
    local args = { ... }
    local str_result = ""
	for _, v in ipairs( args ) do
        if isstring(v) or isnumber(v) then
            str_result = str_result .. " " .. v
        end
        if isbool(v) then
            if v then
                str_result = str_result .. " true"
            else
                str_result = str_result .. " false"
            end
        end
	end
    print(str_result)
end
_G.MsgC = function(...)
    _G.chat.AddText(...)
end

--------------------------------------------------------------------------------

-- Audio
--------------------------------------------------------------------------------
_G.GMOD_CHANNEL_STOPPED = 0
_G.GMOD_CHANNEL_PLAYING = 1
_G.GMOD_CHANNEL_PAUSED = 2
_G.GMOD_CHANNEL_STALLED = 3

_G.AudioChannel = {}
_G.AudioChannel.IsValid = function() return true end
_G.AudioChannel.SetTime = function(self, new_time)
    self._time = new_time
end
_G.AudioChannel.EnableLooping = function(self, bool)
    self._loop = bool
end
_G.AudioChannel.SetVolume = function(self, new_vol)
    self._volume = new_vol
end
_G.AudioChannel.GetLength = function(self)
    return 310.80
end
_G.AudioChannel.GetState = function(self)
    return self._state
end
_G.AudioChannel.Play = function(self)
    self._state = GMOD_CHANNEL_PLAYING
end
_G.AudioChannel.Pause = function(self)
    self._state = GMOD_CHANNEL_PAUSED
end
_G.AudioChannel.Stop = function(self)
    self._state = GMOD_CHANNEL_STOPPED
end
setmetatable(_G.AudioChannel, {  __call = function()
    local chann = {}
    chann._time = 0
    chann._loop = false
    chann._state = GMOD_CHANNEL_STOPPED
    for k, v in pairs(_G.AudioChannel) do
        chann[k] = v
    end
    return chann
end })

_G.sound = {}
_G.sound.PlayFile = function(str_song, flags, callback)
    if not _G.isstring(str_song) then return end
    local current_song = AudioChannel()
    callback(current_song, 0, "no error")
end
--------------------------------------------------------------------------------

-- Table
--------------------------------------------------------------------------------
-- Empty the table contents
_G.table.Empty = function(table)
    if table == nil then
        table = {}
    else
        for i=0, #table do table[i]=nil end
    end
end
_G.table.ClearKeys = function(table)
    local new_table = {}
    for k,v in pairs(table) do
        new_table[k] = v
    end
    return new_table
end
_G.table.IsEmpty = function(table)
    if #table == 0 then return true end
    return false
end

_G.table.Add = function(table_dest, table_src)
    if not istable(table_src)  then return table_dest end
    if not istable(table_dest)  then table_dest = {} end
    for k, v in pairs(table_src) do
        table.insert(table_dest, v)
    end
    return table_dest
end

local storage = {}
storage = {}
storage.GAME = {}
storage.WORKSHOP = {}
storage["GAME"].sound = {}
storage["WORKSHOP"].sound = {}
storage["GAME"].sound.folder1 = { "Example1.mp3", "Example2.mp3"}
storage["WORKSHOP"].sound.folder1 = { "Example10.mp3"}
storage["GAME"].sound.folder2 = { "Example3.mp3", "Example4.mp3"}
storage["WORKSHOP"].sound.folder2 = { "Example30.mp3"}
storage["WORKSHOP"].sound.folder3 = { "Audio_addon1.mp3"}
storage["WORKSHOP"].sound.folder4 = { "Audio_addon2.mp3"}
_G.file = {}
_G.file.Exists = function(self) return true end
_G.file.Find = function(path, path_type)
    local folders = _G.string.Explode("/", path)
    local song_table = {}
    if #folders > 3 then
        song_table = storage[path_type][folders[1]][folders[2]][folders[3]]
    else
        song_table = storage[path_type][folders[1]][folders[2]]
    end
    return song_table, { folders[2] }
end
_G.file.Read = function(self)
    local fake_data = "folder1\nfolder2\nfolder3\n"
    return fake_data
end
--------------------------------------------------------------------------------

-- Util
--------------------------------------------------------------------------------
_G.util = {}
_G.util.StringToType = function(self, str, convert_to)

    -- TODO add support for FLOAT

    if convert_to == "int" then
        return tonumber(str)
    end
    return str
end
--------------------------------------------------------------------------------