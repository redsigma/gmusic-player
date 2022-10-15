local insulate = 0
local describe = 0
local it = 0
local assert = 0

_G.setup_sh_interface = function(_insulate, _describe, _it, _assert)
  insulate, describe, it, assert = init_unit_test_func()
end

-------------------------------------------------------------------------------
function play_cl_switch_sv(dermaBase)
  _reset_server()

  describe("cl play", function()
    local cl_song_index = 1
    dermaBase.main:SwitchModeClient()
    dermaBase.buttonplay:DoClick(nil, cl_song_index)
    local song_list = dermaBase.songlist:GetLines()
    local cl_line = song_list[cl_song_index]

    it("cl has ui highlight ", function()
      assert.ui_top_bar_color(1, "Example1")
      assert.line_highlight_play(1, 0)
      assert.are.same(cl_line.bgcol, color.Play)
    end)

    describe("switch sv", function()
      dermaBase.main:SwitchModeServer()

      it("cl no ui highlight ", function()
        assert.ui_top_bar_color(-1, "gMusic Player")
        assert.are.same(Color.len(cl_line.bgcol), 0)
      end)
    end)
  end)
end

function play_sv_switch_cl(dermaBase)
  describe("sv play", function()
    local sv_song_index = 1
    dermaBase.main:SwitchMode(true)
    dermaBase.buttonplay:DoClick(nil, sv_song_index)
    local song_list = dermaBase.songlist:GetLines()
    local sv_line = song_list[sv_song_index]

    it("sv has ui highlight ", function()
      assert.ui_top_bar_color(1, "Example1")
      assert.line_highlight_play(1, 0)
      assert.are.same(sv_line.bgcol, color.Play)
    end)

    describe("switch cl", function()
      dermaBase.main:SwitchMode(false)

      it("sv no ui highlight ", function()
        assert.ui_top_bar_color(-1, "gMusic Player")
        assert.are.same(Color.len(sv_line.bgcol), 0)
      end)
    end)
  end)
end