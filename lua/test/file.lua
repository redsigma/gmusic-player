--
-- Tests relating to file IO
--

-- PROBLEMS:
-- TODO
-- 1. Check if the folder_dirs.txt file is modified locally. The search when refreshing music dirs should always scan the file again
-- 2. Rebuild left list wont work if i add new folders in a folder that is inside a folder that is already in the active folders. You might rename that button to `Refresh folders` cuz if i fix this it will also update the
-- second list

local files = {}
files.folder1 = {"11_example1.mp3", "_12example2.mp3", "!example3.mp3"}
files.folder1.subfolder1 = {"!example4.mp3", "example5.mp3"}
files.folder2 = {"example6.mp3", "!example7.mp3"}

insulate("Populate music dirs on start", function()
  _set_audio_files("GAME", {"folder1"}, files)
  _set_audio_files("WORKSHOP", {"folder2"}, files)
  local dermaBase, media = create_with_dark_mode()

  it("setup assert rules", function()
      assert.set_derma(dermaBase)
  end)
  describe("load from disk", function()
    dermaBase.songlist.Lines = {}
    local loaded = dermaBase.song_data:load_from_disk()
    it("song page populated", function()
      assert.are.equal(loaded, true)
      dermaBase.song_data:populate_song_page()
      dermaBase.song_data:get_song(2)

      local lines = dermaBase.songlist.Lines
      assert.are.equal(#lines, 7)
      -- sorted per folders and subfolders
      assert.are.equal(lines[1].Columns[0].text, "!example3")
      assert.are.equal(lines[2].Columns[0].text, "!example4")
      assert.are.equal(lines[3].Columns[0].text, "!example7")
      assert.are.equal(lines[4].Columns[0].text, "11_example1")
      assert.are.equal(lines[5].Columns[0].text, "_12example2")
      assert.are.equal(lines[6].Columns[0].text, "example5")
      assert.are.equal(lines[7].Columns[0].text, "example6")
    end)
  end)
end)
