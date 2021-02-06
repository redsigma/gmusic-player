local mediaplayer = nil
local base_panel_colors = nil

local dermaBase = {}
local contextMenu = nil
local contextMenuMargin = ScrW() / 5
local ingameView = nil

surface.CreateFont( "arialDefault", {
	font = "Arial",
	extended = false,
	size = 16,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

local function createMPlayer(ply)
	mediaplayer:SyncSettings(ply)
	mediaplayer:create()
	ingameView = dermaBase.main:GetParent()
end

local function showMPlayer( newHost )



	if dermaBase.main:IsVisible() then
        print("In context: ", LocalPlayer():IsWorldClicking())
        if LocalPlayer():IsWorldClicking() then
            if dermaBase.main:HasParents(ingameView) then
                // was in game screen -> move to context
                print("Was in ingame -> move to context")
                gui.EnableScreenClicker(false)
                dermaBase.main:SetParent(contextMenu)
            end
        else
            -- if dermaBase.main:HasParents(contextMenu) then
            --     // was in context menu -> move to game screen
            --     print("Was in context menu -> move to ingame")
            --     gui.EnableScreenClicker(true)
            --     dermaBase.main:SetParent(ingameView)

            if dermaBase.main:HasParents(contextMenu) then
                // TODO it seems the IsWorldClicking doesnt maintain true when changing parent to ingame ;//, maybe just try to make it work for the clickable gMusic Player button
                print("no change from context -> hide")
                gui.EnableScreenClicker(false)
                dermaBase.main:SetVisible(false)
            else
                print("no change from ingame -> hide")
                gui.EnableScreenClicker(false)
                dermaBase.main:SetVisible(false)
            end
        end
    else
        if LocalPlayer():IsWorldClicking() then
            if dermaBase.main:HasParents(ingameView) then
                print("start in context menu")
                gui.EnableScreenClicker(false)
                dermaBase.main:SetParent(contextMenu)
            else
                -- gui.EnableScreenClicker(false)
                -- dermaBase.main:SetVisible(false)
            end
        else
            if dermaBase.main:HasParents(contextMenu) then
                // was in context menu -> move to game screen
                print("start in ingame")
                gui.EnableScreenClicker(true)
                dermaBase.main:SetParent(ingameView)
            end
        end
	-- 	if dermaBase.main:HasParents(contextMenu) &&
    --         LocalPlayer():IsWorldClicking() then
    --         print("Was in context menu -> move to ingame")
    --         // was in context menu -> move to game screen
    --         gui.EnableScreenClicker(true)
	-- 		dermaBase.main:SetParent(ingameView)
    --     elseif dermaBase.main:HasParents(ingameView) &&
    --         LocalPlayer():IsWorldClicking() then
    --         print("Was in ingame -> move to context")
    --         // was in game screen -> move to context
    --         gui.EnableScreenClicker(false)
    --         dermaBase.main:SetParent(contextMenu)
	-- 	else
    --         print("Was the same -> hide")
	-- 		RememberCursorPosition()
	-- 		dermaBase.main:SetVisible(false)
	-- 		gui.EnableScreenClicker(false)
	-- 	end
	-- else
    --     if LocalPlayer():IsWorldClicking() then
    --         // focus if context already opened
    --         print("In context menu -> context on")
	-- 		dermaBase.main:SetParent(contextMenu)
    --     elseif dermaBase.main:HasParents(ingameView) then
    --         print("Not in context menu -> enable clicker")
    --          // if closed then enable clicker
	-- 		gui.EnableScreenClicker(true)
	-- 	end

		mediaplayer:SetSongHost(newHost)
        dermaBase.main:SetVisible(true)
		mediaplayer:SyncSettings(nil) -- will sync using LocalPlayer()
		RestoreCursorPosition()
	end
end

hook.Add("ContextMenuCreated", "create_context", function(context_menu)
    contextMenu = context_menu
end)

--[[-------------------------------------------------------------------------
Runs if server not just Created
---------------------------------------------------------------------------]]--
net.Receive( "sendServerSettings", function()
	local serverSettings = net.ReadTable()

	dermaBase.cbadminaccess:SetChecked(serverSettings.admin_server_access)
	dermaBase.cbadmindir:SetChecked(serverSettings.admin_dir_access)
end )


--[[-------------------------------------------------------------------------
First Run on server start
---------------------------------------------------------------------------]]--
net.Receive("createMenu", function()
    dermaBase = include("includes/modules/meth_base.lua")(
        contextMenu, contextMenuMargin)

	while !isfunction(dermaBase.main.IsVisible) do
		MsgC(Color( 144, 219, 232 ), "[gMusic Player]", Color(255, 0, 0),
            " Failed to initialize - retrying\n" )
		dermaBase = include("includes/modules/meth_base.lua")(
            contextMenu, contextMenuMargin)
	end

    include("gmpl/cl_cvars.lua")(dermaBase)

	require("musicplayerclass")
	mediaplayer = Media(dermaBase)

	net.Start("serverFirstMade")
	net.SendToServer()

	local currentPlyIsAdmin = net.ReadBool()
	mediaplayer:readFileSongs()
	createMPlayer(currentPlyIsAdmin)

    -- print("Creating base panel:")
    -- base_panel_colors = vgui.Create("DBasePanel")
    -- base_panel_colors:say()
end )

net.Receive( "getSettingsFromFirstAdmin", function()
    if IsValid(LocalPlayer()) and LocalPlayer():IsAdmin() then
		local storeCurrentSettings = {}
		storeCurrentSettings.admin_server_access =
            GetConVar("gmpl_svadminplay"):GetBool()
		storeCurrentSettings.admin_dir_access =
            GetConVar("gmpl_svadmindir"):GetBool()

		net.Start("updateSettingsFromFirstAdmin")
		net.WriteTable(storeCurrentSettings)

		if storeCurrentSettings.admin_dir_access then
			net.WriteTable(mediaplayer:getLeftSongList())
			net.WriteTable(mediaplayer:getRightSongList())
		end
		net.SendToServer()
	end
end )
---------------------------------------------------------------------------]]--


--[[-------------------------------------------------------------------------
Server convars
---------------------------------------------------------------------------]]--
net.Receive( "refreshAdminAccess", function(length, sender)
	local tmpVal = net.ReadBool()
	dermaBase.cbadminaccess:SetChecked(tmpVal)
end )

net.Receive( "refreshAdminAccessDir", function(length, sender)
	local tmpVal = net.ReadBool()
	dermaBase.cbadmindir:SetChecked(tmpVal)
end )
---------------------------------------------------------------------------]]--

net.Receive("openmenu", function()
	local adminHost = net.ReadType()
	mediaplayer:SetSongHost(adminHost)
	showMPlayer(adminHost)
end )

net.Receive("openmenucontext", function()
	local adminHost = net.ReadType()
	mediaplayer:SetSongHost(adminHost)
	showMPlayer(adminHost)
end )

concommand.Add("gmplshow", function()
	showMPlayer()
end)


cvars.AddChangeCallback( "gmpl_vol", function( convar , oldValue , newValue  )
	if !istable(mediaplayer) then return end
	if (isnumber(util.StringToType( newValue, "Float" ))) then
		-- if istable(mediaplayer) then
			mediaplayer:SetVolume(newValue)
		-- end
	elseif (isnumber(util.StringToType( oldValue, "Float" ))) then
		-- if istable(mediaplayer) then
			mediaplayer:SetVolume(oldValue)
			MsgC(Color(255,0,0),"Only 0 - 100 value is allowed. Keeping value " .. oldValue .. "\n")
		-- end
	end
end )

-- hook.Add("OnScreenSizeChanged", "warn_users", function(old_width, old_height)
--     // Keep this warning to notice users of this bug
--      local dialog_warning = vgui.Create("DFrame")
--      dialog_warning:SetSize(350, 200)
--      dialog_warning:SetDeleteOnClose(true)
--      dialog_warning:ShowCloseButton(false)
--      dialog_warning:Center()
--      dialog_warning:SetTitle("Warning resolution changed")
--      dialog_warning:MoveToFront()

--      dialog_warning.Label = vgui.Create("RichText", dialog_warning)
--      dialog_warning.Label:SetVerticalScrollbarEnabled(false)
--      dialog_warning.Label:Dock(FILL)
--      dialog_warning.Label:InsertColorChange(255, 255, 255, 255)
--      dialog_warning.Label:AppendText(
--          "Resolution Change Detected!\n\nBecause of this, a small panel will appear in the left corner due to a bug in Gmod. Please reconnect to the server or live with it :)")
--      dialog_warning.Label.Paint = function(panel)
--          panel:SetFontInternal( "GModNotify" )
--          panel.Paint = nil
--      end

--      local bottom = vgui.Create("Panel", dialog_warning)
--      bottom:Dock(BOTTOM)

--      bottom.btn = vgui.Create("DButton", bottom)
--      bottom.btn:Dock(FILL)
--      bottom.btn:DockMargin(4, 0, 0, 0)
--      bottom.btn:SetText("I Understand")
--      bottom.btn:SetFont("GModNotify")
--      bottom.btn.Paint = function(panel, w, h)
--          surface.SetDrawColor(Color(255, 255, 255))
--          surface.DrawRect(0, 0, w, h)
--      end
--      bottom.btn.DoClick = function()
--          dialog_warning:Close()
--      end
-- end)
