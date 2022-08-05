--
-- This currently does tests for dark mode only
-- Tests related to interface changes , server side
--
-- PROBLEMS:
-- TODO
local files_local = {}

files_local.folder1 = {"Example1.mp3", "Example2.mp3"}

files_local.folder2 = {"Example3.mp3", "Example4.mp3", "example5.mp3"}

local function set_net_call_admin(net_call, is_admin)
  net_calls_player[net_call] = is_admin
end

-- reset audio channels to default value
local function _reset_client(channel)
  channel.isPlaying = false
  channel.isPaused = false
  channel.isLooped = false
  channel.isStopped = true
  channel.isMissing = false
  channel.isAutoPlaying = false
  channel.isLivePaused = false
  channel.error = false
  channel.seek = 0
  channel.volume = -1
  channel.prev_volume = 0
  channel.title_status = ""
  channel.title_song = ""
  channel.song = ""
  channel.song_index = 0
  channel.song_prev_index = 0
  channel.think = false
  channel.think_autoplay = false
  channel.AutoplayNext = false
end

insulate("sv - Switch to Server Mode", function()
  local dermaBase, media = create_with_dark_mode()
  init_sv_shared_settings()

  it("setup assert rules", function()
    assert.set_derma(dermaBase)
  end)

  describe("admin access off", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, false)

    describe("is admin", function()
      _reset_server()
      _set_player_admin(true)

      it("enable normal ui", function()
        dermaBase.main.is_server_mode = false
        dermaBase.main:SwitchModeServer()
        assert.are.equal(dermaBase.cbadminaccess:GetChecked(), false)
        assert.same(dermaBase.main.buttonMode:GetText(), "SERVER")
        assert.same(dermaBase.buttonplay.text, "Play / AutoPlay")
        assert.same(dermaBase.buttonpause.text, "Pause / Loop")
        assert.are.equal(dermaBase.buttonstop:IsVisible(), true)
        assert.are.equal(dermaBase.buttonswap:IsVisible(), false)
      end)
    end)

    describe("not admin", function()
      _reset_server()
      _set_player_admin(false)

      it("enable normal ui", function()
        dermaBase.main.is_server_mode = false
        dermaBase.main:SwitchModeServer()
        assert.are.equal(dermaBase.cbadminaccess:GetChecked(), false)
        assert.same(dermaBase.main.buttonMode:GetText(), "SERVER")
        assert.same(dermaBase.buttonplay.text, "Play / AutoPlay")
        assert.same(dermaBase.buttonpause.text, "Pause / Loop")
        assert.are.equal(dermaBase.buttonstop:IsVisible(), true)
        assert.are.equal(dermaBase.buttonswap:IsVisible(), false)
      end)
    end)
  end)

  describe("admin access on", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)

    describe("is admin", function()
      _reset_server()
      _set_player_admin(true)

      it("enable normal ui", function()
        dermaBase.main.is_server_mode = false
        dermaBase.main:SwitchModeServer()
        assert.are.equal(dermaBase.cbadminaccess:GetChecked(), true)
        assert.same(dermaBase.main.buttonMode:GetText(), "SERVER")
        assert.same(dermaBase.buttonplay.text, "Play / AutoPlay")
        assert.same(dermaBase.buttonpause.text, "Pause / Loop")
        assert.are.equal(dermaBase.buttonstop:IsVisible(), true)
        assert.are.equal(dermaBase.buttonswap:IsVisible(), false)
      end)
    end)

    describe("not admin", function()
      _reset_server()
      _set_player_admin(false)

      it("enable listen ui", function()
        dermaBase.main.is_server_mode = false
        dermaBase.main:SwitchModeServer()
        assert.are.equal(dermaBase.cbadminaccess:GetChecked(), true)
        assert.same(dermaBase.main.buttonMode:GetText(), "SERVER")
        assert.same(dermaBase.buttonplay.text, "Resume Live")
        assert.same(dermaBase.buttonpause.text, "Pause")
        assert.are.equal(dermaBase.buttonstop:IsVisible(), false)
        assert.are.equal(dermaBase.buttonswap:IsVisible(), true)
      end)
    end)
  end)
end)

-- -- TODO check if duplicate
-- insulate("sv - Play On Click", function()
--   _set_player_admin(true)
--   _set_audio_files("GAME", {"folder1", "folder2"}, files_local)
--   _set_audio_files("WORKSHOP", {})
--   local dermaBase, media = create_with_dark_mode()
--   init_sv_shared_settings()
--   it("setup assert rules", function()
--     assert.set_derma(dermaBase)
--   end)
--   describe("play", function()
--     _set_net_players_admin(false)
--     _set_checkbox_as_admin(dermaBase.cbadminaccess, true)
--     dermaBase.main:SwitchMode()
--     local song_line = 2
--     it("is playing", function()
--       dermaBase.buttonplay:DoClick(nil, song_line)
--       assert.is_false(media.sv_PlayingSong.isPaused)
--       assert.is_true(media.sv_PlayingSong.isPlaying)
--       assert.is_false(media.sv_PlayingSong.isStopped)
--       assert.is_false(media.sv_PlayingSong.isLooped)
--       assert.is_false(media.sv_PlayingSong.isAutoPlaying)
--     end)
--     it("update media data", function()
--       assert.same(media.sv_PlayingSong.title_song, "Example2")
--       assert.same(media.sv_PlayingSong.song, "sound/folder1/Example2.mp3")
--       assert.same(media.sv_PlayingSong.title_status, " Playing: ")
--     end)
--     it("update derma ui", function()
--       assert.ui_top_bar_color(1, "Example2")
--       assert.same(dermaBase.main.buttonMode:GetText(), "SERVER")
--     end)
--     it("song list highlight line", function()
--       assert.line_highlight(1, song_line, 0, media.sv_PlayingSong)
--     end)
--   end)
-- end)
-- ------------------------------------------------------------------------------
insulate("sv - Play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_play(dermaBase, media.sv_PlayingSong)

  it("server mode ui button", function()
    assert.same(dermaBase.main.buttonMode:GetText(), "SERVER")
  end)
end)

insulate("sv - Play different after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_play_play_different(dermaBase, media.sv_PlayingSong)
end)

insulate("sv - Play after pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_pause_play(dermaBase, media.sv_PlayingSong)
end)

insulate("sv - Play after autoplay", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  dermaBase.main:SwitchModeServer()

  describe("admin access off", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, false)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_autoplay_play(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(false)
      sh_play_autoplay_play(dermaBase, media.sv_PlayingSong)
    end)
  end)

  describe("admin access on", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_autoplay_play(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      dermaBase.buttonplay:DoClick(nil, 0)
      _set_player_admin(false)
      _net_promote_sender_to_admin("sv_play_live_seek_for_user")
      sh_play_live_seek_no_autoplay_play_liveseek(dermaBase, media.sv_PlayingSong)
    end)
  end)
end)

insulate("sv - Play same after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_play_restart(dermaBase, media.sv_PlayingSong)
end)

------------------------------------------------------------------------------
insulate("sv - Pause after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  dermaBase.main:SwitchModeServer()

  describe("admin access off", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, false)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_pause(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(false)
      sh_play_pause(dermaBase, media.sv_PlayingSong)
    end)
  end)

  describe("admin access on", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_pause(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      dermaBase.buttonplay:DoClick(nil, 0)
      _set_player_admin(false)
      -- set host as admin
      _net_promote_sender_to_admin("sv_play_live_seek_for_user")
      sh_play_live_seek_pause(dermaBase, media.sv_PlayingSong)
    end)
  end)
end)

insulate("sv - Pause after pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  dermaBase.main:SwitchModeServer()

  describe("admin access off", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, false)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(false)
      sh_play_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)
  end)

  describe("admin access on", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      dermaBase.buttonplay:DoClick(nil, 0)
      _set_player_admin(false)
      _net_promote_sender_to_admin("sv_play_live_seek_for_user")
      sh_play_live_seek_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)
  end)
end)

insulate("sv - Pause after loop", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_play_loop_pause(dermaBase, media.sv_PlayingSong)
end)

insulate("sv - Pause after autoplay", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_play_autoplay_pause(dermaBase, media.sv_PlayingSong)
end)

--
-- CONTINUE HERE the below one
--
insulate("sv - Unpause after loop & pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  dermaBase.main:SwitchModeServer()

  describe("admin access off", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, false)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_loop_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(false)
      _net_promote_sender_to_admin("sv_play_live_seek_from_host")
      sh_play_loop_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)
  end)

  describe("admin access on", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_loop_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      dermaBase.buttonplay:DoClick(nil, 0)
      dermaBase.buttonpause:DoRightClick()
      _set_player_admin(false)
      _net_promote_sender_to_admin("sv_play_live_seek_for_user")
      sh_play_live_seek_loop_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)
  end)
end)

insulate("sv - Unpause after autoplay & pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  dermaBase.main:SwitchModeServer()

  describe("admin access off", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, false)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_autoplay_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(false)
      _net_promote_sender_to_admin("cl_play_live_seek_from_host")
      sh_play_autoplay_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)
  end)

  describe("admin access on", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_autoplay_pause_unpause(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      dermaBase.buttonplay:DoClick(nil, 0)
      _set_player_admin(false)
      sh_play_live_seek_no_autoplay_pause_live_unpause_live(dermaBase, media.sv_PlayingSong)
    end)
  end)
end)

------------------------------------------------------------------------------
insulate("sv - Stop after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_play_stop(dermaBase, media.sv_PlayingSong)
end)

insulate("sv - Stop after pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_play_pause_stop(dermaBase, media.sv_PlayingSong)
end)

insulate("sv - Stop after unpause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_play_pause_unpause_stop(dermaBase, media.sv_PlayingSong)
end)

------------------------------------------------------------------------------
insulate("sv - Loop after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_play_loop(dermaBase, media.sv_PlayingSong)
end)

insulate("sv - Loop after pause", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  _reset_server()
  dermaBase.main:SwitchModeServer()
  sh_play_pause_loop(dermaBase, media.sv_PlayingSong)
end)

------------------------------------------------------------------------------
insulate("sv - Autoplay after play", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  dermaBase.main:SwitchModeServer()

  describe("admin access off", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, false)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_autoplay(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(false)
      sh_play_autoplay(dermaBase, media.sv_PlayingSong)
    end)
  end)

  describe("admin access on", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_autoplay(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      dermaBase.buttonplay:DoClick(nil, 0)
      _set_player_admin(false)
      _net_promote_sender_to_admin("sv_play_live_seek_for_user")
      sh_play_live_seek_no_autoplay(dermaBase, media.sv_PlayingSong)
    end)
  end)
end)

insulate("sv - Autoplay after autoplay", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  dermaBase.main:SwitchModeServer()

  describe("admin access off", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, false)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_autoplay_autoplay(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(false)
      sh_play_autoplay_autoplay(dermaBase, media.sv_PlayingSong)
    end)
  end)

  describe("admin access on", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_autoplay_autoplay(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      dermaBase.buttonplay:DoClick(nil, 0)
      _set_player_admin(false)
      _net_promote_sender_to_admin("sv_play_live_seek_for_user")
      sh_play_live_seek_no_autoplay_no_autoplay(dermaBase, media.sv_PlayingSong)
    end)
  end)
end)

insulate("sv - Autoplay while seek end", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  dermaBase.main:SwitchModeServer()

  describe("admin access off", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, false)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_autoplay_seekend(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(false)
      sh_play_autoplay_seekend(dermaBase, media.sv_PlayingSong)
    end)
  end)

  describe("admin access on", function()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)

    describe("is admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      sh_play_autoplay_seekend(dermaBase, media.sv_PlayingSong)
    end)

    describe("not admin", function()
      _reset_client(media.sv_PlayingSong)
      _reset_server()
      _set_player_admin(true)
      dermaBase.buttonplay:DoClick(nil, 0)
      _set_player_admin(false)
      _net_promote_sender_to_admin("sv_play_live_seek_for_user")
      sh_play_live_seek_no_autoplay_no_seekend(dermaBase, media.sv_PlayingSong)
    end)
  end)
end)
--------------------------------------------------------------------------------
-- TODO idea for better function readability
--  - might be worth trying this approach cuz i believe it will improve readability and also offer some nested features
-- insulate("sv - test test", function()
--   describe("test ", function()
--     local player_with_no_admin = __create_player(False)
--     local player_with_admin = __create_player(True)
--     player_with_admin:do_action(function()
--       sh_play_live_seek_no_autoplay_no_seekend(dermaBase, media.sv_PlayingSong)
--     end)
--   end)
-- end)]]