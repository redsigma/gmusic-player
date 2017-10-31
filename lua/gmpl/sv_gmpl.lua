util.AddNetworkString( "openmenu" )

hook.Add("ShowSpare1", "openwithF3", function(ply)
   net.Start( "openmenu" )
   net.Send(ply)
end)
