local function create_timer(timer_name, delay, callback)
  if timer.Exists(timer_name) then return end
  timer.Create(timer_name, delay, 0, callback)
end

local function pause_timer(timer_name)
  if not timer.Exists(timer_name) then return end
  timer.Pause(timer_name)
end

local function init_timers(ui_gmusic)
  if not ui_gmusic then return end

  create_timer("gmpl_seek_daemon", 0.05, function()
    ui_gmusic.mediaplayer:monitor_channel_seek()
  end)

  -- timer.Pause("gmpl_seek_daemon")
  create_timer("gmpl_realtime_seek", 0.07, function()
    ui_gmusic.mediaplayer:realtime_seek()
  end)

  pause_timer("gmpl_realtime_seek")

  create_timer("gmpl_sv_seek_end", 0.06, function()
    ui_gmusic:MonitorSeekEnd(true) -- server
  end)

  create_timer("gmpl_cl_seek_end", 0.2, function()
    -- needs to be slower to prevent issues
    if ui_gmusic.main:IsServerMode() then return end
    ui_gmusic:MonitorSeekEnd(false) -- client
  end)
end

local function configure_cvars(ui_gmusic)
--[[
  AddChangeCallback - the scope of the function is different and objects must be
    passed from outside, in order to have the same address
]]
  if not ui_gmusic then return end

  local ui_gmusic_lowlevel = ui_gmusic.interface

  cvars.AddChangeCallback("gmpl_vol", function(convar, oldValue, newValue)
    if (isnumber(util.StringToType(newValue, "Float"))) then
      ui_gmusic_lowlevel.set_volume(newValue)
    elseif (isnumber(util.StringToType(oldValue, "Float"))) then
      ui_gmusic_lowlevel.set_volume(oldValue)
      MsgC(Color(255, 90, 90),
        "Only 0 - 100 value is allowed. Keeping value " .. oldValue .. "\n")
    end
  end)
end

local function init_derma()
  local ui_gmusic = include("includes/modules/meth_base.lua")(
    g_ContextMenu, ScrW() / 5)

  if not ui_gmusic then return {} end

  ui_gmusic.contextbutton:AfterChange(ui_gmusic.contextbutton:GetCvarInt())

  return ui_gmusic
end

local function load_audio_from_disk(ui_gmusic)
  if not ui_gmusic then return end

  local loaded = ui_gmusic.song_data:load_from_disk()

  if loaded then
    ui_gmusic.song_data:populate_song_page()
  end
end


--[[
  Singleton class used for creating everything
]]
local function create_gmusic(super)
  local obj = {}
  obj.__index = obj
  setmetatable(obj, super)

  obj._derma = {}
  obj._interface = {}
  obj._mediaplayer = {}
  obj._ingame_viewport = {}

  --[[
    Private
  ]]
  local function setup()

    local ui_gmusic = init_derma()
    while not ui_gmusic.main and isfunction(ui_gmusic.main.IsVisible) do
      MsgC(Color(144, 219, 232), "[gMusic Player]", Color(255, 0, 0), " Failed to initialize - retrying\n")
      ui_gmusic = init_derma()
    end

    local ingame_screen = ui_gmusic.main:GetParent()

    ui_gmusic.mediaplayer:net_init()
    load_audio_from_disk(ui_gmusic)

    ui_gmusic.create()
    ui_gmusic.painter:update_colors()

    init_timers(ui_gmusic)

    configure_cvars(ui_gmusic)

    obj._derma = ui_gmusic
    obj._interface = ui_gmusic.interface
    obj._mediaplayer = ui_gmusic.mediaplayer
    obj._ingame_viewport = ingame_screen

  end

  --[[
    Public
  ]]
  function obj.derma(...)
    return obj.get()._derma
  end

  function obj.interface(...)
    return obj.get()._interface
  end

  function obj.media(...)
     return obj.get()._mediaplayer
  end

  function obj.parent(...)
    return obj.get()._ingame_viewport
  end

  function obj.get(...)
    if _G.gmusic and _G.gmusic.obj then
      return _G.gmusic.obj._instance
    end
    _G.gmusic = {}

    print("Preparing GMusic Player...")
    setup()

    local _instance = setmetatable({}, obj)

    _G.gmusic.obj = {}
    _G.gmusic.obj._instance = _instance

    return _instance
  end

  return obj
end

return create_gmusic()
