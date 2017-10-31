 -- snd_musicvolume 1     controls ingame music volume slider
 -- snd_mute_losefocus #  something interesting here too
 -- IGModAudioChannel:EnableLooping( boolean enable )   // check looping
-- surface.PlaySound( "/music/hl2_song20_submix0.mp3" )  // the same as type [play songname] in console
-- try making an autoplay version for the next song

require("musicplayerClass")
local mediaplayer = Media()

local function main()
    mediaplayer:getMenu()
end

net.Receive( "openmenu", function()
    local musicplayer = net.ReadEntity()
    if TypeID(musicplayer) == TYPE_ENTITY then
      main()
    end
end )


concommand.Add("gmplshow", function()
  mediaplayer:getMenu()
end)


cvars.AddChangeCallback( "gmpl_vol", function( convar , oldValue , newValue  )
  if (TypeID(util.StringToType( newValue, "Float" )) == TYPE_NUMBER) then
    mediaplayer:SetVolume(newValue)
  elseif (TypeID(util.StringToType( oldValue, "Float" )) == TYPE_NUMBER) then
    mediaplayer:SetVolume(oldValue)
    MsgC(Color(255,0,0),"Invalid command value. Value not changed ( \"" ..  oldValue .. "\" )\n")
  end
end )
