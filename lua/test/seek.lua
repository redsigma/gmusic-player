--
-- Tests relating to audio seeking
--

-- PROBLEMS:
-- 1. Loop > Should loop song (test how loop works)
-- 2. I think the table of music isnt cleared if i remove songs from musicdirs(i tested this with autoplaying and moving the cursor to end and it still plays the each one. So far i can block the autoplay if list is empty). Correct fix would be to stop music if you press remove musicdirs and all dirs are removed
-- 3. Dont allow user to move slider if adminaccess true and he is not admin. Do test too
-- 4. Switching to server or client while music playing will change seek pos but music doesnt change. Make it so seek wont change if pressing server or client. Make it that if Users is listening to server(might need to use a new bool for current_mode ) then even if he is on client the next server audio will play for him

-- NICE TODO
-- 1. Would  be nice that the seek end monitor timer changes the trigger delay based on the length of the audio, using timer.Adjust
-- 2. If pressing the current time(left time) then it should revert to 0, kinda like a restart button. Using the Play button might be bad if you already scrolled
-- 3. Do a recheck so volume remains in 0-1 range. Also allow values over 1 but there should be a limit, kinda a amplify checkbox in settings
-- 4. Maybe add a new field in GMPL.AUDIO about 'play_from' and set it to 0 and 1, 0 for client and 1 for server. This way you can know from where the audio is playing even when switching modes or pausing the audio
-- 5. Check if you can detect if someone goes to q-menu > admin > clean-up everything.
-- 6. When host becomes unavaiable cuz disconnect or lost admin, make the text change to red or maybe put the text in a red square. Might need to make a custom derma or a function. Also currently the "Unavailable" text changes back to "Host" when toggling the player on and off. This could be ok so make a test that keeps it like this
-- 7. Add test for musicdirs to detect audio in first subfolder. Also make it work for workshop files too cuz it doesnt work now. ALSO you should separate client side and server side musicdirs cuz if they are different then it should work like that too Client can have its own dirs and server can have others or the same
-- 8. Auto play client side then switch to server and seek to end. It should play the server when switching to server and client when switching back to client. Same for seeking, it doesnt work. Make it so right clicking on SERVER tss can live seek too
-- Same for stop but it doesnt stop, instead only hides the slider
-- 9.Pause live breaks if you pause live and then switch to client. When back to server pause live wont work properly. Also i might need to change the logic for volume so i grab the value from the slider instead of remembering each value for each channel
-- 10. Also sometimes when autoplay on server and switch to client. If you wait for the song to finish it will start on client but without any ui changes. This might be related to the live pause problem from 9. cuz it happen while i was doing that
-- 11. Click on the end time text can seek to end. This is ok but it seems that if put the slider near the end and then press the end time text it live seeks 2 songs. Seems that on client the slider also goes to a random position sometimes
-- 12. Play song on client and live seek on server. When client reaches last second switch to server. Then switch back to client and client plays the song again instead of stopping. I gotta try do to a unit test to find the cause cuz i couldnt guess it, it might not be fixable though

insulate("Seek On Click", function()
  local dermaBase, media = create_with_dark_mode()
  it("setup assert rules", function()
    assert.set_derma(dermaBase)
  end)
  describe("play", function()
    local song_line = 2
    local first_seek = 100.25
    local second_seek = 200.25
    local max_seek = 400.25

    _set_slider_seek_max(max_seek)
    it("is playing", function()
      dermaBase.buttonplay:DoClick(nil, song_line)
      assert.is_false(media.cl_PlayingSong.isPaused)
      assert.is_false(media.cl_PlayingSong.isStopped)
      assert.is_false(media.cl_PlayingSong.isLooped)
    end)

    local slider_first_pos = 0.25046845721424110254
    local slider_second_pos = 0.50031230480949406836
    describe("seek", function()
      describe("ui slider", function()
        -- dermaBase.sliderseek:SetTime(first_seek)
        _slider_seek_secs(first_seek)
        it("initial slider pos", function()
          local curr_slider =
            dermaBase.sliderseek.seek_val.current_slider_pos
          local prev_slider =
            dermaBase.sliderseek.seek_val.previous_slider_pos
          local is_slider_handle_visible =
            dermaBase.sliderseek.seek_val.Slider.Knob:IsVisible()

          assert.are.equal(curr_slider, slider_first_pos)
          assert.are.equal(prev_slider, 0.0)
          assert.are.equal(is_slider_handle_visible, true)
        end)
        it("change slider pos", function()
          -- dermaBase.sliderseek:SetTime(second_seek)
          _slider_seek_secs(second_seek)
          local curr_slider =
              dermaBase.sliderseek.seek_val.current_slider_pos
          local prev_slider =
              dermaBase.sliderseek.seek_val.previous_slider_pos
          local is_slider_handle_visible =
              dermaBase.sliderseek.seek_val.Slider.Knob:IsVisible()

          assert.are.equal(curr_slider, slider_second_pos)
          assert.are.equal(prev_slider, slider_first_pos)
          assert.are.equal(is_slider_handle_visible, true)
        end)
      end)
      describe("change audio", function()
        -- dermaBase.sliderseek:SetTime(first_seek)
        _slider_seek_secs(first_seek)
        it("audio time initial", function()
          local initial_seek = dermaBase.sliderseek:GetTime()
          local time_text = dermaBase.sliderseek.seek_text:GetValue()
          local length_text = dermaBase.sliderseek.seek_text_max:GetValue()

          assert.are.equal(initial_seek, first_seek)
          assert.are.equal(time_text, "01:40")
          assert.are.equal(length_text, "06:40")
        end)
        it("audio time changed", function()
          -- dermaBase.sliderseek:SetTime(second_seek)
          _slider_seek_secs(second_seek)
          local changed_seek = dermaBase.sliderseek:GetTime()
          local time_text = dermaBase.sliderseek.seek_text:GetValue()

          assert.are.equal(changed_seek, second_seek)
          assert.are.equal(time_text, "03:20")
        end)
      end)
    end)
    describe("seek to end", function()
      _set_slider_seek_max(max_seek)
      _set_slider_size(650)
      _slider_seek(650)
      describe("ui slider", function()
        it("reset slider pos", function()
          local curr_slider =
            dermaBase.sliderseek.seek_val.current_slider_pos
          local prev_slider =
            dermaBase.sliderseek.seek_val.previous_slider_pos
          local is_slider_handle_visible =
            dermaBase.sliderseek.seek_val.Slider.Knob:IsVisible()

          assert.are.equal(curr_slider, 0.0)
          assert.are.equal(prev_slider, slider_second_pos)
          assert.are.equal(is_slider_handle_visible, false)
        end)
      end)
      describe("stop audio", function()
        it("reset audio time", function()
          local curr_time = dermaBase.sliderseek:GetTime()
          local time_text = dermaBase.sliderseek.seek_text:GetValue()
          local length_text = dermaBase.sliderseek.seek_text_max:GetValue()

          assert.are.equal(curr_time, 0)
          assert.are.equal(time_text, "00:00")
          assert.are.equal(length_text, "00:00")
        end)
      end)
    end)
    describe("seek after end", function()
      _set_slider_seek_max(max_seek)
      _set_slider_size(650)
      _slider_seek_secs(second_seek)
      _slider_seek(651)
      describe("ui slider", function()
        it("reset slider pos", function()
          local curr_slider =
            dermaBase.sliderseek.seek_val.current_slider_pos
          local prev_slider =
            dermaBase.sliderseek.seek_val.previous_slider_pos
          local is_slider_handle_visible =
            dermaBase.sliderseek.seek_val.Slider.Knob:IsVisible()

          assert.are.equal(curr_slider, 0.0)
          assert.are.equal(prev_slider, slider_second_pos)
          assert.are.equal(is_slider_handle_visible, false)
        end)
      end)
      describe("stop audio", function()
        it("reset audio time", function()
          local curr_time = dermaBase.sliderseek:GetTime()
          local time_text = dermaBase.sliderseek.seek_text:GetValue()
          local length_text = dermaBase.sliderseek.seek_text_max:GetValue()

          assert.are.equal(curr_time, 0)
          assert.are.equal(time_text, "00:00")
          assert.are.equal(length_text, "00:00")
        end)
      end)
    end)
  end)
end)
