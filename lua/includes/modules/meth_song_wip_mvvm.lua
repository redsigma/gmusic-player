--[[
    Used to store the list of songs used by the music player
--]]
local songData = {}
local dermaBase = {}

songData.folder_songs   = {}
songData.left_folders   = {}
songData.right_folders  = {}
songData.left_folders_addon = {}

--[[
    Stores list of songs absolute paths
--]]
local song_list = {}
song_list.files = {}
song_list.paths = {}

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

	self.folder_songs, self.left_folders = file.Find( "sound/*", "GAME" )
	self.folder_songs, self.left_folders_addon =
    file.Find( "sound/*", "WORKSHOP" )
  left_list_discard_exceptions(self)
  -- used for safety
  if self.right_folders == nil then
    self.right_folders = {}
  end
end

local function save_on_disk(self)
	file.Write( "gmpl_songpath.txt", "")
	for k,v in pairs(self.right_folders) do
		file.Append( "gmpl_songpath.txt", v .. "\r\n")
	end
	dermaBase.audiodirsheet:InvalidateLayout(true)
end

--[[
    Used to build and validate the audio tables
--]]
local function build_left_and_validate_right_list(self)
  local is_dirty = false
  local files = {}
  local folders = {}
  table.Empty(self.folder_songs)
  table.Empty(self.left_folders)
  table.Empty(song_list.files)
  table.Empty(song_list.paths)
  for k, folder in pairs(self.right_folders) do
    folder = string.Trim(folder)
    local path = "sound/" .. folder .. "/"
    files, folders = file.Find(path .. "*", "GAME")
    if #files > 0 then
      table.Add(self.folder_songs, files)
      for k, songName in pairs(files) do
        table.insert(song_list.files, songName)
        table.insert(song_list.paths, path)
      end
    end

    if #folders > 0 then
      table.Add(self.left_folders, folders)
       -- also scan the first subfolder
      local subfolder_files = ""
      for _, folderName in pairs(folders) do
        local path = "sound/" .. folder .. "/" .. folderName .. "/"
        subfolder_files, _ = file.Find(path .. "*", "GAME")
        if subfolder_files ~= nil and #subfolder_files > 0 then
          table.Add(self.folder_songs, subfolder_files)
          for _, songName in pairs(subfolder_files) do
            table.insert(song_list.files, songName)
            table.insert(song_list.paths, path)
          end
        end
      end
    end

    -- if #files == 0 then
    --   print("Set", k , " to nil")
    --   self.right_folders[k] = nil
    --   is_dirty = true
    -- end
  end
  -- table.insert(song_list, folder_songs)
  -- PrintTable(song_list)
  -- print("==============")
  -- if is_dirty then save_on_disk(self) end
end

local function get_files_from_folders(self, list_of_folders)
  local files = {}
  local folders = {}
  local subfolder_files = {}

  local audio_files = {}

  for _, folder in pairs(list_of_folders) do
    folder = string.Trim(folder)

    local song_path = "sound/" .. folder .. "/"
    files, folders = file.Find(song_path .. "*", "GAME")
    if #files > 0 then
      for _, song_name in pairs(files) do
        local song = {}
        song.file = song_name
        song.path = song_path

        table.insert(audio_files, song)
      end
    end


    if #folders > 0 then
       -- also scan the first subfolder
      for _, folderName in pairs(folders) do
        local song_path = "sound/" .. folder .. "/" .. folderName .. "/"
        subfolder_files, _ = file.Find(song_path .. "*", "GAME")

        if subfolder_files ~= nil and #subfolder_files > 0 then
          for _, song_name in pairs(subfolder_files) do
            local song = {}
            song.file = song_name
            song.path = song_path
            table.insert(audio_files, song)
          end
        end
      end
    end

  end

  return audio_files

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
    local audio_path = self.right_folders[j]
    if audio_path ~= nil then
      local path = "sound/" .. audio_path
      -- this doesn't look in WORKSHOP we prove it exists using
      -- self.left_folders_addon
      if not file.Exists( path, "GAME" ) then
        local found = false
        for k,addonSong in pairs(self.left_folders_addon) do
          -- use self.left_folders_addon just to check for existence
          if rawequal(addonSong, audio_path) then
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

local function populate_music_dirs(self)
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

local function populate_song_page(self)
  dermaBase.songlist:Clear()
  if table.IsEmpty(song_list.files) then
    dermaBase.songlist:InvalidateLayout(true)
    dermaBase.songlist:InvalidateLayout()
    return
  end
  for _, file in SortedPairsByValue(song_list.files) do
    dermaBase.songlist:AddLine(file, song_list.paths[_])
  end
  -- PrintTable(song_list.paths)
  -- should not be twice but doesnt work otherwise
  dermaBase.songlist:InvalidateLayout(true)
  dermaBase.songlist:InvalidateLayout()
end

--------------------------------------------------------------------------------
--[[
    Get the song absolute filepath
--]]
local function get_song(self, index)
  if index > #song_list.files then index = 1 end
  local line = dermaBase.songlist:GetLine(index)
  if line == nil then return nil end
  return line.path, index
end

local function get_left_song_list(self)
    return self.left_folders
end

local function get_right_song_list(self)
	return self.right_folders
end

--[[
    Populates the right song dir list
--]]
local function load_from_disk(self)
	if file.Exists( "gmpl_songpath.txt", "DATA" ) then
		local files = string.Explode("\n", file.Read( "gmpl_songpath.txt", "DATA"))
    table.Empty(self.right_folders)
    for _, folder in pairs(files) do
      local folder_trim = string.Trim(folder)
      if #folder_trim > 0 then
        self.right_folders[_] = folder_trim
      end
		end
    build_left_and_validate_right_list(self)
    return true
	end
  return false
end


local function read_active_folders_from_config_file()
  local active_folders = {}

	if not file.Exists( "gmpl_songpath.txt", "DATA" ) then
    return active_folders
  end

  local files = string.Explode("\n", file.Read( "gmpl_songpath.txt", "DATA"))
  for _, folder in pairs(files) do
    local folder_trim = string.Trim(folder)
    if #folder_trim > 0 then
      active_folders[_] = folder_trim
    end
  end

  return active_folders
end

local function rebuild_song_page(self)
  rebuild_left_list(self)
  sanity_check_right_list(self)
  populate_music_dirs(self)
end

local function refresh_song_list(self)
  build_left_and_validate_right_list(self)
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

songData.populate_left_list = populate_left_list
songData.populate_right_list = populate_right_list



songData.read_active_folders_from_config_file = read_active_folders_from_config_file

songData.get_files_from_folders = get_files_from_folders

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
  --  songData:populate_song_page()
   dermaBase.buttonrefresh:SetVisible(false)
   dermaBase.audiodirsheet:InvalidateLayout(true)
end)
-----------------------------------------------------------------------------
return init
