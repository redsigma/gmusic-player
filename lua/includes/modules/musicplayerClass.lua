local cvarMediaVolume = CreateClientConVar("gmpl_vol", "100", true)

Media = {}
Media.__index = Media
-- private fields
local PlayingSong
local MP_Volume
local MP_Seek
local songNameTable = {}
local songTableFull = {}
local songTablePerFolder  = {}
local folderTable = {}

  function Media:new(nr)
    local MediaPlayer = {
      -- public fields
      nr = nr or 0,
    }
    setmetatable(MediaPlayer, Media)
    return MediaPlayer
  end


  function Media:SetVolume(var)
    cvarMediaVolume:SetString(var)
    MP_Volume:SetValue(var)
  end


  local function getSongName( filePath )
    table.Empty(songNameTable)
    songNameTable = string.Explode( "/", filePath )

    return string.StripExtension(songNameTable[#songNameTable])
  end


  local function getSongs( path )
    table.Empty(songTablePerFolder) table.Empty(folderTable)
  	songTablePerFolder, folderTable = file.Find( "sound/" .. path .. "/*", "GAME" )

  	for k, v in pairs( songTablePerFolder ) do
  		table.insert( songTableFull, "sound/" .. path .. "/" .. v )
  	end

  	for key, folderName in pairs( folderTable ) do  -- also scan within the first folders
      songTablePerFolder = file.Find( "sound/" .. path .. "/" .. folderName .. "/*", "GAME" )

      for key2, songName in pairs( songTablePerFolder ) do
        table.insert( songTableFull, "sound/" .. path .. "/" .. folderName .. "/" .. songName )
      end
  	end
  end


  local function getSongList()
  	table.Empty(songTableFull)
  	SongList:Clear()
  	getSongs( "radiosongs" )

  	for key, v in pairs( songTableFull ) do
  		SongList:AddLine( getSongName(v) )
  	end
  end


  local function getData(CurrentSong)
    if (TypeID(CurrentSong) == TYPE_SOUNDHANDLE and CurrentSong:IsValid()) then
      PlayingSong = CurrentSong
      PlayingSong:SetVolume(MP_Volume:GetValue() / 100)
    end
  end

  local function stopIfRunning()
    if TypeID(PlayingSong) == TYPE_SOUNDHANDLE and PlayingSong:IsValid() then
      PlayingSong:Stop()
    end
  end

  local function PlaySong(song)
    sound.PlayFile(song, "noblock", function(CurrentSong, ErrorID, ErrorName)
      stopIfRunning()
      getData(CurrentSong)
      MP_Seek:SetMax(CurrentSong:GetLength())
    end)
  end


  local function updateTitleSong(status,songFilePath)
    if songFilePath == false and songFilePath == false then
      Main:SetBGColor(150, 150, 150)
      Main:SetTitle(" gMusic Player")
    else
      if status == "Playing" then
        Main:SetBGColor(0,150,0)
      else
        Main:SetBGColor(255,150,0)
      end
      Main:SetTitle( " " .. status .. ": " .. string.StripExtension(string.GetFileFromFilename(songFilePath)))
    end
  end



  local function createMediaPlayer()
    Main = vgui.Create("DgMPlayerFrame")
    Main:SetSizeDynamic(120,300)
    Main:SetPos(16, 36)
    Main:SetTitle(" gMusic Player")
    Main:SetVisible(false)
    Main:SetDraggable(true)

    local mainX, mainY = Main:GetSize()

    colsheet = vgui.Create("DColumnSheet",Main)
    colsheet:SetPos(0,20)
    colsheet:SetSize(mainX, mainY - 80 )
    colsheet.Navigation:Dock( RIGHT )
    colsheet.Navigation:DockMargin( 0, 0, 0, 0 )
    colsheet.Navigation:SetVisible(false)


    sheetSongList = vgui.Create("DPanel", colsheet)
    sheetSongList:Dock(FILL)
    sheetSongList:DockMargin( 0, 0, 0, 0 )
    colsheet:AddSheet("Song List",sheetSongList, "icon16/control_play_blue.png")

    SongList = vgui.Create( "DListView", sheetSongList )
    SongList:Dock(FILL)
    SongList:SetMultiSelect( false )
    SongList:AddColumn( "Song" )

    buttonStop = vgui.Create("DButton", Main)
    buttonStop:SetFont("default")
    buttonStop:SetText("Stop")
    buttonStop:SetTextColor(Color(255,255,255))
    buttonStop:SetSize(mainX / 3,30)
    buttonStop:SetPos(0.1,  colsheet:GetTall() + 20)


    local buttonPause = vgui.Create("DButton", Main)
    buttonPause:SetFont("default")
    buttonPause:SetText("Pause")
    buttonPause:SetTextColor(Color(255,255,255))
    buttonPause:SetSize(buttonStop:GetWide(),buttonStop:GetTall())
    buttonPause:SetPos(buttonStop:GetWide(), colsheet:GetTall() + 20)



    local buttonPlay = vgui.Create("DButton", Main)
    buttonPlay:SetFont("default")
    buttonPlay:SetText("Play")
    buttonPlay:SetTextColor(Color(255,255,255))
    buttonPlay:SetSize(mainX - (buttonStop:GetWide() + buttonPause:GetWide()), buttonStop:GetTall())
    buttonPlay:SetPos(buttonStop:GetWide() + buttonPause:GetWide(), colsheet:GetTall() + 20)


    local sliderSeek = vgui.Create("DSeekBar",Main)
    MP_Seek = sliderSeek
    sliderSeek:SetSize(mainX - 150 ,30)
    sliderSeek:SetPos(0 , mainY - sliderSeek:GetTall())
    sliderSeek.Slider.Knob:SetHeight(sliderSeek:GetTall())
    sliderSeek.Slider.Knob:SetWide(5)
    sliderSeek:SetTextFont("default")
    sliderSeek:SetTextColor(255,255,255)
    sliderSeek:ShowSeekTime()
    sliderSeek:ShowSeekLength()

    local sliderVolume = vgui.Create("DNumSliderNoLabel", Main)
    MP_Volume = sliderVolume
    sliderVolume:SetSize(mainX - sliderSeek:GetWide(), 30)
    sliderVolume:SetPos(sliderSeek:GetWide() , mainY - sliderVolume:GetTall())
    sliderVolume:SetConVar("gmpl_vol")
    sliderVolume:SetValue(cvarMediaVolume:GetFloat())


    buttonStop.DoClick = function()
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE and PlayingSong:IsValid() then
        PlayingSong:Stop()
        sliderSeek:ResetValue()
        updateTitleSong(false,false)
      end
    end

    buttonPause.DoClick = function()
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE and PlayingSong:IsValid() and PlayingSong:GetState() == GMOD_CHANNEL_PLAYING then
        PlayingSong:Pause()
        updateTitleSong("Paused",PlayingSong:GetFileName())
      elseif TypeID(PlayingSong) == TYPE_SOUNDHANDLE and PlayingSong:IsValid() and PlayingSong:GetState() == GMOD_CHANNEL_PAUSED then
        PlayingSong:Play()
        updateTitleSong("Playing",PlayingSong:GetFileName())
      end
    end

    buttonPlay.DoClick = function( songFile )
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE and PlayingSong:IsValid()  and PlayingSong:GetState() == GMOD_CHANNEL_PAUSED
      and PlayingSong:GetFileName() == songTableFull[SongList:GetSelectedLine()] then

        PlayingSong:Play() -- resume if paused
        updateTitleSong("Playing",PlayingSong:GetFileName())

      elseif TypeID(SongList:GetSelectedLine()) ~= TYPE_NIL and TypeID(SongList:GetSelectedLine()) == TYPE_NUMBER then

        songFile = songTableFull[SongList:GetSelectedLine()]
        PlaySong(songFile)
        Main:SetTitle("Playing: " .. string.StripExtension(string.GetFileFromFilename(songFile)))
        updateTitleSong("Playing",songFile)
      else
        chat.AddText( Color(255,0,0),"[gMusic Player] Please select a song")
      end
    end




    sliderVolume.OnValueChanged = function(Panel, Value)
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE and PlayingSong:IsValid() then
        PlayingSong:SetVolume(sliderVolume:GetValue() / 100)
      end
    end
    SongList.DoDoubleClick = function()
      buttonPlay.DoClick(songTableFull[SongList:GetSelectedLine()])
    end

    getSongList()

    sliderSeek.SeekClick.OnValueChanged = function()
      if TypeID(PlayingSong) == TYPE_SOUNDHANDLE and PlayingSong:IsValid() then
        PlayingSong:SetTime(sliderSeek:GetValue())
      end
    end

    Main.Paint = function()
      surface.SetDrawColor( 20, 150, 240, 255 )
      surface.DrawRect( 0, 20, mainX, mainY )
    end

    buttonStop.Paint = function() end
    buttonPause.Paint = function() end
    buttonPlay.Paint = function() end
    sliderVolume.Paint = function() end
    sliderSeek.Paint = function() end

    colsheet.Navigation.Paint = function()
      surface.SetDrawColor( 150, 150, 150, 255 )
      surface.DrawRect( 0, 0 , colsheet:GetWide() ,colsheet:GetTall())
    end
    colsheet.Paint = function()
      surface.SetDrawColor( 20, 150, 240, 255 )
      surface.DrawRect( 0, 0 , colsheet:GetWide() ,colsheet:GetTall())
    end
    sheetSongList.Paint = function()
      surface.SetDrawColor( 150, 0, 0, 100 )
      surface.DrawRect(0, 0, sheetSongList:GetWide() , sheetSongList:GetTall())
    end


    buttonStop.PaintOver = function()
      if buttonStop:IsHovered() then
        surface.SetDrawColor( 255, 255, 255, 50 )
        surface.DrawRect( 0, 0 , buttonStop:GetWide() ,buttonStop:GetTall())
      end
    end
    buttonPause.PaintOver = function()
      if buttonPause:IsHovered() then
        surface.SetDrawColor( 255, 255, 255, 50 )
        surface.DrawRect( 0, 0 , buttonPause:GetWide() ,buttonPause:GetTall())
      end
    end
    buttonPlay.PaintOver =  function()
      if buttonPlay:IsHovered() then
        surface.SetDrawColor( 255, 255, 255, 50 )
        surface.DrawRect( 0, 0 , buttonPlay:GetWide() ,buttonPlay:GetTall())
      end
    end


    sliderSeek.Slider.Knob.Paint = function()
      surface.SetDrawColor(255,255,255,255)
      surface.DrawRect(0,0,sliderSeek.Slider.Knob:GetWide(),sliderSeek:GetTall())
    end
  end

  function Media:getMenu()
    if (!Main) then
      createMediaPlayer()
    end
    if (Main:IsVisible()) then
      Main:SetVisible(false)
      gui.EnableScreenClicker(false)
    else
      Main:SetVisible(true)
      gui.EnableScreenClicker(true)
    end
  end

  setmetatable(Media, {  __call = Media.new  })

  hook.Add("Think","RealTimeSeek", function()
        if TypeID(PlayingSong) == TYPE_SOUNDHANDLE and PlayingSong:IsValid() and Main:IsVisible()
        and (PlayingSong:GetState() == GMOD_CHANNEL_PLAYING or PlayingSong:GetState() == GMOD_CHANNEL_PAUSED) then

            MP_Seek:SetValue(PlayingSong:GetTime())
            if TypeID(MP_Seek:GetMax()) ~= TYPE_NIL and MP_Seek:GetMax() == 0 then
              MP_Seek:SetMax(PlayingSong:GetLength())
            end
        end
  end)
