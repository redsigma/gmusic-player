local cvarMediaVolume = CreateClientConVar("gmpl_vol", "100", true, false, "[gMusic Player] Sets the Volume of music player")

local hostAdminAccess = ""

local defaultFont = "arialDefault"
local dermaBase = {}

local stateStop = false

Media = {}
Media.__index = Media

-- private fields
local prevSelection = 0
local currSelection = 0
local colorSelected = Color(255, 255, 255)
local colorDefault = Color(0, 0, 0)


local PlayingSong
local missingSong = false
local songIsLooped = false

local playerIsAdmin = false

local tsongName = {}
local tsongFull = {}
local tmpsongPerFolder  = {}
local folderTable = {}
local folderExceptions = { "ambience", "ambient", "ambient_mp3", "beams", "buttons", "coach", "combined", "commentary", "common", "doors", "foley", "friends", "garrysmod", "hl1", "items", "midi", "misc",
                            "mvm", "test", "npc", "passtime", "phx", "physics", "pl_hoodoo", "plats", "player", "replay", "resource", "sfx", "thrusters", "tools", "ui", "vehicles", "vo", "weapons" }
local tfolderSearch = {}
local tfolderSearchActive = {}


  function Media:new(coreBase)
    dermaBase = coreBase
    local MediaPlayer = { -- public fields
    }
    
    setmetatable(MediaPlayer, Media)
    return MediaPlayer
  end
  setmetatable(Media, {  __call = Media.new  })






  function Media:SetVolume(var)
    cvarMediaVolume:SetString(var)
    dermaBase.slidervol:SetValue(var)
  end


  function setAccessCheckbox(dermaCheckBox, bool)
    if TypeID(bool) == TYPE_BOOL then
      dermaCheckBox:SetChecked(bool)
    end
  end


  function Media:SetSongHost(var)
    if TypeID(var) == TYPE_ENTITY then
      if var:IsAdmin() then
        hostAdminAccess = var
        dermaBase.labelswap:SetText( "Current Host\n" .. hostAdminAccess:Nick() )
      end
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
    -- else
      -- adminAcessRevertButtons()
    end
  end

  local function adminAccessDirChangeButton()
    if dermaBase.audiodirsheet:IsVisible() then
      if !playerIsAdmin then
        dermaBase.musicsheet:SetActiveButton(dermaBase.musicsheet.Items[1].Button)
      end
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
  	for k, v in pairs( tmpsongPerFolder ) do
  		table.insert( tsongFull, "sound/" .. path .. "/" .. v )
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

  local function getSongList( rightFoldersTable )
    clearSongs()

    for k,foldername in pairs(rightFoldersTable) do
      getSongs( foldername )
    end

  	for key, filePath in pairs( tsongFull ) do
  		dermaBase.songlist:AddLine( getSongName(filePath) ).Columns[1]:SetFont(defaultFont)
  	end
  end


  local function updateAudioObject(CurrentSong)
    if CurrentSong:IsValid() then
      PlayingSong = CurrentSong
      PlayingSong:SetVolume(dermaBase.slidervol:GetValue() / 100)
    end
  end

  local function updateListSelection()
      currSelection = dermaBase.songlist:GetSelectedLine()

      -- if it cant find the song number then better not bother coloring
      if TypeID(dermaBase.songlist:GetLines()[currSelection]) ~= TYPE_NIL then
        dermaBase.songlist:GetLines()[currSelection].Columns[1]:SetTextColor(colorSelected)
        dermaBase.songlist:GetLines()[currSelection].Columns[1].Paint = function(self, w, h)
          surface.SetDrawColor( 0, 150, 0, 255 )
          surface.DrawRect(0, 0, w, h)
        end
      end

      if TypeID(dermaBase.songlist:GetLines()[prevSelection]) ~= TYPE_NIL and prevSelection ~= currSelection then
        dermaBase.songlist:GetLines()[prevSelection].Columns[1]:SetTextColor(colorDefault)
        dermaBase.songlist:GetLines()[prevSelection].Columns[1].Paint = function() end
      end
      prevSelection = currSelection

  end

  local function stopIfRunning()
    if TypeID(PlayingSong) == TYPE_SOUNDHANDLE then
      PlayingSong:Stop()
      PlayingSong = nil
      stateStop = true
    end
  end

  function updateTitleSong(status,songFilePath)
    if status == "Playing" then
      dermaBase.main:SetBGColor(0,150,0)
      dermaBase.contextmedia:SetTitleColor(Color(0, 150, 0))
    elseif status == "Looping" then
      dermaBase.main:SetBGColor(0,255,0)
      dermaBase.contextmedia:SetTitleColor(Color(0, 255, 0))
    elseif status == "Paused" then
      dermaBase.main:SetBGColor(255,150,0)
      dermaBase.contextmedia:SetTitleColor(Color(255, 150, 0))
    else
      dermaBase.main:SetBGColor(150, 150, 150)
    end

    if songFilePath == false then
      dermaBase.main:SetTitle(" gMusic Player")
      dermaBase.contextmedia:SetTitleColor(Color(0, 0, 0))
      dermaBase.contextmedia:SetTitle(false)

    else
      if status == false then
        dermaBase.main:SetBGColor(240, 0, 0)
        dermaBase.contextmedia:SetTitleColor(Color(240, 0, 0))
        status = "Not On Disk"
      end
      dermaBase.main:SetTitle( " " .. status .. ": " .. string.StripExtension(string.GetFileFromFilename(songFilePath)))
    
      dermaBase.contextmedia:SetTitle(string.StripExtension(string.GetFileFromFilename(songFilePath)))

      return string.StripExtension(string.GetFileFromFilename(songFilePath))
    end
  end

  local function PlaySong(song)
    sound.PlayFile(song, "noblock", function(CurrentSong, ErrorID, ErrorName)
      if TypeID(CurrentSong) == TYPE_NIL then
        updateTitleSong(false,song)
        stopIfRunning()
        dermaBase.sliderseek:ResetValue()
        missingSong = true
      else
        stopIfRunning()
        CurrentSong:EnableLooping(false)
        CurrentSong:SetTime(0)
        updateAudioObject(CurrentSong)
        updateListSelection()
        updateTitleSong("Playing",song)
        dermaBase.sliderseek:SetMax(CurrentSong:GetLength())
        dermaBase.contextmedia:SetSeekLength(CurrentSong:GetLength())
        missingSong = false
        stateStop = false
      end
    end)
  end


  local function enableServerTSS(bool)
    if dermaBase.main:isDefaultTitle() then
      dermaBase.main:SetTSSEnabled(true)
    end
    if bool then
      if !dermaBase.main:isTitleServerStateOn() then
        dermaBase.main:SetTitleServerState(bool)  -- switch to Server
        dermaBase.contextmedia:SetTSS(bool)
      end
    else
      if dermaBase.main:isTitleServerStateOn() then
        dermaBase.main:SetTitleServerState(bool) -- switch to Client
        dermaBase.contextmedia:SetTSS(bool)
      end
    end
  end
  local function disableTSS()
    if !dermaBase.main:isDefaultTitle() then -- if audio not playing
      dermaBase.main:SetTSSEnabled(false)
      dermaBase.contextmedia:SetTSS(false)
    end
  end

  local function actionRefresh()
    getSongList(tfolderSearchActive)
    file.Write( "gmpl_songpath.txt", "")
    for k,v in pairs(tfolderSearchActive) do
      file.Append( "gmpl_songpath.txt", v .. "\r\n")
    end
    dermaBase.audiodirsheet:InvalidateLayout(true)
  end

  local function actionStop()
    disableTSS()
    if TypeID(PlayingSong) == TYPE_SOUNDHANDLE then
      PlayingSong:EnableLooping(false)
      isLooped = false
      stateStop = true
      PlayingSong:Pause()
      PlayingSong:SetTime(0)
      dermaBase.sliderseek:ResetValue()
      updateTitleSong(false,false)
      if TypeID(dermaBase.songlist:GetLines()[prevSelection]) ~= TYPE_NIL then
        dermaBase.songlist:GetLines()[prevSelection].Columns[1]:SetTextColor(colorDefault)
        dermaBase.songlist:GetLines()[currSelection].Columns[1].Paint = function() end

      end
    end
  end

  local function actionPauseL()
    if TypeID(PlayingSong) == TYPE_SOUNDHANDLE then
      if PlayingSong:GetState() == GMOD_CHANNEL_PLAYING then
        PlayingSong:Pause()

        updateTitleSong("Paused",PlayingSong:GetFileName())
      elseif PlayingSong:GetState() == GMOD_CHANNEL_PAUSED and !stateStop then
        PlayingSong:Play()

        if PlayingSong:IsLooping() == true then
          updateTitleSong("Looping",PlayingSong:GetFileName())
        else
          updateTitleSong("Playing",PlayingSong:GetFileName())
        end

      end
    end
  end

  local function actionPauseR()
    if TypeID(PlayingSong) == TYPE_SOUNDHANDLE and PlayingSong:GetState() == GMOD_CHANNEL_PLAYING then
      if PlayingSong:IsLooping() then
        PlayingSong:EnableLooping(false)
        songIsLooped = false
        updateTitleSong("Playing",PlayingSong:GetFileName())
      else
        PlayingSong:EnableLooping(true)
        songIsLooped = true
        updateTitleSong("Looping",PlayingSong:GetFileName())
      end
    end
  end

  local function actionPlay(songFile)
    if TypeID(PlayingSong) == TYPE_SOUNDHANDLE and PlayingSong:GetState() == GMOD_CHANNEL_PAUSED 
      and PlayingSong:GetFileName() == songFile and !stateStop then
      PlayingSong:Play()
      if PlayingSong:IsLooping() then
        updateTitleSong("Looping",songFile)
      else
        updateTitleSong("Playing",songFile)
      end
    elseif TypeID(songFile) ~= TYPE_NIL then
      PlaySong(songFile)
    end
  end

  local function actionSeek(AudioChannel, seekValue)
    if TypeID(AudioChannel) == TYPE_SOUNDHANDLE then
      if AudioChannel:GetState() ~= GMOD_CHANNEL_STALLED then
        AudioChannel:SetTime(seekValue)
      end

    else
      AudioChannel:SetTime(seekValue)
    end
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

  local function buildSearchList()
    tfolderSearch = folderTable

    for k,v in pairs(tfolderSearch) do
      for j = 1, #tfolderSearchActive do
        if rawequal(v, string.Trim(tfolderSearchActive[j]))  then
          tfolderSearch[k] = nil
          break
        end
      end
    end
  end

  local function populateFolderSearch()
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

    dermaBase.settingsheet.Paint = function(self, w, h)
      surface.SetDrawColor( 255, 255, 255, 255 )
      surface.DrawRect( 0, 0, w, h )
      surface.SetDrawColor( 20, 150, 240, 255 )
      surface.DrawOutlinedRect( w-1, 0, w, h )
      surface.DrawOutlinedRect( 0, 0, w, 1 )
    end

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
    buildSearchList()
    populateFolderSearch()
    getSongList(tfolderSearchActive)
  end 


  local function createMediaPlayer()  

    dermaBase.main:SetSizeDynamic(120,300)
    dermaBase.main:SetPos(16, 36)
    dermaBase.main:SetTitle(" gMusic Player")
    dermaBase.main:SetDraggable(true)
    dermaBase.main:SetSizable(true)

    dermaBase.contextmedia:SetTitle(false)

    local mainX, mainY = dermaBase.main:GetSize()


    dermaBase.musicsheet:SetPos(0,20)
    dermaBase.musicsheet:SetSize(mainX, mainY - 80 )
    dermaBase.musicsheet.Navigation:Dock( RIGHT )
    dermaBase.musicsheet.Navigation:DockMargin( 0, 0, 0, 0 )
    dermaBase.musicsheet.Navigation:SetVisible(false)


    dermaBase.settingPage:Dock(FILL)
    dermaBase.settingPage:DockPadding(0, 0, 0, 10)


    dermaBase.audiodirsheet:Dock(FILL)
    dermaBase.audiodirsheet:DockMargin( 0, 0, 0, 0 )


    dermaBase.songlist:SetDataHeight( 20 ) 
    dermaBase.songlist:Dock(FILL)
    dermaBase.songlist:SetMultiSelect( false )
    dermaBase.songlist:AddColumn( "Song" ).Header.Paint = function(self, w, h)
      surface.SetDrawColor( 20, 150, 240, 255  )
      surface.DrawRect(0, 0, w, h)
      self:SetFont(defaultFont)
      self:SetTextColor(Color(255,255,255))
    end

    dermaBase.labelrefresh:Dock(TOP)
    dermaBase.labelrefresh:SetHeight(44)
    dermaBase.labelrefresh.Paint = function(self, w, h)
      draw.DrawText( "Select the folders from ROOT that are going to be added. ROOT: garrysmod\\sound\\ \nIt will also add the content of the first folders found inside them.", "default", w * 0.5, h * 0.10, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
      draw.DrawText( "Right Click to deselect | (Ctrl or Shift)+Click for multiple selections", "default", w * 0.5, h * 0.66, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
    end

    dermaBase.buttonrefresh:Dock(BOTTOM)
    dermaBase.buttonrefresh:SetFont(defaultFont)
    dermaBase.buttonrefresh:SetText("Press to refresh the Song List")
    dermaBase.buttonrefresh:SetTextColor(Color(255,255,255))
    dermaBase.buttonrefresh:SetSize(mainX / 3,30)
    dermaBase.buttonrefresh:SetVisible(false)


    dermaBase.buttonswap:SetSize(mainX / 3,30)
    dermaBase.buttonswap:SetPos(0,  dermaBase.musicsheet:GetTall() + 20)

    dermaBase.labelswap:SetFont(defaultFont)
    dermaBase.labelswap:SetTextColor(Color(255,255,255))
    dermaBase.labelswap:Dock(FILL)
    dermaBase.labelswap:DockMargin(6,1,0,0)
    if TypeID(hostAdminAccess) == TYPE_ENTITY then
      dermaBase.labelswap:SetText( "Current Host\n" .. hostAdminAccess:Nick() )
    else
      dermaBase.labelswap:SetText( "No song currently playing" )
    end


    dermaBase.buttonstop:SetFont(defaultFont)
    dermaBase.buttonstop:SetTextColor(Color(255,255,255))
    dermaBase.buttonstop:SetText("Stop")
    dermaBase.buttonstop:SetSize(mainX / 3,30)
    dermaBase.buttonstop:SetPos(0,  dermaBase.musicsheet:GetTall() + 20)


    dermaBase.buttonpause:SetFont(defaultFont)
    dermaBase.buttonpause:SetTextColor(Color(255,255,255))
    dermaBase.buttonpause:SetText("Pause / Loop")
    dermaBase.buttonpause:SetSize(dermaBase.buttonstop:GetWide(),dermaBase.buttonstop:GetTall())
    dermaBase.buttonpause:SetPos(dermaBase.buttonstop:GetWide(), dermaBase.musicsheet:GetTall() + 20)


    dermaBase.buttonplay:SetFont(defaultFont)
    dermaBase.buttonplay:SetTextColor(Color(255,255,255))
    dermaBase.buttonplay:SetText("Play")
    dermaBase.buttonplay:SetSize(mainX - (dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide()), dermaBase.buttonstop:GetTall())
    dermaBase.buttonplay:SetPos(dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide(), dermaBase.musicsheet:GetTall() + 20)


    dermaBase.sliderseek:SetSize(mainX - 150 ,30)
    dermaBase.sliderseek:SetPos(0 , dermaBase.main:GetTall() - dermaBase.sliderseek:GetTall())
    dermaBase.sliderseek:AlignBottom()
    dermaBase.sliderseek.Slider.Knob:SetHeight(dermaBase.sliderseek:GetTall())
    dermaBase.sliderseek.Slider.Knob:SetWide(5)
    dermaBase.sliderseek:SetTextFont(defaultFont)
    dermaBase.sliderseek:SetTextColor(255,255,255)
    dermaBase.sliderseek:ShowSeekTime()
    dermaBase.sliderseek:ShowSeekLength()



    dermaBase.slidervol:SetFont(defaultFont)
    dermaBase.slidervol:SetTextColor(Color(255,255,255))
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
        if !missingSong then
          actionStop()
        end
      end
    end

    dermaBase.buttonpause.DoClick = function()
      actionPauseL()
    end

    dermaBase.buttonpause.DoRightClick  = function()
      if dermaBase.main.IsServerOn() then
        if dermaBase.cbadminaccess:GetbID() then
          if playerIsAdmin then
            actionPauseR()
            net.Start("toServerUpdateLoop")
            net.WriteBool(songIsLooped)
            net.SendToServer()
          end
        else
          actionPauseR()
          net.Start("toServerUpdateLoop")
          net.WriteBool(songIsLooped)
          net.SendToServer()
        end
      else
        actionPauseR()
      end
    end

    dermaBase.buttonplay.DoClick = function( songFile )
      if TypeID(dermaBase.songlist:GetSelectedLine()) == TYPE_NUMBER then
        if !isstring(songFile) then
          songFile = tsongFull[dermaBase.songlist:GetSelectedLine()]
        end
        if dermaBase.main.IsServerOn() then
          net.Start( "toServerAdminPlay" )
          net.WriteString(songFile)
          net.SendToServer()
        else
          actionPlay(songFile)
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


    dermaBase.slidervol.OnValueChanged = function(Panel, Value)
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE then
        PlayingSong:SetVolume(dermaBase.slidervol:GetValue() / 100)
      end
    end


    dermaBase.foldersearch.OnRebuild = function()
      if dermaBase.cbadmindir:GetbID() then
        if playerIsAdmin then
          initLeftList()
          buildSearchList()
          populateFolderSearch()
          dermaBase.foldersearch:selectFirstLine()
        end
      else
        initLeftList()
        buildSearchList()
        populateFolderSearch()
        dermaBase.foldersearch:selectFirstLine()
      end
    end

    dermaBase.foldersearch.OnAdd = function()
      if dermaBase.cbadmindir:GetbID() then
        if playerIsAdmin then
          dermaBase.foldersearch:selectFirstLine()
          dermaBase.buttonrefresh:SetVisible(true)
       
          tfolderSearch = dermaBase.foldersearch:populateLeftList()
          tfolderSearchActive = dermaBase.foldersearch:populateRightList()
        end
      else
        dermaBase.foldersearch:selectFirstLine()
        dermaBase.buttonrefresh:SetVisible(true)
     
        tfolderSearch = dermaBase.foldersearch:populateLeftList()
        tfolderSearchActive = dermaBase.foldersearch:populateRightList()
      end
    end

    dermaBase.foldersearch.OnRemove = function()
      if dermaBase.cbadmindir:GetbID() then
        if playerIsAdmin then
          dermaBase.foldersearch:selectFirstLine()
          dermaBase.buttonrefresh:SetVisible(true)

          tfolderSearch = dermaBase.foldersearch:populateLeftList()
          tfolderSearchActive = dermaBase.foldersearch:populateRightList()
        end
      else
        dermaBase.foldersearch:selectFirstLine()
        dermaBase.buttonrefresh:SetVisible(true)

        tfolderSearch = dermaBase.foldersearch:populateLeftList()
        tfolderSearchActive = dermaBase.foldersearch:populateRightList()
      end
    end


    dermaBase.songlist.DoDoubleClick = function(lineIndex, line)
        songFile = tsongFull[lineIndex]
        dermaBase.buttonplay.DoClick(songFile)
    end

    dermaBase.sliderseek.SeekClick.OnValueChanged = function(seekClickLayer)
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE then

        if dermaBase.main.IsServerOn() then
          if !dermaBase.cbadminaccess:GetbID() then
            if PlayingSong:GetState() == GMOD_CHANNEL_PAUSED then
              actionSeek(PlayingSong, dermaBase.sliderseek:GetValue())
              actionSeek(dermaBase.sliderseek, PlayingSong:GetTime())
            end
            net.Start( "toServerSeek" )
            net.WriteDouble( dermaBase.sliderseek:GetValue() )
            net.SendToServer()
          elseif playerIsAdmin then
            if PlayingSong:GetState() == GMOD_CHANNEL_PAUSED then
              actionSeek(PlayingSong, dermaBase.sliderseek:GetValue())
              actionSeek(dermaBase.sliderseek, PlayingSong:GetTime())
            end
            net.Start( "toServerSeek" )
            net.WriteDouble( dermaBase.sliderseek:GetValue() )
            net.SendToServer()
          end
        else
          if PlayingSong:GetState() == GMOD_CHANNEL_PAUSED then
            actionSeek(PlayingSong, dermaBase.sliderseek:GetValue())
            actionSeek(dermaBase.sliderseek, PlayingSong:GetTime())
          else
            actionSeek(PlayingSong, dermaBase.sliderseek:GetValue())
          end
        end

      end
    end




    dermaBase.main.OnLayoutChange = function()
      dermaBase.musicsheet:SetSize(dermaBase.main:GetWide(), dermaBase.main:GetTall() - 80 )

      dermaBase.buttonstop:SetSize(dermaBase.main:GetWide() / 3,30)
      dermaBase.buttonstop:SetPos(0,  dermaBase.musicsheet:GetTall() + 20)

      dermaBase.buttonswap:SetSize(dermaBase.main:GetWide() / 3,30)
      dermaBase.buttonswap:SetPos(0,  dermaBase.musicsheet:GetTall() + 20)

      dermaBase.buttonpause:SetSize(dermaBase.buttonstop:GetWide(),dermaBase.buttonstop:GetTall())
      dermaBase.buttonpause:SetPos(dermaBase.buttonstop:GetWide(), dermaBase.musicsheet:GetTall() + 20)

      dermaBase.buttonplay:SetSize(dermaBase.main:GetWide() - (dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide()), dermaBase.buttonstop:GetTall())
      dermaBase.buttonplay:SetPos(dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide(), dermaBase.musicsheet:GetTall() + 20)

      dermaBase.sliderseek:SetSize(dermaBase.main:GetWide() - 150 ,30)
      dermaBase.sliderseek:SetPos(0, dermaBase.main:GetTall() - dermaBase.sliderseek:GetTall())

      dermaBase.slidervol:SetSize(dermaBase.main:GetWide()  - dermaBase.sliderseek:GetWide() - 5, 30)
      dermaBase.slidervol:SetPos(dermaBase.sliderseek:GetWide() , dermaBase.main:GetTall() - dermaBase.slidervol:GetTall())
    end

    dermaBase.main.OnResizing = function()
      dermaBase.musicsheet:SetVisible(false)
    end
    dermaBase.main.AfterResizing = function()
      if !dermaBase.musicsheet:IsVisible() then
        dermaBase.musicsheet:SetVisible(true)
      end
    end

    dermaBase.main.OnSettingsClick = function()
      if dermaBase.musicsheet.Navigation:IsVisible() then
        dermaBase.musicsheet.Navigation:SetVisible(false)
        dermaBase.musicsheet:InvalidateLayout(true)
      else
        dermaBase.musicsheet.Navigation:SetVisible(true)
      end
    end
    dermaBase.main.OnModeChanged = function()
      if !dermaBase.main.IsServerOn() then
        adminAcessRevertButtons()
      end
    end


    dermaBase.contextmedia.OnThink = function()
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE then
        if PlayingSong:GetState() == GMOD_CHANNEL_PLAYING then
          dermaBase.contextmedia:SetSeekTime(PlayingSong:GetTime())
        end
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
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE then
       
          if PlayingSong:GetState() == GMOD_CHANNEL_PLAYING  then
            actionSeek(dermaBase.sliderseek, PlayingSong:GetTime())  -- real time Seek
            
          elseif PlayingSong:GetState() == GMOD_CHANNEL_STALLED then
--[[-------------------------------------------------------------------------
This should decrease the chances of cracklings. [#bug, #happensLinux]
---------------------------------------------------------------------------]]--
            PlayingSong:Pause()
            if PlayingSong:GetState() ~= GMOD_CHANNEL_STALLED then
              PlayingSong:Play()
            end
---------------------------------------------------------------------------]]--

          elseif PlayingSong:GetState() == GMOD_CHANNEL_STOPPED and !isLooped then
            PlayingSong:EnableLooping(false)
            isLooped = false
            dermaBase.sliderseek:ResetValue()
            updateTitleSong(false,false)

          end
      end

      if LocalPlayer():IsAdmin() ~= playerIsAdmin then
        playerIsAdmin = LocalPlayer():IsAdmin()
      end

      thinkServerOptions()

    end
  end )

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
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE then
        seekTime = PlayingSong:GetTime()
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
        if TypeID(CurrentSong) ~= TYPE_NIL then
          stopIfRunning()

          CurrentSong:SetTime(numberSeek)
          updateAudioObject(CurrentSong)

          dermaBase.sliderseek:SetMax(CurrentSong:GetLength())
          dermaBase.contextmedia:SetSeekLength(CurrentSong:GetLength())
          missingSong = false
          if loopStatus then
              CurrentSong:EnableLooping(true)
              updateTitleSong("Looping",song)
          else
            CurrentSong:EnableLooping(false)
            updateTitleSong("Playing",song)
          end
          dermaBase.labelswap:SetText( "Current Host\n" .. hostAdminAccess:Nick() )
        else
          updateTitleSong(false,song)
          missingSong = true
          dermaBase.labelswap:SetText( "Cannot play live song" )
        end
      end )
    end
  end )

  net.Receive( "playFromServer_adminAccess", function(length, sender)
    if dermaBase.main.IsServerOn() then
      local filePath = net.ReadString()
      hostAdminAccess = net.ReadEntity()
      PlaySong(filePath)
      enableServerTSS(true)

      dermaBase.labelswap:SetText( "Current Host\n" .. hostAdminAccess:Nick() )
      chat.AddText(Color(0,255,255),  "Playing: " .. string.StripExtension(string.GetFileFromFilename(filePath)) )
    end
  end)

  net.Receive( "stopFromServerAdmin", function(length, sender)
    if dermaBase.main.IsServerOn() and missingSong == false then
      actionStop()
      dermaBase.labelswap:SetText("No song currently playing")
    end
  end)

  net.Receive( "playFromServer", function(length, sender)
    if dermaBase.main.IsServerOn() then
      local filePath = net.ReadString()
      PlaySong(filePath)
      enableServerTSS(true)
      chat.AddText(Color(0,255,255),  "Playing: " .. string.StripExtension(string.GetFileFromFilename(filePath)))
    end
  end)
  net.Receive( "loopFromServer", function(length, sender)
    if dermaBase.main.IsServerOn() then
      local loopState = net.ReadBool()
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE then
        PlayingSong:EnableLooping(loopState)
        if PlayingSong:GetState() == GMOD_CHANNEL_PLAYING then
          if loopState then
            updateTitleSong("Looping",PlayingSong:GetFileName())
          else
            updateTitleSong("Playing",PlayingSong:GetFileName())
          end
        end
      end
    end
  end)

  net.Receive( "stopFromServer", function(length, sender)
    if dermaBase.main.IsServerOn() and missingSong == false then
      actionStop()
    end
  end)
  net.Receive( "seekFromServer", function(length, sender)
    if dermaBase.main.IsServerOn() then
      local seekTime = net.ReadDouble()
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE then
        actionSeek(PlayingSong, seekTime)
      end
    end
  end)
