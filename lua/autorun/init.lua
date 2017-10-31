
if (SERVER) then
	AddCSLuaFile("gmpl/cl_gmpl.lua")
	AddCSLuaFile("vgui/DSeekBar.lua")
	AddCSLuaFile("vgui/DSeekBarClickLayer.lua")
	AddCSLuaFile("vgui/DNumSliderNoLabel.lua")
	include("gmpl/sv_gmpl.lua")

else
	include("gmpl/cl_gmpl.lua")
	include("vgui/DSeekBar.lua")
	include("vgui/DSeekBarClickLayer.lua")
	include("vgui/DNumSliderNoLabel.lua")
end
