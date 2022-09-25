--
-- Tests relating to audio seeking from client to server or reversed
--
-- PROBLEMS:
-- NICE TODO
-- TODO improve: use a dummy player as admin and make admin calls with it
--[[
  NOT SURE what i wanted here but i assume it's something related to muting on
  server mode when you are admin and when you're not
  IMO in both cases the muting should happen only on client side and should not affect the actual players
insulate("sv - Mute server audio for non admin", function()
  local dermaBase, media = create_with_dark_mode()

  it("setup assert rules", function()
    assert.set_derma(dermaBase)
  end)

  describe("play live", function()
    _reset_server()
    init_sv_shared_settings()
    dermaBase.main:SwitchMode()
    local channel = media.sv_PlayingSong
    _set_checkbox_as_admin(dermaBase.cbadminaccess, true)
    _.set_player_admin(true)
    dermaBase.buttonplay:DoClick(nil, 0)
    channel:set_volume(0.8)
    _.set_player_admin(false)
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
]]