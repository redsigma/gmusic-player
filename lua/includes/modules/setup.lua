local top_context_bar = {}
hook.Add("PopulateMenuBar", "getContext", function(menubar)
  top_context_bar = menubar
end)

local function init_derma()
  local ui_gmusic = include("includes/modules/meth_base.lua")(top_context_bar, ScrW() / 5)
  hook.Remove("PopulateMenuBar", "getContext")

  if not ui_gmusic then return {} end

  -- prevents conflcits from other addons that are using the ScreenClicker
  ui_gmusic.main:MoveToFront()

  return ui_gmusic
end


local function init_mediaplayer(derma_gmusic)
  if not derma_gmusic then return end

  require("musicplayerclass")
  local mediaplayer = Media(derma_gmusic)

  mediaplayer:readFileSongs()
  mediaplayer:create()



  -- must do this else the freking half invisible window appears
  -- derma_gmusic.main:SetParent(g_ContextMenu)


  return mediaplayer
end

local function paint_mediaplayer_derma(derma_gmusic)
  if not derma_gmusic then return end

  local all_derma_skins = derma.GetSkinTable()
  local ObjPaint = include("includes/modules/meth_paint.lua")(all_derma_skins)
  ObjPaint.paintButton(derma_gmusic.buttonrefresh)
  ObjPaint.paintButton(derma_gmusic.buttonstop)
  ObjPaint.paintButton(derma_gmusic.buttonpause)
  ObjPaint.paintButton(derma_gmusic.buttonplay)
  ObjPaint.paintSlider(derma_gmusic.sliderseek)
  ObjPaint.paintSlider(derma_gmusic.slidervol)
  ObjPaint.paintBase(derma_gmusic.main)
  ObjPaint.setDisabled(derma_gmusic.musicsheet)
  ObjPaint.paintList(derma_gmusic.songlist)
  ObjPaint.paintDoubleList(derma_gmusic.foldersearch)
  ObjPaint.paintOptions(derma_gmusic.settingPage)
  ObjPaint.paintText(derma_gmusic.contextmedia)

  derma_gmusic.musicsheet.Navigation.Paint = function(panel, w, h)
    surface.SetDrawColor(Color(150, 150, 150))
    surface.DrawRect(0, 0, w, h)
  end

  for k, v in pairs(derma_gmusic.musicsheet.Items) do
    if v.Button then
      v.Button:SetTextColor(Color(0, 0, 0))
      v.Button:DockMargin(0, 0, 0, 1)
    end

    v.Button.Paint = function(panel, w, h)
      surface.SetDrawColor(Color(255, 255, 255))
      surface.DrawRect(0, 0, w, h)
    end
  end

  ObjPaint.setBGHover(derma_gmusic.buttonrefresh)
  ObjPaint.setBGHover(derma_gmusic.buttonstop)
  ObjPaint.setBGHover(derma_gmusic.buttonpause)
  ObjPaint.setBGHover(derma_gmusic.buttonplay)

  derma_gmusic.theme_color = ObjPaint.getColors()

end

--[[
  Singleton class used for creating everything
]]
local function CreateGMusic(super)
  local obj = {}
  obj.__index = obj
  setmetatable(obj, super)

  obj._derma = {}
  obj._mediaplayer = {}
  obj._ingame_viewport = {}

  local function setup()

    local ui_gmusic = init_derma()
    while not ui_gmusic.main and isfunction(ui_gmusic.main.IsVisible) do
      MsgC(Color(144, 219, 232), "[gMusic Player]", Color(255, 0, 0), " Failed to initialize - retrying\n")
      ui_gmusic =  init_derma()
    end

    local ingame_screen = ui_gmusic.main:GetParent()

    local mediaplayer = init_mediaplayer(ui_gmusic)
    paint_mediaplayer_derma(ui_gmusic)

    obj._derma = ui_gmusic
    obj._mediaplayer = mediaplayer
    obj._ingame_viewport = ingame_screen
  end

  function obj.media(...)
     return obj.get()._mediaplayer
  end

  function obj.derma(...)
    return obj.get()._derma
  end

  function obj.parent(...)
    return obj.get()._ingame_viewport
  end

  function obj.get(...)
      if obj._instance then
          return obj._instance
      end

      setup()

      local instance = setmetatable({}, obj)
      if instance.ctor then
          instance:ctor(...)
      end

      obj._instance = instance
      return obj._instance
  end

  return obj
end

return CreateGMusic()