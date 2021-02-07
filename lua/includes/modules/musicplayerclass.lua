local cvarMediaVolume = CreateClientConVar("gmpl_vol", "100", true, false, "[gMusic Player] Sets the Volume of music player")

local hostAdminAccess = ""
local defaultFont = "arialDefault"
local dermaBase = {}

Media = {}
Media.__index = Media

local songsInFolder  = {}
local folderLeft = {}
local folderLeftAddon = {}
local folderRight = {}
local populatedSongs = {}
local folderExceptions = { "ambience", "ambient", "ambient_mp3", "beams",
"buttons", "coach", "combined", "commentary", "common", "doors", "foley",
"friends", "garrysmod", "hl1", "items", "midi", "misc", "mvm", "test",
"npc", "passtime", "phx", "physics", "pl_hoodoo", "plats", "player",
"replay", "resource", "sfx", "thrusters", "tools", "ui", "vehicles", "vo",
"weapons" }
/*
    Parent anchor of the main panel
*/
local view_ingame = nil
local view_context_menu = nil
/*
    Used to track if the player is in context menu
    note: IsWorldClicking() NOT reliable
*/
local is_context_open = false

local basenameSongs = {}

function Media:new(coreBase)
	dermaBase = coreBase
	local MediaPlayer = setmetatable({}, Media)
    /*
        Used to store the active anchor panel when the window is visible
    */
    self.anchor_parent = nil
    /*
        Check if player is admin
    */
    self.playerIsAdmin = false
	local action = include("includes/func/audio.lua")(dermaBase)
	for k,v in pairs(action) do self[k] = v end
	return MediaPlayer
end
setmetatable(Media, {  __call = Media.new })


function Media:SetVolume(var)
	cvarMediaVolume:SetString(var)
	dermaBase.slidervol:SetValue(var)
end

function Media:SetSongHost(ply)
	if isentity(ply) && ply:IsAdmin() then
		hostAdminAccess = ply
		dermaBase.labelswap:SetText( "Host: " .. hostAdminAccess:Nick() )
	end
end


--[[-------------------------------------------------------------------------
Methods Used For Server Options -- Runs in think
---------------------------------------------------------------------------]]--
local function adminAcessRevertButtons()
	dermaBase.buttonplay:SetText("Play / AutoPlay")
	dermaBase.buttonpause:SetText("Pause / Loop")
	dermaBase.buttonstop:SetVisible(true)
	dermaBase.buttonswap:SetVisible(false)
end

local function adminAcessChangeButtons()
	if dermaBase.cbadminaccess:GetChecked() then   -- make sure the checkbox is on
		dermaBase.buttonplay:SetText("Resume Live")
		dermaBase.buttonpause:SetText("Pause")
		dermaBase.buttonstop:SetVisible(false)
		dermaBase.buttonswap:SetVisible(true)
	end
end

local function adminAccessDirChangeButton()
	if dermaBase.audiodirsheet:IsVisible() and !Media.playerIsAdmin then
		dermaBase.musicsheet:SetActiveButton(dermaBase.musicsheet.Items[1].Button)
	end

	if Media.playerIsAdmin then
		if !dermaBase.musicsheet.Items[2].Button:IsVisible() then
			dermaBase.musicsheet.Items[2].Button:SetVisible(true)
			dermaBase.musicsheet.Navigation:InvalidateChildren()
		end
	elseif dermaBase.musicsheet.Items[2].Button:IsVisible() then
		dermaBase.musicsheet.Items[2].Button:SetVisible(false)
		dermaBase.musicsheet.Navigation:InvalidateChildren()
	end
end

local function adminAccessDirRevertButton()
	if dermaBase.musicsheet.Items[2].Button:GetDisabled() then
		dermaBase.musicsheet.Items[2].Button:SetEnabled(true)
	end
end

local function thinkServerOptions()
	if dermaBase.main.IsServerOn() then
		if !Media.playerIsAdmin then
			adminAcessChangeButtons()
		else
			adminAcessRevertButtons()
		end
	end

	if dermaBase.cbadmindir:GetChecked() then
		adminAccessDirChangeButton()
	else
		adminAccessDirRevertButton()
	end
end
---------------------------------------------------------------------------]]--

local function getSongName( filePath )
	local songName = string.GetFileFromFilename(filePath)
	table.insert(basenameSongs, songName)
	return string.StripExtension(songName)
end

local function getSongs( path, soundTable )
	path = string.Trim(path)

	songsInFolder, folderLeft = file.Find( "sound/" .. path .. "/*", "GAME" )

	local songsInFolderAddons, appendFolders = file.Find( "sound/" .. path .. "/*", "WORKSHOP" )
	if IsValid(appendFolders) then
		table.Add(folderLeft, appendFolders)
	end
	if IsValid(songsInFolderAddons) then
		table.Add(songsInFolder, songsInFolderAddons)
	end

	for k, songName in pairs( songsInFolder ) do
		table.insert( soundTable, "sound/" .. path .. "/" .. songName )
	end

	for key, folderName in pairs( folderLeft ) do  -- also scan within the first folders
		songsInFolder = file.Find( "sound/" .. path .. "/" .. folderName .. "/*", "GAME" )

		for key2, songName in pairs( songsInFolder ) do
		table.insert( soundTable, "sound/" .. path .. "/" .. folderName .. "/" .. songName )
		end
	end

	return soundTable
end

local function getSongList( folderRightTable )
	table.Empty(populatedSongs)
	dermaBase.songlist:Clear()

	for k,foldername in pairs(folderRightTable) do
		getSongs(foldername, populatedSongs)
	end

	for key, filePath in pairs( populatedSongs ) do
		dermaBase.songlist:AddLine(getSongName(filePath))
	end
	Media.updateSongs(populatedSongs)
end

local function enableServerTSS(bool)
	if !dermaBase.main:isTSS() then
		dermaBase.main:SetTSSEnabled(true)
	end

	dermaBase.main:SetTitleServerState(bool)  -- switch to Client/Server
	dermaBase.contextmedia:SetTSS(bool)
end


local function initLeftList()
	table.Empty(folderLeft)
	table.Empty(folderLeftAddon)

	songsInFolder, folderLeft = file.Find( "sound/*", "GAME" )
	songsInFolder, folderLeftAddon = file.Find( "sound/*", "WORKSHOP" ) -- also adds GAME

	for k,v in pairs(folderLeft) do
		for j = 0, #folderExceptions do
			if v == folderExceptions[j] then
				folderLeft[k] = nil
			end
		end
	end
	for k,v in pairs(folderLeftAddon) do
		for j = 0, #folderExceptions do
			if v == folderExceptions[j] then
				folderLeftAddon[k] = nil
			end
		end
	end
	folderLeft = table.ClearKeys(folderLeft)
	folderLeftAddon = table.ClearKeys(folderLeftAddon)
end

local function sanityCheckActiveList()
	for k,leftItem in pairs(folderLeft) do
		for j = 1, #folderRight do
			if rawequal(leftItem, folderRight[j]) then -- remove songDir from searchList if in activeList
				folderLeft[k] = nil
				break
			end
		end
	end

	for j = 1, #folderRight do
		local path = "sound/" .. folderRight[j]
		if !file.Exists( path, "GAME" ) then -- this doesn't look in WORKSHOP we prove it exists using folderLeftAddon
			local found = false
			for k,addonSong in pairs(folderLeftAddon) do
				if rawequal(addonSong, folderRight[j]) then	-- use folderLeftAddon just to check for existence
					found = true
					folderLeftAddon[k] = nil -- if it exists we only clear it from left list
				end
				if found then break end
			end
			if !found then
				folderRight[j] = nil
			end
		end
	end

	for k,leftItemAddon in pairs(folderLeftAddon) do -- clean left list addons after you prove above that they exist
		for k2,rightItem in pairs(folderRight) do
			if rawequal(leftItemAddon, rightItem) then
				folderLeftAddon[k] = nil
				break
			end
		end
	end

end

local function populateMusicDir()
	dermaBase.foldersearch:clearLeft()
	dermaBase.foldersearch:clearRight()

	for k,folderAddon in pairs(folderLeftAddon) do	-- make sure we don't add duplicates
		for k2,folderBase in pairs(folderLeft) do
			if rawequal(folderBase, folderAddon) then
				folderLeft[k2] = nil
			end
		end
	end

	for key,foldername in pairs(folderLeftAddon) do
		dermaBase.foldersearch:AddLineLeft(foldername)
	end
	for key,foldername in pairs(folderLeft) do
		dermaBase.foldersearch:AddLineLeft(foldername)
	end
	for key,foldername in pairs(folderRight) do
		dermaBase.foldersearch:AddLineRight(foldername)
	end
end

local function actionRebuild()
	initLeftList()
	sanityCheckActiveList()
	populateMusicDir()
end

local function actionRefresh()
	getSongList(folderRight)
	file.Write( "gmpl_songpath.txt", "")
	for k,v in pairs(folderRight) do
		file.Append( "gmpl_songpath.txt", v .. "\r\n")
	end
	dermaBase.audiodirsheet:InvalidateLayout(true)
end

local function createMain()
	dermaBase.main:SetFont(defaultFont)

	dermaBase.musicsheet:AddSheet("Song List",dermaBase.songlist , "icon16/control_play_blue.png")
	dermaBase.musicsheet:AddSheet(" Music Dirs",dermaBase.audiodirsheet, "icon16/folder_add.png", true)
	dermaBase.musicsheet:AddSheet("Settings",dermaBase.settingsheet, "icon16/application_view_list.png")

	dermaBase.musicsheet.Items[2].Button.PaintOver = function(self,w,h)
		if self:GetDisabled() then
		surface.SetDrawColor( 0, 0, 0, 150 )
		surface.DrawRect( 0, 0, w, h )
		end
	end

	local tallOptionsPage = 0


	for k,v in pairs(dermaBase.settingPage.Items) do
		tallOptionsPage = tallOptionsPage + v:GetTall()
	end
	dermaBase.settingPage:SetSize(200, tallOptionsPage + 40)

	initLeftList()
	sanityCheckActiveList()
	populateMusicDir()
	getSongList(folderRight)
end

local function createMediaPlayer()
	dermaBase.main:SetPos(16, 36)
	dermaBase.main:SetText(" gMusic Player")
	dermaBase.main:SetDraggable(true)
	dermaBase.main:SetSizable(true)

	dermaBase.contextmedia:SetText(false)
	local mainX, mainY = dermaBase.main:GetSize()

	dermaBase.musicsheet:SetPos(0,20)
	dermaBase.musicsheet.Navigation:Dock(RIGHT)
	dermaBase.musicsheet.Navigation:SetVisible(false)

	dermaBase.settingPage:Dock(FILL)
	dermaBase.settingPage:DockPadding(0, 0, 0, 10)

	dermaBase.audiodirsheet:Dock(FILL)
	dermaBase.audiodirsheet:DockMargin( 0, 0, 0, 0 )

	dermaBase.songlist:AddColumn( "Song" )

	dermaBase.labelrefresh:Dock(TOP)
	dermaBase.labelrefresh:SetHeight(44)
	dermaBase.labelrefresh.Paint = function(self, w, h)
		draw.DrawText( "Select the folders from ROOT that are going to be added. ROOT: garrysmod\\sound\\ \nIt will also add the content of the first folders found inside them.", "default", w * 0.5, h * 0.10, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
		draw.DrawText( "Right Click to deselect | (Ctrl or Shift)+Click for multiple selections", "default", w * 0.5, h * 0.66, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	end

	dermaBase.buttonrefresh:Dock(BOTTOM)
	dermaBase.buttonrefresh:SetFont(defaultFont)
	dermaBase.buttonrefresh:SetText("Press to refresh the Song List")
	dermaBase.buttonrefresh:SetSize(mainX / 3,30)
	dermaBase.buttonrefresh:SetVisible(false)

	dermaBase.buttonswap:SetSize(mainX / 3,30)
	dermaBase.buttonswap:SetPos(0,  dermaBase.musicsheet:GetTall() + 20)

	dermaBase.labelswap:SetFont(defaultFont)
	dermaBase.labelswap:Dock(FILL)
	dermaBase.labelswap:DockMargin(6,1,0,0)
	if isentity(hostAdminAccess) then
		dermaBase.labelswap:SetText( "Host: " .. hostAdminAccess:Nick() )
	else
		dermaBase.labelswap:SetText( "No host info" )
	end

	local buttonTall = 30
	dermaBase.buttonstop:SetText("Stop")
	dermaBase.buttonstop:SetSize(mainX / 3, buttonTall)
	dermaBase.buttonstop:SetPos(0, dermaBase.musicsheet:GetTall() + 20)

	dermaBase.buttonpause:SetText("Pause / Loop")
	dermaBase.buttonpause:SetSize(dermaBase.buttonstop:GetWide(), buttonTall)
	dermaBase.buttonpause:SetPos(dermaBase.buttonstop:GetWide(), dermaBase.musicsheet:GetTall() + 20)

	dermaBase.buttonplay:SetText("Play / AutoPlay")
	dermaBase.buttonplay:SetSize(mainX - (dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide()), buttonTall)
	dermaBase.buttonplay:SetPos(dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide(), dermaBase.musicsheet:GetTall() + 20)

	dermaBase.sliderseek:SetSize(mainX - 150 , buttonTall)
	dermaBase.sliderseek:AlignBottom()
	dermaBase.sliderseek.Slider.Knob:SetHeight(dermaBase.sliderseek:GetTall())
	dermaBase.sliderseek.Slider.Knob:SetWide(5)
	dermaBase.sliderseek:ShowSeekTime()
	dermaBase.sliderseek:ShowSeekLength()

	dermaBase.slidervol:SetValue(cvarMediaVolume:GetFloat())

	dermaBase.musicsheet.Items[2].Button.DoClick = function(self)
		dermaBase.foldersearch:selectFirstLine()
		if !dermaBase.audiodirsheet:IsVisible() then
			dermaBase.musicsheet:SetActiveButton(self)
		end
	end

	dermaBase.buttonrefresh.DoClick = function(self)
		if dermaBase.cbadmindir:GetChecked() then
			if Media.playerIsAdmin then
				net.Start("toServerRefreshSongList")

				net.WriteTable(folderLeft)
				net.WriteTable(folderRight)
				net.SendToServer()
			end
		else
			self:SetVisible(false)
			actionRefresh()
		end
	end

	dermaBase.buttonstop.DoClick = function()
		if dermaBase.main.IsServerOn() then
			if !dermaBase.cbadminaccess:GetChecked() then
				net.Start( "toServerStop" )
				net.SendToServer()
			elseif Media.playerIsAdmin then
				net.Start( "toServerAdminStop" )
				net.SendToServer()
			end
		else
			if !Media.isMissing() then
				Media.stop()
			end
		end
	end

	dermaBase.buttonpause.DoClick = function()
		Media.pause()
	end

	dermaBase.buttonplay.DoClick = function( songFile )
		local nrLine = dermaBase.songlist:GetSelectedLine()
		if isnumber(nrLine) then
			if !isstring(songFile) then
				songFile = populatedSongs[nrLine]
			end
			if dermaBase.main.IsServerOn() then
				net.Start( "toServerAdminPlay" )
				net.WriteString(songFile)
				net.SendToServer()
			else
				if Media.hasValidity() and Media.hasState() == GMOD_CHANNEL_PAUSED  then
					Media.resume(songFile)
				else
					Media.play(songFile)
				end
				enableServerTSS(false)
			end
		else
			if !( dermaBase.main.IsServerOn() and  !Media.playerIsAdmin and dermaBase.cbadminaccess:GetChecked() ) then
				chat.AddText(Color(100, 200, 200), "[gMusic Player] ",
                    Color(255, 90, 90), "Please select a song")
			else
				net.Start( "toServerAdminPlay" )
				net.WriteString("")
				net.SendToServer()
			end
		end
	end

	dermaBase.buttonplay.DoRightClick = function()
		if #populatedSongs and dermaBase.main.IsServerOn() then
			if dermaBase.cbadminaccess:GetChecked() then
				if Media.playerIsAdmin then
					Media.autoplay()
					net.Start("sv_autoPlay")
					net.WriteBool(Media.isAutoPlay())
					net.SendToServer()
				end
			else
				Media.autoplay()
				net.Start("sv_autoPlay")
				net.WriteBool(Media.isAutoPlay())
				net.SendToServer()
			end
		else
			Media.autoplay()
		end
	end

	dermaBase.slidervol.OnValueChanged = function(panel, value)
		if Media.hasValidity() then
			Media.volume(panel:GetValue() / 100)
		end
	end

	dermaBase.slidervol.OnVolumeClick = function(panel, lastVolume)
		if Media.hasValidity() then
			if panel:GetMute() then
				Media.volume(0)
			else
				Media.volume(lastVolume)
			end
		end
	end

	dermaBase.foldersearch.OnRebuild = function(panel)
		if dermaBase.cbadmindir:GetChecked() then
			if Media.playerIsAdmin then
				actionRebuild()
				panel:selectFirstLine()
			end
		else
			actionRebuild()
			panel:selectFirstLine()
		end
	end

	dermaBase.foldersearch.OnAdd = function(panel)
		if dermaBase.cbadmindir:GetChecked() then
			if Media.playerIsAdmin then
				panel:selectFirstLine()
				dermaBase.buttonrefresh:SetVisible(true)

				folderLeft = dermaBase.foldersearch:populateLeftList()
				folderRight = dermaBase.foldersearch:populateRightList()
			end
		else
			panel:selectFirstLine()
			dermaBase.buttonrefresh:SetVisible(true)

			folderLeft = dermaBase.foldersearch:populateLeftList()
			folderRight = dermaBase.foldersearch:populateRightList()
		end
	end

	dermaBase.foldersearch.OnRemove = function(panel)
		if dermaBase.cbadmindir:GetChecked() then
			if Media.playerIsAdmin then
				panel:selectFirstLine()
				dermaBase.buttonrefresh:SetVisible(true)

				folderLeft = panel:populateLeftList()
				folderRight = panel:populateRightList()
			end
		else
			panel:selectFirstLine()
			dermaBase.buttonrefresh:SetVisible(true)

			folderLeft = panel:populateLeftList()
			folderRight = panel:populateRightList()
		end
	end


	dermaBase.songlist.DoDoubleClick = function(panel, lineIndex, line)
		songFile = populatedSongs[lineIndex]
		dermaBase.buttonplay.DoClick(songFile)
	end

	dermaBase.sliderseek.SeekClick.OnValueChanged = function(seekClickLayer, seekSecs)
		if Media.hasValidity() then
			if dermaBase.main.IsServerOn() then
				if !dermaBase.cbadminaccess:GetChecked() then
					if Media.hasState() == GMOD_CHANNEL_PAUSED then
						Media.seek(seekSecs)
						dermaBase.sliderseek:SetTime(seekSecs)
					end
					net.Start("toServerSeek")
					net.WriteDouble(seekSecs)
					net.SendToServer()
				elseif Media.playerIsAdmin then
					if Media.hasState() == GMOD_CHANNEL_PAUSED then
						Media.seek(seekSecs)
						dermaBase.sliderseek:SetTime(seekSecs)
					end
					net.Start( "toServerSeek" )
					net.WriteDouble(seekSecs)
					net.SendToServer()
				end
			else
				if Media.hasState() ~= GMOD_CHANNEL_PAUSED then
					Media.seek(seekSecs)
					dermaBase.sliderseek:SetTime(seekSecs)
				end
			end
		end
	end

	dermaBase.main.OnLayoutChange = function(panel)
		local songHeight = dermaBase.musicsheet:GetTall()
		local mainTall = panel:GetTall()

		dermaBase.musicsheet:SetSize(panel:GetWide(), mainTall - 80 )
		dermaBase.songlist:RefreshLayout(panel:GetWide(), mainTall - 80 )
		if dermaBase.musicsheet.Navigation:IsVisible() then
			dermaBase.settingPage:RefreshLayout(panel:GetWide() - 100, mainTall - 80 )
		else
			dermaBase.settingPage:RefreshLayout(panel:GetWide(), mainTall - 80 )
		end

		dermaBase.buttonstop:SetSize(panel:GetWide() / 3,30)
		dermaBase.buttonstop:SetPos(0, songHeight + 20)

		dermaBase.buttonswap:SetSize(panel:GetWide() / 3,30)
		dermaBase.buttonswap:SetPos(0, songHeight + 20)

		dermaBase.buttonpause:SetSize(dermaBase.buttonstop:GetWide(), 30)
		dermaBase.buttonpause:SetPos(dermaBase.buttonstop:GetWide(), songHeight + 20)

		dermaBase.buttonplay:SetSize(panel:GetWide() - (dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide()), 30)
		dermaBase.buttonplay:SetPos(dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide(), songHeight + 20)

		dermaBase.sliderseek:SetSize(panel:GetWide() - 150 ,30)
		dermaBase.slidervol:SetSize(panel:GetWide()  - dermaBase.sliderseek:GetWide() - 5, 30)
	end

	dermaBase.main.OnResizing = function()
		dermaBase.musicsheet:SetVisible(false)
	end
	dermaBase.main.AfterResizing = function()
		dermaBase.musicsheet:SetVisible(!dermaBase.musicsheet:IsVisible())
	end

	dermaBase.main.OnSettingsClick = function(panel)
		dermaBase.musicsheet:ToggleSideBar()

	end
	dermaBase.musicsheet.OnSideBarToggle = function(sidePanel, wide)
		dermaBase.settingPage:RefreshCategoryLayout(dermaBase.main:GetWide() - wide)
	end

	dermaBase.main.OnModeChanged = function()
		if !dermaBase.main.IsServerOn() then
			adminAcessRevertButtons()
		end
	end

	dermaBase.contextmedia.OnThink = function(panel)
		if Media.hasValidity() and Media.hasState() == GMOD_CHANNEL_PLAYING then
			panel:SetSeekTime(Media.getTime())
		elseif panel:IsMissing() then
			panel:SetSeekEnabled(false)
		end
	end
end

function Media:getLeftSongList()
	return folderLeft
end

function Media:getRightSongList()
	return folderRight
end

function Media:readFileSongs()
	if file.Exists( "gmpl_songpath.txt", "DATA" ) then
		local fileRead = string.Explode("\n", file.Read( "gmpl_songpath.txt", "DATA" ))
		for i = 1, #fileRead - 1 do
			folderRight[i] = string.TrimRight(fileRead[i])
		end
		getSongList(folderRight)
	end
end

function Media:SyncSettings(ply)
	dermaBase.settingPage:SyncItems(ply)
end

function Media:create(context_menu)
	createMain()
	createMediaPlayer()
    view_ingame = dermaBase.main:GetParent()
    view_context_menu = context_menu
end

function Media:show()
	if dermaBase.main:IsVisible() then
        RememberCursorPosition()
        gui.EnableScreenClicker(false)
        if is_context_open then
            if self.anchor_parent == view_context_menu then
                dermaBase.main:SetVisible(false)
            else
                // move from outside to context area
                self.anchor_parent = view_context_menu
            end
        else
            if self.anchor_parent == view_ingame then
                dermaBase.main:SetVisible(false)
            else
                // move outside of context menu area
                gui.EnableScreenClicker(true)
                self.anchor_parent = view_ingame
            end
        end
    else
        if is_context_open then
            // open in context area
            gui.EnableScreenClicker(false)
            self.anchor_parent = view_context_menu
        else
            // open outside
            gui.EnableScreenClicker(true)
            self.anchor_parent = view_ingame
        end
        dermaBase.main:SetVisible(true)
    end
    RestoreCursorPosition()
    dermaBase.main:SetParent(self.anchor_parent)
end

hook.Add('OnContextMenuOpen', 'gmpl_context_open', function()
    is_context_open = true
end)
hook.Add('OnContextMenuClose', 'gmpl_context_close', function()
    is_context_open = false
end)

hook.Add("Think","gmpl_RealTimeSeek", function()
	if !Media.breakOnStop and Media.hasValidity() and Media.hasState() == GMOD_CHANNEL_STOPPED then
		if Media.isAutoPlay() then
			if dermaBase.main.IsServerOn() then
				if dermaBase.cbadminaccess:GetChecked() then
					if Media.playerIsAdmin then
						print("stopsmart---- checked IS admin ")
						Media.stopsmart()
					else
						print("stopsmart---- checked NOT admin ")
						-- gather next song from admin
						net.Start("sv_getAutoPlaySong")
						net.SendToServer()
					end
				else --aaccess off
					print("stopsmart---- NOT checked ")
					Media.stopsmart()
				end
			else -- not server
				print("stopsmart---- NOT on server")
				Media.stopsmart()
			end
		else
			print("stopsmart---- STOP no autoplay")
			Media.stop()
		end
		Media.breakOnStop = true
	end
	if dermaBase.main:IsVisible() then
		if Media.hasValidity() then
			if dermaBase.sliderseek:isAllowed() then
				if Media.hasState() == GMOD_CHANNEL_PLAYING  then  -- real time Seek
					dermaBase.sliderseek:SetTime(Media.getTime(), false)
				elseif Media.hasState() == GMOD_CHANNEL_STALLED then
	--[[-------------------------------------------------------------------------
	This should decrease the chances of cracklings. [#bug, #happensLinux]
	---------------------------------------------------------------------------]]--
					Media.buffer()
	---------------------------------------------------------------------------]]--
				end
			elseif Media.isLooped() then
				dermaBase.sliderseek:AllowSeek(true)
				dermaBase.sliderseek:SetTime(dermaBase.sliderseek:GetMin())
			else -- audio stopped
				dermaBase.sliderseek:AllowSeek(true)
			end
		end
		if LocalPlayer():IsAdmin() ~= Media.playerIsAdmin then
			Media.playerIsAdmin = LocalPlayer():IsAdmin()
		end
		thinkServerOptions()
	end

end)

hook.Add("Tick", "gmpl_RealTimePost", function()
	if Media.breakOnStop and Media.hasValidity() and Media.hasState() ~= GMOD_CHANNEL_STOPPED then
		Media.breakOnStop = false
	end
end)


net.Receive( "refreshSongListFromServer", function(length, sender)
	folderLeft = net.ReadTable() -- also update the left list in case of becoming admin
	local newActiveTable = net.ReadTable()

	getSongList(newActiveTable)
	dermaBase.buttonrefresh:SetVisible(false)
	dermaBase.audiodirsheet:InvalidateLayout(true)
end )

net.Receive( "askAdminForLiveSeek", function(length, sender)
	local user = net.ReadEntity()
	if Media.playerIsAdmin then
		local seekTime = 0

		if Media.hasValidity() then
			seekTime = Media.getTime()
			songIndex = dermaBase.songlist:GetSelectedLine()
			net.Start("toServerUpdateSeek")
			net.WriteDouble(seekTime)
			net.SendToServer()
		else
			user:PrintMessage(HUD_PRINTTALK, "No song is playing on the server")
		end
	else
		dermaBase.labelswap:SetText("Disconnected: " .. hostAdminAccess:Nick())
		user:PrintMessage(HUD_PRINTTALK, "Cannot get Live Song. The host disconnected or it's no longer admin.")
	end
end)

net.Receive( "playLiveSeek", function(length, sender)
	local loopStatus = net.ReadBool()
	local autoplayStatus = net.ReadBool()
	hostAdminAccess = net.ReadEntity()
	song = net.ReadString()
	local numberSeek = net.ReadDouble()
	if dermaBase.main.IsServerOn() then
		sound.PlayFile(song, "noblock", function(CurrentSong, ErrorID, ErrorName)
			enableServerTSS(true)
			if IsValid(CurrentSong) then
				Media.kill()
				CurrentSong:SetTime(numberSeek)
				Media.update(CurrentSong)
				if loopStatus then
					CurrentSong:EnableLooping(true)
					Media.uiLoop()
				else
					CurrentSong:EnableLooping(false)
					Media.uiPlay()
				end
				Media.autoplay(autoplayStatus)
				dermaBase.labelswap:SetText( "Host: " .. hostAdminAccess:Nick() )
			else
				Media.uiMissing()
				dermaBase.labelswap:SetText( "Cannot play live song" )
			end
		end )
	end
end )

net.Receive( "playFromServer_adminAccess", function(length, sender)
	if dermaBase.main.IsServerOn() then
		local filePath = net.ReadString()
		hostAdminAccess = net.ReadEntity()
		Media.play(filePath)
		enableServerTSS(true)

		dermaBase.labelswap:SetText( "Host: " .. hostAdminAccess:Nick() )
		chat.AddText(Color(0,220,220),  "Playing: " .. string.StripExtension(string.GetFileFromFilename(filePath)) )
	end
end)

net.Receive( "stopFromServerAdmin", function(length, sender)
	if dermaBase.main.IsServerOn() and !Media.isMissing() then
		Media.stop()
		dermaBase.labelswap:SetText("No song currently playing")
	end
end)

net.Receive( "playFromServer", function(length, sender)
	if dermaBase.main.IsServerOn() then
		local filePath = net.ReadString()
		Media.play(filePath)
		enableServerTSS(true)
		chat.AddText(Color(0,220,220),  "Playing: " .. string.StripExtension(string.GetFileFromFilename(filePath)))
	end
end)

net.Receive( "loopFromServer", function(length, sender)
	if dermaBase.main.IsServerOn() then
		local loopState = net.ReadBool()
		if Media.hasValidity() then
			Media.setloop(loopState)
			if Media.hasState() == GMOD_CHANNEL_PLAYING then
				if loopState then
					Media.uiLoop()
				else
					Media.uiPlay()
				end
			end
		end
	end
end)

net.Receive( "cl_autoPlay", function(length, sender)
	if dermaBase.main.IsServerOn() then
		local autoplayState = net.ReadBool()
		if Media.hasValidity() then
			Media.autoplay(autoplayState)
		end
	end
end)

// TODO WORK ON adding the song table of the admin host on the server and tehn you just
//increment from that table the next song.
//If the same admin host tries to change the song check if it is the same admin and if not
//check if the song basename is the one he wants to play(the key probably wont be a good idea)
net.Receive( "cl_ansAutoPlaySong", function(length, sender)
	local nextAutoPlayedSong = net.ReadString()
	-- local currSong = populatedSongs[Media.songIndex(1, true)] or ""
	Media.uiAutoPlay()
	Media.play(nextAutoPlayedSong)
end)

net.Receive( "cl_errAutoPlaySong", function(length, sender)
	Media.stop()
end)

net.Receive( "stopFromServer", function(length, sender)
	if dermaBase.main.IsServerOn() and !Media.isMissing() then
		Media.stop()
	end
end)
net.Receive( "seekFromServer", function(length, sender)
	if dermaBase.main.IsServerOn() then
		local seekTime = net.ReadDouble()
		if Media.hasValidity() then
			Media.seek(seekTime)
		end
	end
end)

