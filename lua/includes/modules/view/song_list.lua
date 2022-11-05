function class(super)
  local obj = {}
  obj.__index = obj
  setmetatable(obj, super)

  function obj.new(...)
      local instance = setmetatable({}, obj)
      if instance.ctor then
          instance:ctor(...)
      end
      return instance
  end

  return obj
end


require("delegate")
local view_song_list = class()


local function create_song_list()
  local songlist = vgui.Create("DBetterListView")
  songlist:AddColumn("Song")

  return songlist
end

local function attach_to_empty_parent(derma_panel)
  local panel = vgui.Create("DPanel")
  panel:SetPos(200,200)
  panel:SetBackgroundColor(Color(0,0,0))
  panel:SetSize(400, 400)

  derma_panel:SetParent(panel)
end


function view_song_list:ctor()
  self.viewmodel = include("includes/modules/viewmodel/song_list.lua")(self)


  self.derma = {}
  self.derma.songlist = create_song_list()
  -- attach_to_empty_parent(self.derma.songlist)

  self.viewmodel:populate_song_list()
  self:refresh_layout()

end

function view_song_list:show()
  self.viewmodel:show_interface()
end

function view_song_list:parent_to(panel)
  local ui_song_list = self.derma.songlist

  if not panel then return end

  ui_song_list:SetParent(panel)
  self:refresh_layout()
end

-------------------------------------------------------------------------------
function view_song_list:refresh_layout()
  local ui_song_list = self.derma.songlist

  local parent = ui_song_list:GetParent()
  if nil == parent then return end
  ui_song_list:RefreshLayout(parent:GetWide(), parent:GetTall())
end

return view_song_list.new()