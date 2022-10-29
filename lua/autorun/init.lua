if (SERVER) then
  _G.gmusic_sv = {}
  -- server and shared ( i think )
  include("includes/modules/coms.lua")
  include("includes/func/settings.lua")
  include("gmpl/sv_gmpl.lua")
  --
  AddCSLuaFile("vgui/dhorizontalbox.lua")
  AddCSLuaFile("vgui/dbuttonswitch2.lua")
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
  --- register modules
  AddCSLuaFile("includes/modules/setup.lua")
  AddCSLuaFile("includes/modules/delegate.lua")
  AddCSLuaFile("includes/modules/musicplayerclass.lua")
  AddCSLuaFile("includes/modules/meth_base.lua")
  AddCSLuaFile("includes/modules/meth_paint.lua")
  AddCSLuaFile("includes/modules/meth_song.lua")
  AddCSLuaFile("includes/func/interface.lua")
  AddCSLuaFile("includes/func/audio.lua")
  -- register delegate calls
  AddCSLuaFile("includes/events/base.lua")
  AddCSLuaFile("includes/events/audio.lua")
  AddCSLuaFile("includes/events/interface.lua")
  --- register client only
  AddCSLuaFile("includes/func/net_calls_mandatory.lua")
  AddCSLuaFile("includes/func/net_calls_audio.lua")
  AddCSLuaFile("includes/func/messages.lua")
  ---
  -- AddCSLuaFile("includes/func/settings.lua")
  AddCSLuaFile("gmpl/cl_gmpl.lua")
  AddCSLuaFile("gmpl/cl_cvars.lua")
  --
  include("gmpl/sv_cvars.lua")
else
  _G.gmusic_cl = {}
  include("gmpl/cl_gmpl.lua")
end