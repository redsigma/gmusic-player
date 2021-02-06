util.AddNetworkString( "serverFirstMade")	util.AddNetworkString( "sendServerSettings")
util.AddNetworkString( "getSettingsFromFirstAdmin")	util.AddNetworkString( "updateSettingsFromFirstAdmin")

util.AddNetworkString( "createMenu" )
util.AddNetworkString( "requestHotkeyFromServer")

util.AddNetworkString( "toServerContext")	util.AddNetworkString( "openmenucontext")
util.AddNetworkString( "toServerHotkey")	util.AddNetworkString( "openmenu" )

util.AddNetworkString( "toServerStop" )	util.AddNetworkString( "stopFromServer" )
util.AddNetworkString( "toServerSeek" )	util.AddNetworkString( "seekFromServer" )

util.AddNetworkString( "toServerAdminPlay" )	util.AddNetworkString( "playFromServer_adminAccess" )	util.AddNetworkString( "playFromServer" )
util.AddNetworkString( "toServerAdminStop" )	util.AddNetworkString( "stopFromServerAdmin" )
util.AddNetworkString( "toServerUpdateLoop" )	util.AddNetworkString( "loopFromServer" )

-- AutoPlay Mechanic
util.AddNetworkString( "sv_autoPlay" )  util.AddNetworkString( "cl_autoPlay" )
util.AddNetworkString( "sv_getAutoPlaySong" )  util.AddNetworkString( "cl_ansAutoPlaySong" )
util.AddNetworkString( "cl_errAutoPlaySong" )

-- Live Seek Mechanic
util.AddNetworkString( "askAdminForLiveSeek" )
util.AddNetworkString( "toServerUpdateSeek" )
util.AddNetworkString( "playLiveSeek")

util.AddNetworkString( "toServerRefreshAccess")  util.AddNetworkString( "refreshAdminAccess")
util.AddNetworkString( "toServerRefreshAccess_msg")

util.AddNetworkString( "toServerRefreshAccessDir") util.AddNetworkString( "refreshAdminAccessDir")
util.AddNetworkString( "toServerRefreshAccessDir_msg")
util.AddNetworkString( "toServerRefreshSongList") util.AddNetworkString( "refreshSongListFromServer")

util.AddNetworkString( "persistClientSettings")
