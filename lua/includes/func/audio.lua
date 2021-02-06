local PlayingSong
local missingSong = false
local stateStop = false

local prevSelection = 0
local currSelection = 1

local colPlay	= Color(0, 150, 0)
local colAPlay	= Color(70, 190, 180)
local colPause	= Color(255, 150, 0)
local colAPause	= Color(210, 210, 0)
local colLoop	= Color(0, 230, 0)
local colALoop	= Color(45,205,115)
local col404	= Color(240, 0, 0)
local colBlack 	= Color(0, 0, 0)
local colWhite 	= Color(255, 255, 255)

local dermaBase = {}
local action = {}
local breakOnStop = false

local isAutoPlaying = false
local prevLooped = false
local songList = {}

local function init(baseMenu)
	dermaBase = baseMenu
	return action
end

local function updateSongList(list)
	songList = list
end

local function isMediaValid()
	return IsValid(PlayingSong)
end

local function stopIfRunning()
	if isMediaValid() then
		PlayingSong:Stop()
		PlayingSong = nil
		stateStop = true
		prevLooped = false
	end
end

local function disableTSS()
	if dermaBase.main:isTSS() then
		dermaBase.main:SetTSSEnabled(false)
		dermaBase.contextmedia:SetTSS(false)
	end

	if IsValid(dermaBase.songlist:GetLines()[prevSelection]) then
		dermaBase.songlist:HighlightLine(currSelection, false, false)
	end
end

local function updateAudioObject(CurrentSong)
	if CurrentSong:IsValid() then
		PlayingSong = CurrentSong
		PlayingSong:SetVolume(dermaBase.slidervol:GetValue() / 100)
		dermaBase.sliderseek:SetMax(CurrentSong:GetLength())
		dermaBase.contextmedia:SetSeekLength(CurrentSong:GetLength())
		missingSong = false
	end
end

------------------------------------------------------------------------------------------------

local function songLooped() return PlayingSong:IsLooping() end
local function songAutoPlay() return isAutoPlaying end
local function songMissing() return missingSong end
local function songState() return PlayingSong:GetState() end
local function songTime() return PlayingSong:GetTime() end
local function volumeState() return PlayingSong:GetVolume() end
local function songVol(time) PlayingSong:SetVolume(time) end
local function forcedLoop(bool) PlayingSong:EnableLooping(bool) end
local function forcedAutoPlay(bool) isAutoPlaying = bool end
local function forcedListSelection(selection)
	if selection < #songList then
		currSelection = selection
	else
		currSelection = 1
	end
	dermaBase.songlist:SetSelectedLine(selection)
end
local function songIndex(offset, apply)
	local tmp = currSelection + offset
	if tmp < #songList then
		if apply then
			currSelection = tmp
			dermaBase.songlist:SetSelectedLine(tmp)
		end
		return tmp
	else
		if apply then
			currSelection = 1
			dermaBase.songlist:SetSelectedLine(1)
		end
		return 1
	end
end

local function waitBuffer()
	PlayingSong:Pause()
	if PlayingSong ~= GMOD_CHANNEL_STALLED then
		PlayingSong:Play()
	end
end

local function updateListSelection(color, textcolor)
	currSelection = dermaBase.songlist:GetSelectedLine()
	-- if it cant find the song number then better not bother coloring
	if IsValid(dermaBase.songlist:GetLines()[currSelection]) then
		dermaBase.songlist:HighlightLine(currSelection, color, textcolor)
		if textcolor then
			dermaBase.main:SetTextColor(textcolor)
		end
	end

	if IsValid(dermaBase.songlist:GetLines()[prevSelection]) and prevSelection ~= currSelection then
		dermaBase.songlist:HighlightLine(prevSelection, false, false)
		dermaBase.songlist:ResetColor(prevSelection)
	end
	prevSelection = currSelection
end

local function updateTitleSong(status,songFilePath)
	if status == 1 then
		strStatus = " Playing: "
		if isAutoPlaying then
			dermaBase.main:SetBGColor(colAPlay)
			dermaBase.contextmedia:SetTextColor(colAPlay)
			updateListSelection(colAPlay, colBlack)
		else
			dermaBase.main:SetBGColor(colPlay)
			dermaBase.contextmedia:SetTextColor(colPlay)
			updateListSelection(colPlay, colWhite)
		end
	elseif status == 2 then
		strStatus = " Paused: "
		if isAutoPlaying then
			dermaBase.main:SetBGColor(colAPause)
			dermaBase.contextmedia:SetTextColor(colAPause)
			updateListSelection(colAPause, colBlack)
		else
			dermaBase.main:SetBGColor(colPause)
			dermaBase.contextmedia:SetTextColor(colPause)
			updateListSelection(colPause, colWhite)
		end
	elseif status == 3 then
		strStatus = " Looping: "
		if isAutoPlaying then
			dermaBase.main:SetBGColor(colALoop)
			dermaBase.contextmedia:SetTextColor(colALoop)
			updateListSelection(colALoop, colBlack)
		else
			dermaBase.main:SetBGColor(colLoop)
			dermaBase.contextmedia:SetTextColor(colLoop)
			updateListSelection(colLoop, colBlack)
		end
	else
		dermaBase.main:SetBGColor(150, 150, 150)
	end

	if songFilePath == false then
		dermaBase.main:SetTextColor(colWhite)
		dermaBase.main:SetText(" gMusic Player")
		dermaBase.contextmedia:SetTextColor(colBlack)
		dermaBase.contextmedia:SetText(false)
		disableTSS()
	else
		if status == false then
			strStatus = " Not On Disk: "
			dermaBase.main:SetBGColor(col404)
			dermaBase.contextmedia:SetTextColor(col404)
			dermaBase.contextmedia:SetMissing(true)
			missingSong = true
		end
		dermaBase.main:SetText(strStatus .. string.StripExtension(string.GetFileFromFilename(songFilePath)))
		dermaBase.contextmedia:SetText(string.StripExtension(string.GetFileFromFilename(songFilePath)))

		return string.StripExtension(string.GetFileFromFilename(songFilePath))
	end
end

local function ui404()
	updateTitleSong(false,PlayingSong:GetFileName())
end
local function uiPlay()
	updateTitleSong(1, PlayingSong:GetFileName())
end
local function uiLoop()
	updateTitleSong(3, PlayingSong:GetFileName())
end
local function uiAPlay()
	if PlayingSong:IsLooping() and PlayingSong:GetState() ~= GMOD_CHANNEL_PAUSED then
		updateTitleSong(3, PlayingSong:GetFileName())
		prevLooped = true;
		if isAutoPlaying then
			PlayingSong:EnableLooping(false)
		end
	elseif PlayingSong:GetState() == GMOD_CHANNEL_PLAYING then
		updateTitleSong(1, PlayingSong:GetFileName())
	elseif PlayingSong:GetState() == GMOD_CHANNEL_PAUSED then
		updateTitleSong(2, PlayingSong:GetFileName())
	end
end


local function playSong(song)
	prevLooped = false
	if isstring(song) then
		sound.PlayFile(song, "noblock", function(CurrentSong, ErrorID, ErrorName)
			stopIfRunning()
			if IsValid(CurrentSong) then
				CurrentSong:EnableLooping(false)
				CurrentSong:SetTime(0)
				updateAudioObject(CurrentSong)
				updateTitleSong(1,song)
				stateStop = false
				dermaBase.sliderseek:AllowSeek(true)
			else
				updateTitleSong(false,song)
				dermaBase.sliderseek:ResetValue()
			end
		end)
	end
end

local function resumeSong(song)
	if PlayingSong:GetFileName() == song and !stateStop then
		PlayingSong:Play()
		if PlayingSong:IsLooping() then
			updateTitleSong(3, song)
		else
			updateTitleSong(1, song)
		end
	else
		playSong(song)
	end
end

local function actionAutoPlay(bool)
	if isMediaValid() and !stateStop then
		if prevLooped then
			PlayingSong:EnableLooping(true)
			prevLooped = false;
		end

		if isbool(bool) then
			isAutoPlaying = bool
		else
			isAutoPlaying = !isAutoPlaying
		end

		uiAPlay()
	end
end

local function actionPauseL()
	if isMediaValid() then
		if PlayingSong:GetState() == GMOD_CHANNEL_PLAYING then
			PlayingSong:Pause()
			updateTitleSong(2, PlayingSong:GetFileName())
		elseif PlayingSong:GetState() == GMOD_CHANNEL_PAUSED and !stateStop then
			PlayingSong:Play()

			if PlayingSong:IsLooping() == true then
				updateTitleSong(3, PlayingSong:GetFileName())
			else
				updateTitleSong(1, PlayingSong:GetFileName())
			end
		end
	end
end

local function actionPauseR()
	if isMediaValid() and PlayingSong:GetState() == GMOD_CHANNEL_PLAYING then
		if PlayingSong:IsLooping() then
			PlayingSong:EnableLooping(false)
			prevLooped = false
			updateTitleSong(1, PlayingSong:GetFileName())
		else
			PlayingSong:EnableLooping(true)
			updateTitleSong(3, PlayingSong:GetFileName())
		end
	end
end

local function actionStop()
	if isMediaValid() then
		PlayingSong:Pause()
		PlayingSong:EnableLooping(false)
		dermaBase.sliderseek:ResetValue()
		updateTitleSong(false,false)
		stateStop = true
		isAutoPlaying = false
	end
end

local function actionStopAutoPlay(song)
	if #songList ~= 0 then
		prevSelection = currSelection
		if currSelection < #songList then
			currSelection = currSelection + 1
		else
			currSelection = 1
		end

		if isstring(song) then
			playSong(song)
		else
			playSong(songList[currSelection])
		end
		dermaBase.songlist:SetSelectedLine(currSelection)
		dermaBase.songlist:HighlightLine(currSelection, colAPlay, colBlack)
		if prevSelection ~= currSelection then
			dermaBase.songlist:HighlightLine(prevSelection, false, false)
			dermaBase.songlist:ResetColor(prevSelection)
		end
	else
		actionStop()
	end
end

local function resetUI()
	if songState() == GMOD_CHANNEL_STOPPED then
		actionStop()
	end
end

local function actionSeek(time)
	if IsValid(PlayingSong) and PlayingSong:GetState() ~= GMOD_CHANNEL_STALLED then
		PlayingSong:SetTime(time)
	end
end

action.play			=	playSong
action.resume		=	resumeSong
action.autoplay		=	actionAutoPlay
action.stop			=	actionStop
action.pause		=	actionPauseL
action.loop			=	actionPauseR
action.setloop		=	forcedLoop
action.setautoplay	=	forcedAutoPlay
action.setselection	=	forcedListSelection
action.seek			=	actionSeek
action.volume		=	songVol

action.stopsmart	=	actionStopAutoPlay

action.resetUI		= 	resetUI
action.kill			= 	stopIfRunning
action.update		=	updateAudioObject
action.updateList	=	updateListSelection
action.getTime		=	songTime
action.getVolume	=	volumeState
action.buffer		=	waitBuffer

action.updateSongs	=	updateSongList
action.songIndex	=	songIndex

action.isMissing	=	songMissing
action.isLooped		=	songLooped
action.isAutoPlay	=	songAutoPlay

action.hasValidity 	=	isMediaValid
action.hasState 	=	songState

action.uiPlay 		= 	uiPlay
action.uiAutoPlay 	= 	uiAPlay
action.uiLoop 		= 	uiLoop
action.uiMissing 	= 	ui404

action.colorLoop	= 	colLoop
action.colorPause	= 	colPause
action.colorPlay	= 	colPlay
action.colorMissing =	col404

action.breakOnStop	=	breakOnStop

return init
