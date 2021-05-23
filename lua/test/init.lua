require("busted.runner")()
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
else
    print("[ FAIL ] Cannot start Busted Debugging")
end

require("test/mock/base")
require("test/mock/vgui")

AddCSLuaFile("vgui/seekbarclicklayer.lua")
AddCSLuaFile("vgui/seekbar.lua")
AddCSLuaFile("vgui/numslidernolabel.lua")
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
_G.view_context_menu = {}
_G.color = {}
_G.color.Play	= Color(0, 150, 0)
_G.color.APlay	= Color(70, 190, 180)
_G.color.Pause	= Color(255, 150, 0)
_G.color.APause	= Color(210, 210, 0)
_G.color.Loop	= Color(0, 230, 0)
_G.color.ALoop	= Color(45,205,115)
_G.color._404	= Color(240, 0, 0)
_G.color.Black 	= Color(0, 0, 0)
_G.color.White 	= Color(255, 255, 255)
_G.color.Stop   = Color(150, 150, 150)

-- colors used for dark mode
_G.color_light = {}
_G.color_light.bg       = Color(20, 150, 240)
_G.color_light.bghover  = Color(30, 30, 30, 130)
_G.color_light.text     = Color(0, 0, 0)
_G.color_light.bglist   = Color(245, 245, 245)
_G.color_light.slider   = Color(0, 0, 0, 100)

_G.color_dark = {}
_G.color_dark.bg       = Color(15, 110, 175)
_G.color_dark.bghover  = Color(230, 230, 230, 50)
_G.color_dark.text     = Color(230, 230, 230)
_G.color_dark.bglist   = Color(35, 35, 35)
_G.color_dark.slider   = Color(0, 0, 0, 100)
_G.create_with_dark_mode = function()
    local dermaBase =
        include("includes/modules/meth_base.lua")(view_context_menu, -1)
    dermaBase.mediaplayer:net_init()
    dermaBase.painter:change_theme(true)
    dermaBase.song_data:load_from_disk()
    dermaBase.create(view_context_menu)
    dermaBase.painter:update_colors()
    local media = dermaBase.mediaplayer
    dermaPanel = dermaBase
    return dermaBase, media
end


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

    _set_player_admin(true)
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