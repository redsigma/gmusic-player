local PlayingSong
local missingSong = false
local stateStop = false

local prevSelection = 0
local currSelection = 0

local colPlay	= Color(0,150,0)
local colPause	= Color(255,150,0)
local colLoop	= Color(0,230,0)
local colBlack 	= Color(0, 0, 0)
local colWhite 	= Color(255, 255, 255)

local dermaBase = {}
local action = {}

local function init(baseMenu)
	dermaBase = baseMenu
	return action
end

local function isMediaValid()
	return IsValid(PlayingSong)
end

local function stopIfRunning()
	if isMediaValid() then
		PlayingSong:Stop()
		PlayingSong = nil
		stateStop = true
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
local function songMissing() return missingSong end
local function songState() return PlayingSong:GetState() end
local function songTime() return PlayingSong:GetTime() end
local function volumeState() return PlayingSong:GetVolume() end
local function songVol(time) PlayingSong:SetVolume(time) end
local function forcedLoop(bool) PlayingSong:EnableLooping(bool) end
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
			dermaBase.main:SetTitleColor(textcolor)
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
		dermaBase.main:SetBGColor(colPlay)
		dermaBase.contextmedia:SetTextColor(colPlay)
		updateListSelection(colPlay, colWhite)
	elseif status == 2 then
		strStatus = " Paused: "
		dermaBase.main:SetBGColor(colPause)
		dermaBase.contextmedia:SetTextColor(colPause)
		updateListSelection(colPause, colWhite)
	elseif status == 3 then
		strStatus = " Looping: "
		dermaBase.main:SetBGColor(colLoop)
		dermaBase.contextmedia:SetTextColor(colLoop)
		updateListSelection(colLoop, colBlack)
	else
		dermaBase.main:SetBGColor(150, 150, 150)
	end

	if songFilePath == false then
		dermaBase.main:SetTitle(" gMusic Player")
		dermaBase.contextmedia:SetTextColor(dermaBase.songlist:GetLineColor())
		dermaBase.contextmedia:SetTitle(false)
		stateStop = true
		disableTSS()
	else
		if status == false then
			strStatus = " Not On Disk: "
			dermaBase.main:SetBGColor(240, 0, 0)
			dermaBase.contextmedia:SetTextColor(Color(240, 0, 0))
			dermaBase.contextmedia:SetMissing(true)
			missingSong = true
		end
		dermaBase.main:SetTitle(strStatus .. string.StripExtension(string.GetFileFromFilename(songFilePath)))
		dermaBase.contextmedia:SetTitle(string.StripExtension(string.GetFileFromFilename(songFilePath)))

		return string.StripExtension(string.GetFileFromFilename(songFilePath))
	end
end

local function playSong(song)
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
			updateTitleSong(1, PlayingSong:GetFileName())
		else
			PlayingSong:EnableLooping(true)
			updateTitleSong(3, PlayingSong:GetFileName())
		end
	end
end

local function actionStop()
	if isMediaValid() then
		PlayingSong:EnableLooping(false)
		PlayingSong:Pause()
		dermaBase.sliderseek:ResetValue()
		updateTitleSong(false,false)
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

local function ui404()
	updateTitleSong(false,PlayingSong:GetFileName())
end
local function uiPlay()
	updateTitleSong(1, PlayingSong:GetFileName())
end
local function uiLoop()
	updateTitleSong(3, PlayingSong:GetFileName())
end

action.play			=	playSong
action.resume		=	resumeSong
action.stop			=	actionStop
action.pause		=	actionPauseL
action.loop			=	actionPauseR
action.forceloop	=	forcedLoop
action.seek			=	actionSeek
action.volume		=	songVol

action.resetUI		= 	resetUI
action.kill			= 	stopIfRunning
action.update		=	updateAudioObject
action.updateList	=	updateListSelection
action.getTime		=	songTime
action.getVolume	=	volumeState
action.buffer		=	waitBuffer

action.isMissing	= songMissing
action.isLooped		= songLooped
action.hasValidity 	= isMediaValid
action.hasState 	= songState

action.uiPlay = uiPlay
action.uiLoop = uiLoop
action.uiMissing = ui404

return init