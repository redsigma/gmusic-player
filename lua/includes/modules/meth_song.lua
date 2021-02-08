--[[
    Used to store the list of songs used by the music player
--]]
local songData = {}
local dermaBase = {}
local local_player = LocalPlayer()

songData.folder_songs   = {}
songData.left_folders   = {}
songData.right_folders  = {}
songData.left_folders_addon = {}

--[[
    Stores list of songs absolute paths
--]]
local song_list = {}

local folderExceptions = { "ambience", "ambient", "ambient_mp3", "beams",
"buttons", "coach", "combined", "commentary", "common", "doors", "foley",
"friends", "garrysmod", "hl1", "items", "midi", "misc", "mvm", "test",
"npc", "passtime", "phx", "physics", "pl_hoodoo", "plats", "player",
"replay", "resource", "sfx", "thrusters", "tools", "ui", "vehicles", "vo",
"weapons" }

local function init(baseMenu)
    dermaBase = baseMenu
	return songData
end
--------------------------------------------------------------------------------
--[[
    Discards folders that are not needed
--]]
local function left_list_discard_exceptions(self)
    for k,v in pairs(self.left_folders) do
		for j = 0, #folderExceptions do
			if v == folderExceptions[j] then
				self.left_folders[k] = nil
			end
		end
	end
	for k,v in pairs(self.left_folders_addon) do
		for j = 0, #folderExceptions do
			if v == folderExceptions[j] then
				self.left_folders_addon[k] = nil
			end
		end
	end
	self.left_folders = table.ClearKeys(self.left_folders)
	self.left_folders_addon = table.ClearKeys(self.left_folders_addon)
end

local function rebuild_left_list(self)
	table.Empty(self.left_folders)
	table.Empty(self.left_folders_addon)

	self.folder_songs, self.left_folders =
        file.Find( "sound/*", "GAME" )
	self.folder_songs, self.left_folders_addon =
        file.Find( "sound/*", "WORKSHOP" )
    left_list_discard_exceptions(self)
    -- used for safety
    if self.right_folders == nil then
        self.right_folders = {}
    end
end

local function sanity_check_right_list(self)
	for k,leftItem in pairs(self.left_folders) do
		for j = 1, #self.right_folders do
            -- remove audio dir from left list if in right list
			if rawequal(leftItem, self.right_folders[j]) then
				self.left_folders[k] = nil
				break
			end
		end
	end

	for j = 1, #self.right_folders do
		local path = "sound/" .. self.right_folders[j]
        -- this doesn't look in WORKSHOP we prove it exists using
        -- self.left_folders_addon
		if not file.Exists( path, "GAME" ) then
			local found = false
			for k,addonSong in pairs(self.left_folders_addon) do
                -- use self.left_folders_addon just to check for existence
				if rawequal(addonSong, self.right_folders[j]) then
					found = true
                    -- if it exists we only clear it from left list
					self.left_folders_addon[k] = nil
				end
				if found then break end
			end
			if not found then
				self.right_folders[j] = nil
			end
		end
	end
    -- clean left list addons after you prove above that they exist
	for k,leftItemAddon in pairs(self.left_folders_addon) do
		for k2,rightItem in pairs(self.right_folders) do
			if rawequal(leftItemAddon, rightItem) then
				self.left_folders_addon[k] = nil
				break
			end
		end
	end
end

local function populate_both_lists(self)
	dermaBase.foldersearch:clearLeft()
	dermaBase.foldersearch:clearRight()

    -- don't add duplicates
	for k,folderAddon in pairs(self.left_folders_addon) do
		for k2,folderBase in pairs(self.left_folders) do
			if rawequal(folderBase, folderAddon) then
				self.left_folders[k2] = nil
			end
		end
	end

	for key,foldername in pairs(self.left_folders_addon) do
		dermaBase.foldersearch:AddLineLeft(foldername)
	end
	for key,foldername in pairs(self.left_folders) do
		dermaBase.foldersearch:AddLineLeft(foldername)
	end

	for key,foldername in pairs(self.right_folders) do
		dermaBase.foldersearch:AddLineRight(foldername)
	end
end

local function updateSongList(table_songs)
    if table.IsEmpty(table_songs) then return end
    song_list = table_songs
    for key, filePath in pairs(song_list) do
        dermaBase.songlist:AddLine(
            string.StripExtension(string.GetFileFromFilename(filePath)))
    end
end
--------------------------------------------------------------------------------
--[[
    Get the song absolute filepath
--]]
local function get_song(self, index)
    if table.IsEmpty(song_list) then return end
    return song_list[index]
end

local function get_current_list(self)
    return song_list
end

local function get_left_song_list(self)
    return self.left_folders
end

local function get_right_song_list(self)
	return self.right_folders
end

local function populate_song_page(self)
	dermaBase.songlist:Clear()
    local table_songs = {}
    local subfolder_songs = {}
    local worshop_folders = {}
    local worshop_files = {}
	for k, folder in pairs(self.right_folders) do
        folder = string.Trim(folder)
        self.folder_songs, self.left_folders =
            file.Find("sound/" .. folder .. "/*", "GAME") or {}, {}

        worshop_files, worshop_folders =
            file.Find( "sound/" .. folder .. "/*", "WORKSHOP" )

        if not table.IsEmpty(worshop_files) then
            table.Add(self.folder_songs, worshop_files)
        end

        for k, songName in pairs(self.folder_songs) do
            table.insert(table_songs, "sound/" .. folder .. "/" .. songName)
        end

        for key, folderName in pairs(self.left_folders) do
            -- also scan within the first folders
            subfolder_songs = file.Find(
                "sound/" .. folder .. "/" .. folderName .. "/*", "GAME")
            if subfolder_songs ~= nil then
                for key2, songName in pairs(subfolder_songs) do
                    table.insert(table_songs, "sound/" .. folder .. "/" .. folderName .. "/" .. songName)
                end
            end
        end
	end
    updateSongList(table_songs)
end

local function save_on_disk(self)
	self:populate_song_page()
	file.Write( "gmpl_songpath.txt", "")
	for k,v in pairs(self.right_folders) do
		file.Append( "gmpl_songpath.txt", v .. "\r\n")
	end
	dermaBase.audiodirsheet:InvalidateLayout(true)
end

--[[
    Populates the right song dir list
--]]
local function load_from_disk(self)
	if file.Exists( "gmpl_songpath.txt", "DATA" ) then
		local fileRead =
            string.Explode("\n", file.Read( "gmpl_songpath.txt", "DATA" ))
		for i = 1, #fileRead - 1 do
			self.right_folders[i] = string.TrimRight(fileRead[i])
		end
		self:populate_song_page()
	end
end

local function rebuild_song_page(self)
    rebuild_left_list(self)
    sanity_check_right_list(self)
    populate_both_lists(self)
end

local function refresh_song_list(self)
    net.Start("sv_refresh_song_list")
    net.WriteTable(self.left_folders)
    net.WriteTable(self.right_folders)
    net.SendToServer()
end

local function populate_left_list(self, song_list)
    if istable(song_list) then
        self.left_folders = song_list
    else
        self.left_folders = dermaBase.foldersearch:populateLeftList()
    end
end

local function populate_right_list(self, song_list)
    if istable(song_list) then
        self.right_folders = song_list
    else
        self.right_folders = dermaBase.foldersearch:populateRightList()
    end
end
-----------------------------------------------------------------------------
songData.populate_song_page = populate_song_page
songData.rebuild_song_page  = rebuild_song_page
songData.refresh_song_list  = refresh_song_list

songData.save_on_disk       = save_on_disk
songData.load_from_disk     = load_from_disk

songData.get_song           = get_song

songData.get_left_song_list  = get_left_song_list
songData.get_right_song_list = get_right_song_list
songData.get_current_list   = get_current_list

songData.populate_left_list = populate_left_list
songData.populate_right_list = populate_right_list
-----------------------------------------------------------------------------
net.Receive("cl_refresh_song_list", function(length, sender)
    -- update the left list in case of becoming admin
    songData.left_folders = net.ReadTable()
    songData.right_folders = net.ReadTable()

--    print("\nUpdating song list from server")
--    print("inactive:")
--    PrintTable(songData.left_folders)
--    print("active:")
--    PrintTable(songData.right_folders)
--    print("----------------------------")

   -- actionRebuild()
   songData:rebuild_song_page()
   -- populate_song_page(folderRight)
   songData:populate_song_page()
   dermaBase.buttonrefresh:SetVisible(false)
   dermaBase.audiodirsheet:InvalidateLayout(true)
end)
-----------------------------------------------------------------------------
return init
