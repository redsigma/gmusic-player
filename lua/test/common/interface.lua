--
-- Contains tests used for both client and server side
-- Tests related to interface changes
--
local insulate = 0
local describe = 0
local it = 0
local assert = 0

_G.init_unit_test_func = function(_insulate, _describe, _it, _assert)
  if insulate ~= 0 then return insulate, describe, it, assert end
  insulate = _insulate
  describe = _describe
  it = _it
  assert = _assert
end

-------------------------------------------------------------------------------
function sh_play(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    channel.song_index = 0

    it("change theme from light to dark", function()
      dermaBase.painter:theme_dark(false)
      dermaBase.painter:update_colors()
      assert.ui_theme(-1, dermaBase.painter)
      dermaBase.painter:theme_dark(true)
      dermaBase.painter:update_colors()
      assert.ui_theme(0, dermaBase.painter)
    end)

    it("is playing", function()
      dermaBase.buttonplay:DoClick(nil, song_line)
      assert.is_false(channel.isPaused)
      assert.is_true(channel.isPlaying)
      assert.is_false(channel.isStopped)
      assert.is_false(channel.isLooped)
      assert.is_false(channel.isAutoPlaying)
    end)

    it("update media data", function()
      assert.same(channel.title_song, "Example2")
      assert.same(channel.song, "sound/folder1/Example2.mp3")
      assert.same(channel.title_status, " Playing: ")
    end)

    it("update derma ui", function()
      assert.ui_top_bar_color(1, "Example2")
      assert.same(dermaBase.contextmedia:IsMissing(), false)
    end)

    it("song list highlight line", function()
      assert.line_highlight(1, song_line, 0, channel)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_play_different(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("play another", function()
      it("is playing", function()
        song_line = 1
        dermaBase.buttonplay:DoClick(nil, song_line)
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example1")
        assert.same(channel.song, "sound/folder1/Example1.mp3")
        assert.same(channel.title_status, " Playing: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(1, "Example1")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(1, song_line, 2, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_pause_play(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonpause:DoClick()

    describe("resume", function()
      it("is playing", function()
        dermaBase.buttonplay:DoClick()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example2")
        assert.same(channel.song, "sound/folder1/Example2.mp3")
        assert.same(channel.title_status, " Playing: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(1, "Example2")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(1, song_line, 0, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_autoplay_play(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    local prev_line = 0
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("autoplay", function()
      dermaBase.buttonplay:DoRightClick()

      describe("play", function()
        it("is autoplaying", function()
          dermaBase.buttonplay:DoClick(nil)
          assert.is_false(channel.isPaused)
          assert.is_true(channel.isPlaying)
          assert.is_false(channel.isStopped)
          assert.is_false(channel.isLooped)
          assert.is_true(channel.isAutoPlaying)
        end)

        it("update media data", function()
          assert.same(channel.title_song, "Example2")
          assert.same(channel.song, "sound/folder1/Example2.mp3")
          assert.same(channel.title_status, " Auto Playing: ")
        end)

        it("update derma ui", function()
          assert.ui_top_bar_color(2, "Example2")
          assert.same(dermaBase.contextmedia:IsMissing(), false)
        end)

        it("song list highlight line", function()
          assert.line_highlight(2, song_line, prev_line, channel)
        end)
      end)
    end)
  end)
end

function sh_play_autoplay_autoplay(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    local prev_line = 0
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("autoplay", function()
      dermaBase.buttonplay:DoRightClick()

      describe("play", function()
        it("is not autoplaying", function()
          dermaBase.buttonplay:DoRightClick()
          assert.is_false(channel.isPaused)
          assert.is_true(channel.isPlaying)
          assert.is_false(channel.isStopped)
          assert.is_false(channel.isLooped)
          assert.is_false(channel.isAutoPlaying)
        end)

        it("update media data", function()
          assert.same(channel.title_song, "Example2")
          assert.same(channel.song, "sound/folder1/Example2.mp3")
          assert.same(channel.title_status, " Playing: ")
        end)

        it("update derma ui", function()
          assert.ui_top_bar_color(1, "Example2")
          assert.same(dermaBase.contextmedia:IsMissing(), false)
        end)

        it("song list highlight line", function()
          assert.line_highlight(1, song_line, prev_line, channel)
        end)
      end)
    end)
  end)
end

function sh_play_live_seek_no_autoplay_no_autoplay(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    local prev_line = 0
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("autoplay", function()
      dermaBase.buttonplay:DoRightClick()

      describe("play", function()
        it("is not autoplaying", function()
          dermaBase.buttonplay:DoRightClick()
          assert.is_false(channel.isPaused)
          assert.is_true(channel.isPlaying)
          assert.is_false(channel.isStopped)
          assert.is_false(channel.isLooped)
          assert.is_false(channel.isAutoPlaying)
        end)

        it("update media data", function()
          assert.same(channel.title_song, "Example1")
          assert.same(channel.song, "sound/folder1/Example1.mp3")
          assert.same(channel.title_status, " Playing: ")
        end)

        it("update derma ui", function()
          assert.ui_top_bar_color(1, "Example1")
          assert.same(dermaBase.contextmedia:IsMissing(), false)
        end)

        it("song list highlight line", function()
          assert.line_highlight(1, 1, prev_line, channel)
        end)
      end)
    end)
  end)
end

function sh_play_live_seek_no_autoplay_play_liveseek(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    local prev_line = 0
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("autoplay", function()
      dermaBase.buttonplay:DoRightClick()

      describe("play", function()
        it("is autoplaying", function()
          dermaBase.buttonplay:DoClick(nil)
          assert.is_false(channel.isPaused)
          assert.is_true(channel.isPlaying)
          assert.is_false(channel.isStopped)
          assert.is_false(channel.isLooped)
          assert.is_false(channel.isAutoPlaying)
        end)

        it("update media data", function()
          assert.same(channel.title_song, "Example1")
          assert.same(channel.song, "sound/folder1/Example1.mp3")
          assert.same(channel.title_status, " Playing: ")
        end)

        it("update derma ui", function()
          assert.ui_top_bar_color(1, "Example1")
          assert.same(dermaBase.contextmedia:IsMissing(), false)
        end)

        it("song list highlight line", function()
          assert.line_highlight(1, 1, prev_line, channel)
        end)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_restart(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("play another", function()
      it("is playing", function()
        dermaBase.buttonplay:DoClick(nil)
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example2")
        assert.same(channel.song, "sound/folder1/Example2.mp3")
        assert.same(channel.title_status, " Playing: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(1, "Example2")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(1, song_line, 0, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_pause(dermaBase, channel, more_checks)
  local song_line = 2
  channel.song_index = 0

  describe("play", function()
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("pause", function()
      it("is paused", function()
        dermaBase.buttonpause:DoClick()
        assert.is_true(channel.isPaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
        assert.is_false(channel.isAutoPlaying)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example2")
        assert.same(channel.song, "sound/folder1/Example2.mp3")
        assert.same(channel.title_status, " Paused: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(3, "Example2")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(3, song_line, 0, channel)
      end)

      if more_checks ~= nil then
        more_checks()
      end
    end)
  end)
end

function sh_play_live_seek_pause(dermaBase, channel)
  -- should play line from server
  local song_line = 2
  channel.song_index = 0

  describe("live seek", function()
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("pause", function()
      it("is paused", function()
        dermaBase.buttonpause:DoClick()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isLivePaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
        assert.is_false(channel.isAutoPlaying)
      end)

      it("update media data from server", function()
        assert.same(channel.title_song, "Example1")
        assert.same(channel.song, "sound/folder1/Example1.mp3")
        assert.same(channel.title_status, " Muted: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(5, "Example1")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(5, 1, 0, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_pause_unpause(dermaBase, channel)
  describe("play & pause", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonpause:DoClick()

    describe("unpause", function()
      it("is playing", function()
        dermaBase.buttonpause:DoClick(nil, song_line)
        assert.is_false(channel.isPaused)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example2")
        assert.same(channel.song, "sound/folder1/Example2.mp3")
        assert.same(channel.title_status, " Playing: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(1, "Example2")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(1, song_line, 0, channel)
      end)
    end)
  end)
end

function sh_play_live_seek_pause_unpause(dermaBase, channel)
  describe("play & pause live", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonpause:DoClick()

    describe("unpause live", function()
      it("is live seeking", function()
        dermaBase.buttonpause:DoClick(nil, song_line)
        assert.is_false(channel.isPaused)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
      end)

      it("update media data from server", function()
        assert.same(channel.title_song, "Example1")
        assert.same(channel.song, "sound/folder1/Example1.mp3")
        assert.same(channel.title_status, " Playing: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(1, "Example1")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(1, 1, 0, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_loop_pause(dermaBase, channel)
  describe("play & loop", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonpause:DoRightClick()

    describe("pause", function()
      it("is paused & looped", function()
        dermaBase.buttonpause:DoClick()
        assert.is_true(channel.isPaused)
        assert.is_false(channel.isStopped)
        assert.is_true(channel.isLooped)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example2")
        assert.same(channel.song, "sound/folder1/Example2.mp3")
        assert.same(channel.title_status, " Paused: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(3, "Example2")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(3, song_line, 0, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_autoplay_pause(dermaBase, channel)
  describe("play & autoplay", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonplay:DoRightClick()

    describe("pause", function()
      it("is paused", function()
        dermaBase.buttonpause:DoClick()
        assert.is_true(channel.isPaused)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
        assert.is_true(channel.isAutoPlaying)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example2")
        assert.same(channel.song, "sound/folder1/Example2.mp3")
        assert.same(channel.title_status, " Paused: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(3, "Example2")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(3, song_line, 0, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_loop_pause_unpause(dermaBase, channel)
  describe("play & loop & pause", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonpause:DoRightClick()
    dermaBase.buttonpause:DoClick()

    describe("unpause", function()
      it("is looping", function()
        dermaBase.buttonpause:DoClick()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_true(channel.isLooped)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example2")
        assert.same(channel.song, "sound/folder1/Example2.mp3")
        assert.same(channel.title_status, " Looping: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(4, "Example2")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(4, song_line, 0, channel)
      end)
    end)
  end)
end

function sh_play_live_seek_loop_pause_unpause(dermaBase, channel)
  describe("live seek & loop & pause", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonpause:DoRightClick()
    dermaBase.buttonpause:DoClick()

    describe("unpause live seek", function()
      it("is looping", function()
        dermaBase.buttonpause:DoClick()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_true(channel.isLooped)
      end)

      it("update media data from server", function()
        assert.same(channel.title_song, "Example1")
        assert.same(channel.song, "sound/folder1/Example1.mp3")
        assert.same(channel.title_status, " Looping: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(4, "Example1")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(4, 1, 0, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_autoplay_pause_unpause(dermaBase, channel)
  describe("play & autoplay & pause", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonplay:DoRightClick()
    dermaBase.buttonpause:DoClick()

    describe("unpause", function()
      it("is playing & autoplayed", function()
        dermaBase.buttonpause:DoClick()
        assert.is_false(channel.isPaused)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
        assert.is_true(channel.isAutoPlaying)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example2")
        assert.same(channel.song, "sound/folder1/Example2.mp3")
        assert.same(channel.title_status, " Auto Playing: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(2, "Example2")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(2, song_line, 0, channel)
      end)
    end)
  end)
end

function sh_play_live_seek_no_autoplay_pause_live_unpause_live(dermaBase, channel)
  describe("play & autoplay & pause", function()
    local song_line = 2
    local prev_line = 0
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonplay:DoRightClick()
    dermaBase.buttonpause:DoClick()

    it("is live paused", function()
      assert.is_true(channel.isLivePaused)
      assert.is_false(channel.isPaused)
    end)

    describe("unpause", function()
      it("is playing & autoplayed", function()
        dermaBase.buttonpause:DoClick()
        assert.is_false(channel.isLivePaused)
        assert.is_false(channel.isPaused)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
        assert.is_false(channel.isAutoPlaying)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example1")
        assert.same(channel.song, "sound/folder1/Example1.mp3")
        assert.same(channel.title_status, " Playing: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(1, "Example1")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(1, 1, prev_line, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_stop(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("stop", function()
      it("is stopped", function()
        dermaBase.buttonstop:DoClick()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isStopped)
        assert.is_false(channel.isLooped)
      end)

      it("reset ui", function()
        assert.same(channel.title_song, "")
        assert.same(channel.song, "")
        assert.same(channel.title_status, "")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(-1, "gMusic Player")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list dont highlight line", function()
        assert.line_highlight(0, 0, song_line, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_pause_stop(dermaBase, channel)
  describe("play & pause", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonpause:DoClick()

    describe("stop", function()
      it("is stopped", function()
        dermaBase.buttonstop:DoClick()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isStopped)
        assert.is_false(channel.isLooped)
      end)

      it("reset ui", function()
        assert.same(channel.title_song, "")
        assert.same(channel.song, "")
        assert.same(channel.title_status, "")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(-1, "gMusic Player")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list dont highlight line", function()
        assert.line_highlight(0, 0, song_line, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_pause_unpause_stop(dermaBase, channel)
  describe("play & pause & unpause", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonpause:DoClick()
    dermaBase.buttonpause:DoClick()

    describe("stop", function()
      it("is stopped", function()
        dermaBase.buttonstop:DoClick()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isStopped)
        assert.is_false(channel.isLooped)
      end)

      it("reset ui", function()
        assert.same(channel.title_song, "")
        assert.same(channel.song, "")
        assert.same(channel.title_status, "")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(-1, "gMusic Player")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list dont highlight line", function()
        assert.line_highlight(0, 0, song_line, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_loop(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("loop", function()
      it("is looping", function()
        dermaBase.buttonpause:DoRightClick()
        assert.is_false(channel.isPaused)
        assert.is_false(channel.isStopped)
        assert.is_true(channel.isLooped)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example2")
        assert.same(channel.song, "sound/folder1/Example2.mp3")
        assert.same(channel.title_status, " Looping: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(4, "Example2")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(4, song_line, 0, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_pause_loop(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("pause", function()
      describe("loop", function()
        it("is paused and looping", function()
          dermaBase.buttonpause:DoClick()
          dermaBase.buttonpause:DoRightClick()
          assert.is_true(channel.isPaused)
          assert.is_true(channel.isPlaying)
          assert.is_false(channel.isStopped)
          assert.is_false(channel.isLooped)
        end)

        it("update media data", function()
          assert.same(channel.title_song, "Example2")
          assert.same(channel.song, "sound/folder1/Example2.mp3")
          assert.same(channel.title_status, " Paused: ")
        end)

        it("update derma ui", function()
          assert.ui_top_bar_color(3, "Example2")
          assert.same(dermaBase.contextmedia:IsMissing(), false)
        end)

        it("song list highlight line", function()
          assert.line_highlight(3, song_line, 0, channel)
        end)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_autoplay(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("autoplay", function()
      it("is autoplaying", function()
        dermaBase.buttonplay:DoRightClick()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
        assert.is_true(channel.isAutoPlaying)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example2")
        assert.same(channel.song, "sound/folder1/Example2.mp3")
        assert.same(channel.title_status, " Auto Playing: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(2, "Example2")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(2, song_line, 0, channel)
      end)
    end)
  end)
end

function sh_play_live_seek_no_autoplay(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)

    describe("autoplay", function()
      it("is autoplaying", function()
        dermaBase.buttonplay:DoRightClick()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
        assert.is_false(channel.isAutoPlaying)
      end)

      it("update media data", function()
        assert.same(channel.title_song, "Example1")
        assert.same(channel.song, "sound/folder1/Example1.mp3")
        assert.same(channel.title_status, " Playing: ")
      end)

      it("update derma ui", function()
        assert.ui_top_bar_color(1, "Example1")
        assert.same(dermaBase.contextmedia:IsMissing(), false)
      end)

      it("song list highlight line", function()
        assert.line_highlight(1, 1, 0, channel)
      end)
    end)
  end)
end

-------------------------------------------------------------------------------
function sh_play_autoplay_seekend(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonplay:DoRightClick()

    describe("seek to end", function()
      _set_slider_seek_max(400.25)
      _set_slider_size(650)
      dermaBase.sliderseek.seek_val.seek_seconds_from_slider = 200
      _slider_seek(650)

      it("play next audio", function()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
        assert.is_true(channel.isAutoPlaying)
        assert.are.equal(channel.song_index, song_line + 1)
        assert.are.equal(channel.song_prev_index, song_line)
      end)

      it("slider is visible", function()
        local curr_slider = dermaBase.sliderseek.seek_val.current_slider_pos
        local seconds_slider = dermaBase.sliderseek.seek_val.seek_seconds_from_slider
        local is_slider_handle_visible = dermaBase.sliderseek.seek_val.Slider.Knob:IsVisible()
        assert.are.equal(curr_slider, 0.0)
        assert.are.equal(seconds_slider, 0)
        assert.are.equal(is_slider_handle_visible, true)
      end)
    end)
  end)
end

function sh_play_live_seek_no_autoplay_no_seekend(dermaBase, channel)
  describe("play", function()
    local song_line = 2
    local prev_line = 0
    channel.song_index = 0
    dermaBase.buttonplay:DoClick(nil, song_line)
    dermaBase.buttonplay:DoRightClick()

    describe("seek to end", function()
      dermaBase.sliderseek.seek_val.Slider:SetWide(650)
      dermaBase.sliderseek.seek_val.seek_seconds_from_slider = 200
      dermaBase.sliderseek.seek_val:SetDragging(true)
      dermaBase.sliderseek.seek_val:OnCursorMoved(650)

      it("play next audio", function()
        assert.is_false(channel.isPaused)
        assert.is_true(channel.isPlaying)
        assert.is_false(channel.isStopped)
        assert.is_false(channel.isLooped)
        assert.is_false(channel.isAutoPlaying)
        assert.are.equal(channel.song_index, 1)
        assert.are.equal(channel.song_prev_index, prev_line)
      end)

      it("slider is visible", function()
        local curr_slider = dermaBase.sliderseek.seek_val.current_slider_pos
        local seconds_slider = dermaBase.sliderseek.seek_val.seek_seconds_from_slider
        local is_slider_handle_visible = dermaBase.sliderseek.seek_val.Slider.Knob:IsVisible()
        assert.are.equal(curr_slider, 0.0)
        assert.are.equal(seconds_slider, 200)
        assert.are.equal(is_slider_handle_visible, true)
      end)
    end)
  end)
end
-------------------------------------------------------------------------------