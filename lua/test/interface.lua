
--
-- This currently does tests for dark mode only
-- Tests related to interface changes , client side
--

--[[
-- TODO:
-- 1, allow resizability for bottom-left in the time and top-left in the TSS,
-- it should work

-- PROBLEMS:
 THESE 2 happen when switching to server mode while playing on client mode
 (normally client should stop and server should resume live if existing)
 1. [gmusic-player] addons/gmusic-player/lua/includes/func/audio.lua:236: attempt to call method 'GetState' (a nil value)
1.state - addons/gmusic-player/lua/includes/func/audio.lua:236
2. HasSliderEnded - addons/gmusic-player/lua/includes/modules/meth_base.lua:242
3. MonitorSeek - addons/gmusic-player/lua/vgui/seekbarclicklayer.lua:72
4. unknown - addons/gmusic-player/lua/gmpl/cl_gmpl.lua:89

2. [gmusic-player] addons/gmusic-player/lua/includes/modules/musicplayerclass.lua:151: attempt to call field 'sv_stop' (a nil value)
1. func - addons/gmusic-player/lua/includes/modules/musicplayerclass.lua:151
2. unknown - lua/includes/extensions/net.lua:32

-- 3. Adding audio songs from sound/<folder> works
but from sound/<folder>/<subfolder> does not work.
However the <folder> appears in the music dirs. All audio from
subfolders should be added. And in case of
sound/<folder>/<subfolder1>/subfolder2> , then subfolder2 will be ignored and only subfolder1 content will be added, no matter how many of these subfolder1 are. DO a test for this, this way you can improve the way you add fake folder tree so you can make it more flexible

-- 4. Normally the audio which is directly in sound/ will be ignore and only audio in <folder> and <subfolder1> will be added. I should make a checkbox which allows sound/ audios just for the sake of having one (BUT IF i do this i should grab the audio from sound/ folder that belongs only to addons and not the local sound/ folder)
Can use this addon as example since ith as audio directly in sound/
correct_gmodworkshopurl/2532700664  TODO

5. Show missing song if no longer on disk.

6. When you pause a song and play on the list a different song, it resume the currently paused song. It should just directly play the new song that is clicked
- i think the problem is related to the play button resuming the song if it's paused
  - IMO i should make it simple and play button will only play a new song
    - i wonder why i overcomplicated the play button with pause detection
- FIXED: i think i fixed this

]]

--------------------------------------------------------------------------------
insulate("cl - Play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Play different after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_play_different(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Play after pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_pause_play(dermaBase, media.cl_PlayingSong)
end)
insulate("sv - Play different after pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_pause_play_different(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Play after autoplay", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_autoplay_play(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Play same after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_restart(dermaBase, media.cl_PlayingSong)
end)
--------------------------------------------------------------------------------

insulate("cl - Pause after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_pause(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Pause after pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_pause_unpause(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Pause after loop", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_loop_pause(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Pause after autoplay", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_autoplay_pause(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Unpause after loop & pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_loop_pause_unpause(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Unpause after autoplay & pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_autoplay_pause_unpause(dermaBase, media.cl_PlayingSong)
end)
--------------------------------------------------------------------------------

insulate("cl - Stop after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_stop(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Stop after pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_pause_stop(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Stop after unpause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_pause_unpause_stop(dermaBase, media.cl_PlayingSong)
end)
--------------------------------------------------------------------------------

insulate("cl - Loop after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_loop(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Loop after pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_pause_loop(dermaBase, media.cl_PlayingSong)
end)
--------------------------------------------------------------------------------

insulate("cl - Autoplay after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_autoplay(dermaBase, media.cl_PlayingSong)
end)
insulate("cl - Autoplay while seek end", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  sh_play_autoplay_seekend(dermaBase, media.cl_PlayingSong)
end)
--------------------------------------------------------------------------------
