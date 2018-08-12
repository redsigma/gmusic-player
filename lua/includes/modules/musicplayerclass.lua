local cvarMediaVolume = CreateClientConVar("gmpl_vol", "100", true, false, "[gMusic Player] Sets the Volume of music player")

local hostAdminAccess = ""
local defaultFont = "arialDefault"
local dermaBase = {}

Media = {}
Media.__index = Media

-- private fields
local playerIsAdmin = false

local tsongName = {}
local tsongFull = {}
local tmpsongPerFolder  = {}
local folderTable = {}
local folderExceptions = { "ambience", "ambient", "ambient_mp3", "beams", "buttons", "coach", "combined", "commentary", "common", "doors", "foley", "friends", "garrysmod", "hl1", "items", "midi",
							"misc", "mvm", "test", "npc", "passtime", "phx", "physics", "pl_hoodoo", "plats", "player", "replay", "resource", "sfx", "thrusters", "tools", "ui", "vehicles", "vo", "weapons" }
local tfolderSearch = {}
local tfolderSearchActive = {}

function Media:new(coreBase)
	dermaBase = coreBase
	local MediaPlayer = setmetatable({}, Media)
	local action = include("includes/func/audio.lua")(dermaBase)
	for k,v in pairs(action) do self[k] = v end
	return MediaPlayer
end
setmetatable(Media, {  __call = Media.new })


function Media:SetVolume(var)
	cvarMediaVolume:SetString(var)
	dermaBase.slidervol:SetValue(var)
end


function setAccessCheckbox(dermaCheckBox, bool)
	if isbool(bool) then
		dermaCheckBox:SetChecked(bool)
	end
end


function Media:SetSongHost(var)
	if isentity(var) and var:IsAdmin() then
		hostAdminAccess = var
		dermaBase.labelswap:SetText( "Current Host\n" .. hostAdminAccess:Nick() )
	end
end


--[[-------------------------------------------------------------------------
Methods Used For Server Options -- Runs in think
---------------------------------------------------------------------------]]--
local function adminAcessRevertButtons()
	dermaBase.buttonplay:SetText("Play")
	dermaBase.buttonpause:SetText("Pause / Loop")
	dermaBase.buttonstop:SetVisible(true)
	dermaBase.buttonswap:SetVisible(false)
end

local function adminAcessChangeButtons()
	if dermaBase.cbadminaccess:GetbID() then   -- make sure the checkbox is on
		dermaBase.buttonplay:SetText("Resume Live")
		dermaBase.buttonpause:SetText("Pause")
		dermaBase.buttonstop:SetVisible(false)
		dermaBase.buttonswap:SetVisible(true)
	end
end

local function adminAccessDirChangeButton()
	if dermaBase.audiodirsheet:IsVisible() and !playerIsAdmin then
		dermaBase.musicsheet:SetActiveButton(dermaBase.musicsheet.Items[1].Button)
	end

	if playerIsAdmin then
		if dermaBase.musicsheet.Items[2].Button:GetDisabled() then
			dermaBase.musicsheet.Items[2].Button:SetEnabled(true)
		end
	elseif !dermaBase.musicsheet.Items[2].Button:GetDisabled() then
		dermaBase.musicsheet.Items[2].Button:SetEnabled(false)
	end
end

local function adminAccessDirRevertButton()
	if dermaBase.musicsheet.Items[2].Button:GetDisabled() then
		dermaBase.musicsheet.Items[2].Button:SetEnabled(true)
	end
end

local function thinkServerOptions()
	if dermaBase.main.IsServerOn() then
		if !playerIsAdmin then
			adminAcessChangeButtons()
		else
			adminAcessRevertButtons()
		end
	end

	if dermaBase.cbadmindir:GetbID() then
		adminAccessDirChangeButton()
	else
		adminAccessDirRevertButton()
	end
end
---------------------------------------------------------------------------]]--

local function getSongName( filePath )
	table.Empty(tsongName)
	tsongName = string.Explode( "/", filePath )

	return string.StripExtension(tsongName[#tsongName])
end

local function getSongs( path )
	path = string.Trim(path)
	tmpsongPerFolder, folderTable = file.Find( "sound/" .. path .. "/*", "GAME" )

	for k, songName in pairs( tmpsongPerFolder ) do
		table.insert( tsongFull, "sound/" .. path .. "/" .. songName )
	end

	for key, folderName in pairs( folderTable ) do  -- also scan within the first folders
		tmpsongPerFolder = file.Find( "sound/" .. path .. "/" .. folderName .. "/*", "GAME" )

		for key2, songName in pairs( tmpsongPerFolder ) do
		table.insert( tsongFull, "sound/" .. path .. "/" .. folderName .. "/" .. songName )
		end
	end
end

local function clearSongs()
	table.Empty(tsongFull) table.Empty(tmpsongPerFolder)
	dermaBase.songlist:Clear()
end

local function getSongList( soundDirs )
	clearSongs()

	for k,foldername in pairs(soundDirs) do
		getSongs( foldername )
	end

	for key, filePath in pairs( tsongFull ) do
		dermaBase.songlist:AddLine( getSongName(filePath))
	end
end

local function enableServerTSS(bool)
	if !dermaBase.main:isTSS() then
		dermaBase.main:SetTSSEnabled(true)
	end

	dermaBase.main:SetTitleServerState(bool)  -- switch to Client/Server
	dermaBase.contextmedia:SetTSS(bool)
end


local function actionRefresh()
	getSongList(tfolderSearchActive)
	file.Write( "gmpl_songpath.txt", "")
	for k,v in pairs(tfolderSearchActive) do
		file.Append( "gmpl_songpath.txt", v .. "\r\n")
	end
	dermaBase.audiodirsheet:InvalidateLayout(true)
end


local function initLeftList()
	table.Empty(folderTable)

	tmpsongPerFolder, folderTable = file.Find( "sound/*", "GAME" )
	local folderWTable
	tmpsongPerFolder, folderWTable = file.Find( "sound/*", "WORKSHOP" )
	table.Add(folderTable, folderWTable)  table.Empty(folderWTable)

	for k,v in pairs(folderTable) do
		for j = 0, #folderExceptions do
			if v == folderExceptions[j] then
				folderTable[k] = nil
			end
		end
	end
	folderTable = table.ClearKeys(folderTable)
end

local function sanityCheckActiveList()
	tfolderSearch = folderTable

	for k,v in pairs(tfolderSearch) do
		for j = 1, #tfolderSearchActive do
			-- remove songDir from searchList if in activeList
			if rawequal(v, string.Trim(tfolderSearchActive[j]))  then
				tfolderSearch[k] = nil
				break
			end
		end
	end
	--Check if current actives are not found
	for j = 1, #tfolderSearchActive do
		if !file.Exists( "sound/" .. string.Trim(tfolderSearchActive[j]), "GAME" ) then
			tfolderSearchActive[j] = nil
		end
	end
end

local function populateMusicDir()
	dermaBase.foldersearch:clearLeft()
	dermaBase.foldersearch:clearRight()
	for key,foldername in pairs(tfolderSearch) do
		dermaBase.foldersearch:AddLineLeft(foldername)
	end
	for key,foldername in pairs(tfolderSearchActive) do
		dermaBase.foldersearch:AddLineRight(foldername)
	end
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
	getSongList(tfolderSearchActive)
end

local function createMediaPlayer()
	dermaBase.main:SetPos(16, 36)
	dermaBase.main:SetTitle(" gMusic Player")
	dermaBase.main:SetDraggable(true)
	dermaBase.main:SetSizable(true)

	dermaBase.contextmedia:SetTitle(false)
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
		dermaBase.labelswap:SetText( "Current Host\n" .. hostAdminAccess:Nick() )
	else
		dermaBase.labelswap:SetText( "No song currently playing" )
	end

	dermaBase.buttonstop:SetFont(defaultFont)
	dermaBase.buttonstop:SetText("Stop")
	dermaBase.buttonstop:SetSize(mainX / 3,30)
	dermaBase.buttonstop:SetPos(0,  dermaBase.musicsheet:GetTall() + 20)

	dermaBase.buttonpause:SetFont(defaultFont)
	dermaBase.buttonpause:SetText("Pause / Loop")
	dermaBase.buttonpause:SetSize(dermaBase.buttonstop:GetWide(),dermaBase.buttonstop:GetTall())
	dermaBase.buttonpause:SetPos(dermaBase.buttonstop:GetWide(), dermaBase.musicsheet:GetTall() + 20)

	dermaBase.buttonplay:SetFont(defaultFont)
	dermaBase.buttonplay:SetText("Play")
	dermaBase.buttonplay:SetSize(mainX - (dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide()), dermaBase.buttonstop:GetTall())
	dermaBase.buttonplay:SetPos(dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide(), dermaBase.musicsheet:GetTall() + 20)

	dermaBase.sliderseek:SetSize(mainX - 150 ,30)
	dermaBase.sliderseek:SetPos(0 , dermaBase.main:GetTall() - dermaBase.sliderseek:GetTall())
	dermaBase.sliderseek:AlignBottom()
	dermaBase.sliderseek.Slider.Knob:SetHeight(dermaBase.sliderseek:GetTall())
	dermaBase.sliderseek.Slider.Knob:SetWide(5)
	dermaBase.sliderseek:SetTextFont(defaultFont)
	dermaBase.sliderseek:ShowSeekTime()
	dermaBase.sliderseek:ShowSeekLength()

	dermaBase.slidervol:SetFont(defaultFont)
	dermaBase.slidervol:SetSize(mainX - dermaBase.sliderseek:GetWide() - 5, 30)
	dermaBase.slidervol:SetPos(dermaBase.sliderseek:GetWide() , mainY - dermaBase.slidervol:GetTall())
	dermaBase.slidervol:AlignBottom()
	dermaBase.slidervol:SetConVar("gmpl_vol")
	dermaBase.slidervol:SetValue(cvarMediaVolume:GetFloat())

	dermaBase.musicsheet.Items[2].Button.DoClick = function(self)
		dermaBase.foldersearch:selectFirstLine()
		if !dermaBase.audiodirsheet:IsVisible() then
			dermaBase.musicsheet:SetActiveButton(self)
		end
	end

	dermaBase.buttonrefresh.DoClick = function(self)
		if dermaBase.cbadmindir:GetbID() then
			if playerIsAdmin then
				net.Start("toServerRefreshSongList")

				net.WriteTable(tfolderSearch)
				net.WriteTable(tfolderSearchActive)
				net.SendToServer()
			end
		else
			self:SetVisible(false)
			actionRefresh()
		end
	end

	dermaBase.buttonstop.DoClick = function()
		if dermaBase.main.IsServerOn() then
			if !dermaBase.cbadminaccess:GetbID() then
				net.Start( "toServerStop" )
				net.SendToServer()
			elseif playerIsAdmin then
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

	dermaBase.buttonpause.DoRightClick  = function()
		if dermaBase.main.IsServerOn() then
			if dermaBase.cbadminaccess:GetbID() then
				if playerIsAdmin then
					Media.loop()
					net.Start("toServerUpdateLoop")
					net.WriteBool(Media.isLooped())
					net.SendToServer()
				end
			else
				Media.loop()
				net.Start("toServerUpdateLoop")
				net.WriteBool(Media.isLooped())
				net.SendToServer()
			end
		else
			Media.loop()
		end
	end

	dermaBase.buttonplay.DoClick = function( songFile )
		if isnumber(dermaBase.songlist:GetSelectedLine()) then
			if !isstring(songFile) then
				songFile = tsongFull[dermaBase.songlist:GetSelectedLine()]
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
			if !( dermaBase.main.IsServerOn() and  !playerIsAdmin and dermaBase.cbadminaccess:GetbID() ) then
				chat.AddText( Color(255,0,0),"[gMusic Player] Please select a song")
			else
				net.Start( "toServerAdminPlay" )
				net.WriteString("")
				net.SendToServer()
			end
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
		if dermaBase.cbadmindir:GetbID() then
			if playerIsAdmin then
				initLeftList()
				sanityCheckActiveList()
				populateMusicDir()
				panel:selectFirstLine()
			end
		else
			initLeftList()
			sanityCheckActiveList()
			populateMusicDir()
			panel:selectFirstLine()
		end
	end

	dermaBase.foldersearch.OnAdd = function(panel)
		if dermaBase.cbadmindir:GetbID() then
			if playerIsAdmin then
				panel:selectFirstLine()
				dermaBase.buttonrefresh:SetVisible(true)

				tfolderSearch = dermaBase.foldersearch:populateLeftList()
				tfolderSearchActive = dermaBase.foldersearch:populateRightList()
			end
		else
			panel:selectFirstLine()
			dermaBase.buttonrefresh:SetVisible(true)

			tfolderSearch = dermaBase.foldersearch:populateLeftList()
			tfolderSearchActive = dermaBase.foldersearch:populateRightList()
		end
	end

	dermaBase.foldersearch.OnRemove = function(panel)
		if dermaBase.cbadmindir:GetbID() then
			if playerIsAdmin then
				panel:selectFirstLine()
				dermaBase.buttonrefresh:SetVisible(true)

				tfolderSearch = panel:populateLeftList()
				tfolderSearchActive = panel:populateRightList()
			end
		else
			panel:selectFirstLine()
			dermaBase.buttonrefresh:SetVisible(true)

			tfolderSearch = panel:populateLeftList()
			tfolderSearchActive = panel:populateRightList()
		end
	end


	dermaBase.songlist.DoDoubleClick = function(lineIndex, line)
		songFile = tsongFull[lineIndex]
		dermaBase.buttonplay.DoClick(songFile)
	end

	dermaBase.sliderseek.SeekClick.OnValueChanged = function(seekClickLayer, seekSecs)
		if Media.hasValidity() then
			if dermaBase.main.IsServerOn() then
				if !dermaBase.cbadminaccess:GetbID() then
					if Media.hasState() == GMOD_CHANNEL_PAUSED then
						Media.seek(seekSecs)
						dermaBase.sliderseek:SetTime(seekSecs)
					end
					net.Start("toServerSeek")
					net.WriteDouble(seekSecs)
					net.SendToServer()
				elseif playerIsAdmin then
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

		dermaBase.buttonpause:SetSize(dermaBase.buttonstop:GetWide(),dermaBase.buttonstop:GetTall())
		dermaBase.buttonpause:SetPos(dermaBase.buttonstop:GetWide(), songHeight + 20)

		dermaBase.buttonplay:SetSize(panel:GetWide() - (dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide()), dermaBase.buttonstop:GetTall())
		dermaBase.buttonplay:SetPos(dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide(), songHeight + 20)

		dermaBase.sliderseek:SetSize(panel:GetWide() - 150 ,30)
		dermaBase.sliderseek:SetPos(0, mainTall - dermaBase.sliderseek:GetTall())

		dermaBase.slidervol:SetSize(panel:GetWide()  - dermaBase.sliderseek:GetWide() - 5, 30)
		dermaBase.slidervol:SetPos(dermaBase.sliderseek:GetWide() , mainTall - dermaBase.slidervol:GetTall())
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
	return tfolderSearch
end

function Media:getRightSongList()
	return tfolderSearchActive
end

function Media:readFileSongs()
	if file.Exists( "gmpl_songpath.txt", "DATA" ) then
		local fileRead = string.Explode("\n", file.Read( "gmpl_songpath.txt", "DATA" ))
		for i = 1, #fileRead - 1 do
			tfolderSearchActive[i] = fileRead[i]
		end
	end
end

function Media:SyncSettings(ply)
	dermaBase.settingPage:SyncItems(ply)
end

function Media:create()
	createMain()
	createMediaPlayer()
end


hook.Add("Think","RealTimeSeek", function()
	if dermaBase.main:IsVisible() then
		if Media.hasValidity() then
			if dermaBase.sliderseek:isAllowed() then
				if Media.hasState() == GMOD_CHANNEL_PLAYING  then  -- real time Seek
					dermaBase.sliderseek:SetTime(Media.getTime())
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
			else
				Media.stop()
				dermaBase.sliderseek:AllowSeek(true)
			end
		end
		if LocalPlayer():IsAdmin() ~= playerIsAdmin then
			playerIsAdmin = LocalPlayer():IsAdmin()
		end
		thinkServerOptions()
	end
end)

--[[-------------------------------------------------------------------------
Settings Page on each Client
---------------------------------------------------------------------------]]--
net.Receive( "refreshAdminAccess", function(length, sender)
	local tmpVal = net.ReadBool()
	setAccessCheckbox(dermaBase.cbadminaccess,tmpVal)
end )

net.Receive( "refreshAdminAccessDir", function(length, sender)
	local tmpVal = net.ReadBool()
	setAccessCheckbox(dermaBase.cbadmindir,tmpVal)
end )
---------------------------------------------------------------------------]]--

net.Receive( "refreshSongListFromServer", function(length, sender)
	tfolderSearch = net.ReadTable() -- also update the left list in case of becoming admin
	local newActiveTable = net.ReadTable()

	getSongList(newActiveTable)
	dermaBase.buttonrefresh:SetVisible(false)
	dermaBase.audiodirsheet:InvalidateLayout(true)
end )

net.Receive( "askAdminForLiveSeek", function(length, sender)
	local user = net.ReadEntity()
	if playerIsAdmin then
		local seekTime = 0
		if Media.hasValidity() then
			seekTime = Media.getTime()
			net.Start("toServerUpdateSeek")
			net.WriteDouble(seekTime)
			net.SendToServer()
		else
			user:PrintMessage(HUD_PRINTTALK, "No song is playing on the server")
		end
	else
		user:PrintMessage(HUD_PRINTTALK, "Cannot get Live Song. The host probably disconnected or not admin anymore.")
	end
end)

net.Receive( "playLiveSeek", function(length, sender)
	local loopStatus = net.ReadBool()
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
				dermaBase.labelswap:SetText( "Current Host\n" .. hostAdminAccess:Nick() )
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
		dermaBase.labelswap:SetText( "Current Host\n" .. hostAdminAccess:Nick() )
		chat.AddText(Color(0,255,255),  "Playing: " .. string.StripExtension(string.GetFileFromFilename(filePath)) )
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
		chat.AddText(Color(0,255,255),  "Playing: " .. string.StripExtension(string.GetFileFromFilename(filePath)))
	end
end)

net.Receive( "loopFromServer", function(length, sender)
	if dermaBase.main.IsServerOn() then
		local loopState = net.ReadBool()
		if Media.hasValidity() then
			Media.forceloop(loopState)
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
