/*
    Convars that update at client side
*/

local dermaBase = {}
local function init(baseMenu)
	dermaBase = baseMenu
end
-------------------------------------------------------------------------------
/*
    Use gm_showspare1  to toggle the music player
    note: won't apply if the key is binded directly to F3
*/
net.Receive("press_Key_F3FromServer", function(length, sender)
    if !IsValid(dermaBase.hotkey) then return end

	if !dermaBase.hotkey:GetChecked() then
		net.Start("toServerKey_F3")
		net.SendToServer()
    elseif input.LookupKeyBinding(KEY_F3) == "gmplshow" then
        return
	end
end )
net.Receive("persistClientSettings", function(length, sender)
	dermaBase.darkmode.AfterChange = function(panel, bVal)
		dermaBase.painter.changeTheme(bVal)
        dermaBase.painter.update_colors()

		panel.OnCvarWrong = function(panel, old, new)
			MsgC(Color(255,0,0), "Only 0 - 1 value is allowed. Keeping value "
                .. oldValue .. " \n")
		end

	end
    dermaBase.darkmode:AfterChange(dermaBase.darkmode:GetChecked())
	dermaBase.contextbutton:AfterChange(dermaBase.contextbutton:GetChecked())
end )

return init