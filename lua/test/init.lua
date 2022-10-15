require("busted.runner")()

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
else
  print("[ FAIL ] Cannot start Busted Debugging")
end

require("test/mock/base")
require("test/mock/util")
require("test/mock/vgui")
AddCSLuaFile("vgui/seekbarclicklayer.lua")
AddCSLuaFile("vgui/seekbar.lua")
AddCSLuaFile("vgui/volumebar.lua")
AddCSLuaFile("vgui/doublelist.lua")
AddCSLuaFile("vgui/doptions.lua")
AddCSLuaFile("vgui/playerframe.lua")
AddCSLuaFile("vgui/dsidemenu.lua")
AddCSLuaFile("vgui/dbettercheckbox.lua")
AddCSLuaFile("vgui/dbettercblabel.lua")
AddCSLuaFile("vgui/dsimplescroll.lua")
AddCSLuaFile("vgui/dbetterline.lua")
AddCSLuaFile("vgui/dbettercolumn.lua")
AddCSLuaFile("vgui/dbetterlist.lua")
AddCSLuaFile("vgui/dmultibutton.lua")
AddCSLuaFile("vgui/dbetterbutton.lua")
require("test/mock/hook")
require("test/mock/net")
require("includes/modules/coms")
require("gmpl/sv_gmpl")
-- Unit tests used in multiple files
require("test/common/interface")
require("test/common/interface_sh")
_G.gmusic_sv = {}
_G.gmusic_cl = {}
_G.view_context_menu = {}
_G.color = {}
_G.color.Play = Color(0, 150, 0)
_G.color.APlay = Color(70, 190, 180)
_G.color.Pause = Color(255, 150, 0)
_G.color.APause = Color(210, 210, 0)
_G.color.Loop = Color(0, 230, 0)
_G.color.ALoop = Color(45, 205, 115)
_G.color._404 = Color(240, 0, 0)
_G.color.Black = Color(0, 0, 0)
_G.color.White = Color(255, 255, 255)
_G.color.Stop = Color(150, 150, 150)
-- colors used for dark mode
_G.color.light = {}
_G.color.light.bg = Color(20, 150, 240)
_G.color.light.bghover = Color(30, 30, 30, 130)
_G.color.light.text = Color(0, 0, 0)
_G.color.light.bglist = Color(245, 245, 245)
_G.color.light.slider = Color(0, 0, 0, 100)
_G.color.dark = {}
_G.color.dark.bg = Color(15, 110, 175)
_G.color.dark.bghover = Color(230, 230, 230, 50)
_G.color.dark.text = Color(230, 230, 230)
_G.color.dark.bglist = Color(35, 35, 35)
_G.color.dark.slider = Color(0, 0, 0, 100)
local files_local = {}

files_local.folder1 = {"Example1.mp3", "Example2.mp3"}

files_local.folder2 = {"Example3.mp3", "Example4.mp3", "example5.mp3"}

local files_workshop = {}

files_workshop.folder1 = {"Example20.mp3"}

files_workshop.folder2 = {"Example30.mp3"}

_set_audio_files("GAME", {"folder1", "folder2"}, files_local)

_set_audio_files("WORKSHOP", {"folder1", "folder2"}, files_workshop)

--[[
  Older version before singleton refactor
]]
-- _G.create_with_dark_mode = function()
--   local dermaBase = include("includes/modules/meth_base.lua")(view_context_menu, -1)
--   dermaBase.mediaplayer:net_init()
--   dermaBase.painter:theme_dark(true)
--   string._Explode_Separator("\\n")
--   local loaded = dermaBase.song_data:load_from_disk()

--   if loaded then
--     dermaBase.song_data:populate_song_page()
--   end

--   dermaBase.create(view_context_menu)
--   dermaBase.painter:update_colors()
--   include("gmpl/cl_cvars.lua")(dermaBase)
--   require("gmpl/sv_cvars")
--   local media = dermaBase.mediaplayer
--   dermaPanel = dermaBase

--   return dermaBase, media
-- end

_G.create_with_dark_mode = function()
  local dermaBase = include("includes/modules/setup.lua").derma()
  dermaBase.painter:theme_dark(true)

  include("gmpl/cl_cvars.lua")
  require("gmpl/sv_cvars")
  local media = dermaBase.mediaplayer
  dermaPanel = dermaBase

  return dermaBase, media
end

_G._dermaBase = {}

_G.set_derma = function(state, arguments)
  if not type(arguments[1]) == "table" then return false end
  _G._dermaBase = arguments[1]

  return true
end
-- local insulate = nil
-- local describe = 0
-- local it = nil
-- local assert = nil
-- // TODO
--     [OK] play > loop > is looping
--     [OK] play > loop > pause > is paused
--     [OK] play > loop > pause > unpause > is looping
--     [OK] play > autoplay > is autoplayed
--     [OK] play > autoplay > pause > is paused
--     [OK] play > autoplay > pause > unpause > is playing autoplayed
--     [OK] play > pause > play > is playing
--     play > pause > loop > is looping
--     play > pause > loop > unpause > is playing
--     play > pause > autoplay > is playing
--     autoplay > is playing autoplayed
-- //
-- FACTS
-- assert.are.equal  <-- checks the refference address
-- assert.are.same   <-- checks content
-- SERVER SIDE
--------------------------------------------------------------------------------
-- insulate("-- Play On Click --\n", function()
--     local dermaBase = {}
--     local media = nil
--     dermaBase = include("includes/modules/meth_base.lua")(view_context_menu, -1)
--     require("gmpl/sv_gmpl")
--     require("includes/modules/musicplayerclass")
--     dermaBase.mediaplayer = Media(dermaBase)
--     dermaBase.mediaplayer:net_init()
--     dermaBase.song_data:load_from_disk()
--     dermaBase.create(view_context_menu)
--     media = dermaBase.mediaplayer
--     dermaBase.main:SwitchMode()
--     describe("play audio", function()
--         it("play audio", function()
--             dermaBase.buttonplay:DoClick()
--             assert.is_false(media.sv_PlayingSong.isPaused)
--             assert.is_false(media.sv_PlayingSong.isStopped)
--             assert.is_false(media.sv_PlayingSong.isLooped)
--         end)
--         it("and update ui play", function()
--             assert.same(media.sv_PlayingSong.title_song, "Example1")
--             assert.same(media.sv_PlayingSong.song,
--                 "sound/folder1/Example1.mp3")
--             assert.same(media.sv_PlayingSong.title_status, " Playing: ")
--         end)
--         describe("then stop audio", function()
--             it("must pause", function()
--                 dermaBase.buttonstop:DoClick()
--                 assert.is_false(media.sv_PlayingSong.isPaused)
--                 assert.is_true(media.sv_PlayingSong.isStopped)
--                 assert.is_false(media.sv_PlayingSong.isLooped)
--             end)
--             it("and reset ui", function()
--                 assert.same(media.sv_PlayingSong.title_song, 0)
--                 assert.same(media.sv_PlayingSong.song, "")
--                 assert.same(media.sv_PlayingSong.title_status, "")
--             end)
--         end)
--     end)
-- end)
--[[
insulate("-- EXPERImeNT On Click --\n", function()
    -- local dermaBase = {}
    -- local media = nil

    -- dermaBase = include("includes/modules/meth_base.lua")(view_context_menu, -1)
    require("gmpl/sv_gmpl")
    require("gmpl/cl_gmpl")

    hook._Run("Initialize")
    hook._Run("PlayerInitialSpawn")
    -- require("includes/modules/musicplayerclass")

    -- dermaBase.mediaplayer = Media(dermaBase)
    -- dermaBase.mediaplayer:net_init()

    -- dermaBase.song_data:load_from_disk()
    -- dermaBase.create(view_context_menu)

    media = dermaBase.mediaplayer
    -- dermaBase.main:SwitchMode()

    describe("play audio", function()
        it("play audio", function()
            dermaBase.buttonplay:DoClick()
            assert.is_false(media.sv_PlayingSong.isPaused)
            assert.is_false(media.sv_PlayingSong.isStopped)
            assert.is_false(media.sv_PlayingSong.isLooped)
        end)
        it("and update ui play", function()
            assert.same(media.sv_PlayingSong.title_song, "Example1")
            assert.same(media.sv_PlayingSong.song,
                "sound/folder1/Example1.mp3")
            assert.same(media.sv_PlayingSong.title_status, " Playing: ")
        end)
        describe("then stop audio", function()
            it("must pause", function()
                dermaBase.buttonstop:DoClick()
                assert.is_false(media.sv_PlayingSong.isPaused)
                assert.is_true(media.sv_PlayingSong.isStopped)
                assert.is_false(media.sv_PlayingSong.isLooped)
            end)
            it("and reset ui", function()
                assert.same(media.sv_PlayingSong.title_song, 0)
                assert.same(media.sv_PlayingSong.song, "")
                assert.same(media.sv_PlayingSong.title_status, "")
            end)
        end)
    end)
end)
]]