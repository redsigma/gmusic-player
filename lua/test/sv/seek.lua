--
-- Tests relating to audio seeking from client to server or reversed
--

-- PROBLEMS:

-- NICE TODO

-- TODO improve: use a dummy player as admin and make admin calls with it

insulate("sv - Mute server audio for non admin", function()
  local dermaBase, media = create_with_dark_mode()
  it("setup assert rules", function()
    assert.set_derma(dermaBase)
  end)
  describe("play live", function()
    _reset_server()
    init_sv_shared_settings()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)

    local channel = media.sv_PlayingSong
    dermaBase.main:SwitchMode()
    _set_player_admin(true)
    dermaBase.buttonplay:DoClick(nil, 0)
    _set_player_admin(false)

    media.sv_PlayingSong:set_volume(0.8)
    local vol_channel = 0
    local vol_slider = 0
    describe("pause", function()
      dermaBase.buttonpause:DoClick()
      assert.is_false(channel.isPaused)
      assert.is_true(channel.isLivePaused)

      it("audio muted", function()
        vol_channel = media:get_volume(true)
        vol_slider = media:get_volume()
        assert.same(vol_channel, 0)
        assert.same(vol_slider, 0.8)
      end)
      it("ui live paused", function()
        assert.ui_top_bar_color(5, "Example1")
        assert.line_highlight(5, 1, 0, media.sv_PlayingSong)
        assert.same(channel.title_song, "Example1")
        assert.same(channel.title_status, " Muted: ")
      end)
    end)
    describe("unpause", function()
      it("audio unmuted", function()
        dermaBase.buttonpause:DoClick()
        vol_channel = media:get_volume(true)
        vol_slider = media:get_volume()
        assert.same(vol_channel, 0.8)
        assert.same(vol_slider, 0.8)
      end)
      it("ui live play", function()
        assert.ui_top_bar_color(1, "Example1")
        assert.line_highlight(1, 1, 0, media.sv_PlayingSong)
        assert.same(channel.title_song, "Example1")
        assert.same(channel.title_status, " Playing: ")
      end)
    end)
  end)
end)
