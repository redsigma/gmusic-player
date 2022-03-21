--
-- Tests relating to audio volume
--


-- [gmusic-player] addons/gmusic-player/lua/includes/func/audio.lua:393: attempt to index local 'self' (a nil value)
--1. getMedia - addons/gmusic-player/lua/includes/func/audio.lua:393
--2. volume - addons/gmusic-player/lua/includes/func/audio.lua:749
--3. OnValueChanged - addons/gmusic-player/lua/includes/func/interface.lua:290
--4. ValueChanged - addons/gmusic-player/lua/vgui/numslidernolabel.lua:162
--5. OnValueChanged - addons/gmusic-player/lua/vgui/numslidernolabel.lua:60
--6. SetValue - lua/vgui/dnumberscratch.lua:47
--7. SetValue - addons/gmusic-player/lua/vgui/numslidernolabel.lua:128
--8. TranslateValues - addons/gmusic-player/lua/vgui/numslidernolabel.lua:171
--9. OnCursorMoved - lua/vgui/dslider.lua:108
--10. unknown - lua/vgui/dslider.lua:135

-- TODO
-- 1. Add tests for pause live and also when switching from server to client so nothing breaks cuz there was a bug which made it break when switch to client and then come back to server and disable it




insulate("Change volume On Click", function()
    local dermaBase, media = create_with_dark_mode()
    it("setup assert rules", function()
        assert.set_derma(dermaBase)
    end)
    describe("play", function()
        local song_line = 2
        it("is playing", function()
            dermaBase.buttonplay:DoClick(nil, song_line)
            assert.is_false(media.cl_PlayingSong.isPaused)
            assert.is_false(media.cl_PlayingSong.isStopped)
            assert.is_false(media.cl_PlayingSong.isLooped)
        end)
        describe("audio volume changed", function()
            local volume_changed = 42.5
            -- add test for higher val than 100
            dermaBase.slidervol:SetVolume(volume_changed)
            -- it("ui slider changed", function()
            --     local slider_number =
            --         dermaBase.sliderseek.seek_val:GetFloatValue()
            --     local slider_text = dermaBase.sliderseek.seek_text:GetValue()

            --     assert.are.equal(slider_number, seek_to)
            --     assert.are.equal(slider_text, "01:40")
            -- end)
            -- it("audio time changed", function()
            --     local seek_number = dermaBase.sliderseek:GetTime()
            --     assert.are.equal(seek_number, seek_to)
            -- end)
        end)
    end)
end)
