if (SERVER) then
	AddCSLuaFile("vgui/seekbarclicklayer.lua")
	AddCSLuaFile("vgui/seekbar.lua")
	AddCSLuaFile("vgui/numslidernolabel.lua")
	AddCSLuaFile("vgui/doublelist.lua")
	AddCSLuaFile("vgui/doptions.lua")
	AddCSLuaFile("vgui/playerframe.lua")
	AddCSLuaFile("vgui/dbettercheckbox.lua")
	AddCSLuaFile("vgui/dbettercblabel.lua")
	
	AddCSLuaFile "includes/modules/musicplayerclass.lua"
	AddCSLuaFile "includes/modules/meth_base.lua"
	AddCSLuaFile "includes/modules/meth_paint.lua"

	AddCSLuaFile("gmpl/cl_gmpl.lua")

	include("gmpl/sv_gmpl.lua")
else

	include("gmpl/cl_gmpl.lua")
end
