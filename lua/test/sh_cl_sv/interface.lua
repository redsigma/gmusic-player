--
-- Tests related to switching from CLIENT to SERVER
--
-- TODO
-- PROBLEMS:
-- Serverside reaches end, switching to client playing, client ui is reset.
-- SEEMS FIXED
-- Live seek both cl adn sv. When cl is at the last second switch to sv and it will loop live seek. Doesnt seems to always happen. Has something to do with that timer that monitors the end seek
insulate("cl-sv - End server song, dont affect client", function()
  local dermaBase, media = create_with_dark_mode()
  init_sv_shared_settings()
  local sv_channel = media.sv_PlayingSong
  local cl_channel = media.cl_PlayingSong
  local sv_line = 1
  local cl_line = 2

  it("setup assert rules", function()
    assert.set_derma(dermaBase)
  end)

  describe("play cl", function()
    dermaBase.main:SwitchMode(false)
    dermaBase.buttonplay:DoClick(nil, cl_line)
    cl_channel:set_volume(0.8)

    describe("play sv", function()
      dermaBase.main:SwitchMode(true)
      dermaBase.buttonplay:DoClick(nil, sv_line)
      sv_channel:set_volume(0.8)

      describe("reach end sv", function()
        dermaBase.main:SwitchMode(false)
        _sv_channel_reach_end()

        it("channels data", function()
          assert.same(cl_channel.title_song, "Example2")
          assert.same(cl_channel.song, "sound/folder1/Example2.mp3")
          assert.same(cl_channel.title_status, " Playing: ")
          assert.same(sv_channel.title_song, "")
          assert.same(sv_channel.song, "")
          assert.same(sv_channel.title_status, "")
        end)

        it("cl dont update ui", function()
          assert.ui_top_bar_color(1, "Example2")
          assert.line_highlight(1, cl_line, 0)
        end)
      end)
    end)
  end)
end)