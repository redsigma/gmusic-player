local PANEL = {}

AccessorFunc( PANEL, "m_bDisabled",		"Disabled",			FORCE_BOOL )
AccessorFunc( PANEL, "m_bBorder", "DrawBorder", FORCE_BOOL )

function PANEL:Init()
    self:SetContentAlignment( 5 )

    self:SetDrawBorder( false )

    self:SetTall( 22 )
    self:SetMouseInputEnabled( true )
    self:SetKeyboardInputEnabled( true )

    self:SetCursor( "hand" )
    self:SetFont( "DermaDefault" )

end

function PANEL:IsDown()
    return self.Depressed
end

function PANEL:SetImage( img )

    if ( !img ) then
        if ( IsValid( self.m_Image ) ) then
            self.m_Image:Remove()
        end
        return
    end

    if ( !IsValid( self.m_Image ) ) then
        self.m_Image = vgui.Create( "DImage", self )
    end

    self.m_Image:SetImage( img )
    self.m_Image:SizeToContents()
    self:InvalidateLayout()

end
PANEL.SetIcon = PANEL.SetImage

function PANEL:UpdateColours( skin )
    if ( !self:IsEnabled() )					then return self:SetTextStyleColor( skin.Colours.Button.Disabled ) end
    if ( self:IsDown() || self.m_bSelected )	then return self:SetTextStyleColor( skin.Colours.Button.Down ) end
    if ( self.Hovered )							then return self:SetTextStyleColor( skin.Colours.Button.Hover ) end

    return self:SetTextStyleColor( skin.Colours.Button.Normal )
end

function PANEL:PerformLayout()
    if ( IsValid( self.m_Image ) ) then
        self.m_Image:SetPos( 4, ( self:GetTall() - self.m_Image:GetTall() ) * 0.5 )
        self:SetTextInset( self.m_Image:GetWide() + 16, 0 )
    end

    DLabel.PerformLayout( self )
end


function PANEL:SizeToContents()
    self:InvalidateLayout(true)
end

function PANEL:SetEnabled(bool)
    self:SetDisabled(!bool)
end

function PANEL:DoClick()
    -- override
end

function PANEL:DoRightClick()
    -- override
end

function PANEL:DoMiddleClick()
    -- override
end

function PANEL:DoM4Click()
    -- override
end
function PANEL:DoRightLeftClick()
    -- override
end

function PANEL:OnMousePressed( mousecode )
    -- override to check before release
end

function PANEL:OnMouseReleased( mousecode )
    if mousecode == MOUSE_LEFT then
        self:DoClick()
    elseif mousecode == MOUSE_RIGHT then
        self:DoRightClick()
    elseif mousecode == MOUSE_MIDDLE then
        self:DoMiddleClick()
    elseif mousecode == MOUSE_4 then
        self:DoM4Click()
    end
end

function PANEL:Think()
    if !self:GetDisabled() then
        self:OnThink()
    end
end

function PANEL:OnThink()
    -- override
end

function PANEL:Paint()
end

derma.DefineControl( "DBetterButton", "A Better Button", PANEL, "DLabel" )
