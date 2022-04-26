--
-- Tests relating to audio seeking from client to server or reversed
--

-- PROBLEMS:
-- FIXED {} 1. While on client, after autoplay on serverside ended, the seek handle and end time becomes visible
-- 2. While on client, After autoplay serverside audio finishes, if you switch to client the slider will jump to the correct position instead of already being there. Maybe you can fix this. I think the slider isnt actually moving so make it moving but keep it invisible


-- NICE TODO

insulate("sv - Autoplay server, play next from client", function()
  local dermaBase, media = create_with_dark_mode()
  it("setup assert rules", function()
    assert.set_derma(dermaBase)
  end)
  describe("autoplay live", function()
    init_sv_shared_settings()
    _set_checkbox_as_admin(dermaBase.cbadminaccess, false)
    local max_seek = 450
    _set_slider_seek_max(450)
    dermaBase.slidervol:SetVolume(80)
    dermaBase.main:SwitchMode()

    local sv_channel = media.sv_PlayingSong
    local cl_channel = media.cl_PlayingSong
    local vol_channel = 0
    local vol_slider = 0
    -- _set_player_admin(true)


    dermaBase.buttonplay:DoClick(nil, 0)
    dermaBase.buttonplay:DoRightClick()
    assert.same(sv_channel.song, "sound/folder1/Example1.mp3")
    -- _set_player_admin(false)



    describe("switch client", function()
      dermaBase.main:SwitchMode()
      _channel_reach_end(true)
      it("server muted", function()
        assert.same(sv_channel.song, "sound/folder1/Example2.mp3")
        assert.same(sv_channel.volume, 0)
        assert.same(sv_channel:get():GetVolume(), 0)
        assert.is_false(sv_channel.isPaused)
        assert.is_true(sv_channel.isPlaying)
        assert.is_false(sv_channel.isStopped)
        assert.is_false(sv_channel.isLooped)
        assert.is_true(sv_channel.isAutoPlaying)
      end)

      it("no client audio", function()
        assert.same(cl_channel.song, "")
        assert.same(cl_channel.volume, 0)
        assert.same(cl_channel.title_status, "")
        assert.is_false(cl_channel.isPaused)
        assert.is_false(cl_channel.isPlaying)
        assert.is_true(cl_channel.isStopped)
        assert.is_false(cl_channel.isLooped)
        assert.is_false(cl_channel.isAutoPlaying)
      end)

      it("no ui change", function()
        local curr_time = dermaBase.sliderseek:GetTime()
        local time_text = dermaBase.sliderseek.seek_text:GetValue()
        local length_text = dermaBase.sliderseek.seek_text_max:GetValue()
        local is_slider_visible =
          dermaBase.sliderseek.seek_val.Slider.Knob:IsVisible()

        assert.ui_top_bar_color(-1, "gMusic Player")
        assert.are.equal(curr_time, 0)
        assert.are.equal(time_text, "00:00")
        assert.are.equal(length_text, "00:00")
        assert.are.equal(is_slider_visible, false)
      end)
    end)

    describe("switch server", function()
      dermaBase.main:SwitchMode()

      assert.same(sv_channel.song, "sound/folder1/Example2.mp3")
      assert.same(sv_channel.volume, 0.8)
      assert.is_false(sv_channel.isPaused)
      assert.is_true(sv_channel.isPlaying)
      assert.is_false(sv_channel.isStopped)
      assert.is_false(sv_channel.isLooped)
      assert.is_true(sv_channel.isAutoPlaying)

      assert.same(cl_channel.song, "")
      assert.same(cl_channel.volume, 0)
      assert.is_false(cl_channel.isPaused)
      assert.is_false(cl_channel.isPlaying)
      assert.is_true(cl_channel.isStopped)
      assert.is_false(cl_channel.isLooped)
      assert.is_false(cl_channel.isAutoPlaying)
    end)
  end)
end)



