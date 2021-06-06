--
-- Tests relating to audio seeking
--

-- PROBLEMS:
-- 1. Loop > Should loop song (test how loop works)
-- 2. I think the table of music isnt cleared if i remove songs from musicdirs(i tested this with autoplaying and moving the cursor to end and it still plays the each one. So far i can block the autoplay if list is empty). Correct fix would be to stop music if you press remove musicdirs and all dirs are removed

-- NICE TODO
-- 1. Would  be nice that the seek end monitor timer changes the trigger delay based on the length of the audio, using timer.Adjust
-- 2. If pressing the current time(left time) then it should revert to 0, kinda like a restart button. Using the Play button might be bad if you already scrolled
-- 3. Do a recheck so volume remains in 0-1 range. Also allow values over 1 but there should be a limit, kinda a amplify checkbox in settings
-- 4. Maybe add a new field in GMPL.AUDIO about 'play_from' and set it to 0 and 1, 0 for client and 1 for server. This way you can know from where the audio is playing even when switching modes or pausing the audio

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
        AudioChannel:_SetMaxTime(max_seek)
        dermaBase.sliderseek:AllowSeek(true)
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
                dermaBase.sliderseek:SetTime(first_seek)
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
                    dermaBase.sliderseek:SetTime(second_seek)
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
                dermaBase.sliderseek:SetTime(first_seek)
                it("audio time initial", function()
                    local initial_seek = dermaBase.sliderseek:GetTime()
                    local time_text = dermaBase.sliderseek.seek_text:GetValue()
                    local length_text =
                        dermaBase.sliderseek.seek_text_max:GetValue()

                    assert.are.equal(initial_seek, first_seek)
                    assert.are.equal(time_text, "01:40")
                    assert.are.equal(length_text, "06:40")
                end)
                it("audio time changed", function()
                    dermaBase.sliderseek:SetTime(second_seek)
                    local changed_seek = dermaBase.sliderseek:GetTime()
                    local time_text = dermaBase.sliderseek.seek_text:GetValue()

                    assert.are.equal(changed_seek, second_seek)
                    assert.are.equal(time_text, "03:20")
                end)
            end)
        end)
        describe("seek to end", function()
            dermaBase.sliderseek.seek_val.Slider:SetWide(650)
            dermaBase.sliderseek.seek_val:SetDragging(true)
            dermaBase.sliderseek.seek_val:OnCursorMoved(650)
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
                    local length_text =
                        dermaBase.sliderseek.seek_text_max:GetValue()

                    assert.are.equal(curr_time, 0)
                    assert.are.equal(time_text, "00:00")
                    assert.are.equal(length_text, "00:00")
                end)
            end)
        end)
        describe("seek after end", function()
            dermaBase.sliderseek.seek_val.Slider:SetWide(650)
            dermaBase.sliderseek.seek_val:SetDragging(true)
            dermaBase.sliderseek.seek_val:OnCursorMoved(651)
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
                    local length_text =
                        dermaBase.sliderseek.seek_text_max:GetValue()

                    assert.are.equal(curr_time, 0)
                    assert.are.equal(time_text, "00:00")
                    assert.are.equal(length_text, "00:00")
                end)
            end)
        end)
    end)
end)
