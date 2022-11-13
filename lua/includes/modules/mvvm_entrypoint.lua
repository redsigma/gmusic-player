
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

local MEDIATOR_MODEL_USER_INTERFACE = class()

function MEDIATOR_MODEL_USER_INTERFACE:ctor()
  --[[
    MODEL SCOPE:
      - contains the user interface data and you can edit them
        - for each edit of the data, a DELEGATE must be broadcasted
          - the viewmodel subcribes to this delegate

      - NOTES
        - complex validation MUST not take place here, but in VIEWMODEL,
          - simple validation is ok (such as nil checks), but try to set the data directly
          - the `MODEL` represents the behaviour and `VIEWMODEL` is the connections between VIEW and MODEL
            - these connections are represented by delegates called from the `MODEL` and received by the `VIEWMODEL` which then updates the `VIEW`

      - NOTES debate
        - according to this, you are supposed to do validation in the `MODEL` and `VIEWMODEL` handles ONLY the communication/updates between `VIEW` and `MODEL` , afterall you can have multiple `MODELS` each with its own SCOPE of data
          - https://stackoverflow.com/a/14236737

  ]]

  self.user_interface = include("includes/modules/meth_base_wip_mvvm.lua")(
    g_ContextMenu, ScrW() / 5)

  self.user_interface.create()

  self.user_interface.buttonstop.DoClick = function()
    print("MODEL: Pressed STOP")
    -- BAD - read the `info_NOTES.txt` for clarification on where to move the user interface
  end
end

-- =====-- =====-- =====-- =====-- =====-- =====-- =====-- =====-- =====--
local MEDIATOR_MODEL_MEDIAPLAYER = class()
function MEDIATOR_MODEL_MEDIAPLAYER:ctor()
  --[[
    MODEL SCOPE:
      - contains the mediaplayer data such as current song, seek value,

      - NOTES
        - SAME AS the MODEL from `MEDIATOR_MODEL_USER_INTERFACE`:
          - you must do only simple validation
          - you must broadcast delegates for each change, so the `VIEWMODEL` can react to those changes
  ]]
end
-- =====-- =====-- =====-- =====-- =====-- =====-- =====-- =====-- =====--

local MEDIATOR_VIEWMODEL = class()

function MEDIATOR_VIEWMODEL:ctor(view)
  --[[
    VIEWMODEL SCOPE:
      - takes care of filtering, sorting data, validation of data, so the MODEL contains valid data
      - according to the RULES in MVVM you MUST HAVE only 1 viewmodel but you can have multiple `MODEL`s

      - handles advanced validation for incoming data


  ]]

  self.model_user_interface = MEDIATOR_MODEL_USER_INTERFACE.new()
  self.model_mediaplayer = MEDIATOR_MODEL_MEDIAPLAYER.new()
  self.view = view

  self.model_song = include("includes/modules/model/song.lua")


  -- callbacks
  self.callback_update_song = Delegate:new_one_param()
  self.callback_get_song_name = Delegate:new()
  self.callback_interface_update_song = Delegate:new()
  --

  self:setup_bindings_of_viewmodel()
  self:setup_bindings_with_viewmodel()

  self.click_button_stop = Delegate:new()

end

function MEDIATOR_VIEWMODEL:setup_bindings_of_viewmodel()

  -- viewmodel to model

  self.callback_update_song:add(function(self, song_name)
    self.model_song:set_song(song_name)

    local song_title = song_name .. "preprocessed"
    self.model_song:set_song_title(song_title)
  end)


  self.callback_get_song_name:add(function()
   return self.model_song:get_song_title()
  end)


  -- viewmodel to view
  self.callback_interface_update_song:add(function()
    local song_title = self.model_song:get_song_title()
    self.view:update_top_title(song_title)
  end)

end

function MEDIATOR_VIEWMODEL:setup_bindings_with_viewmodel()
  -- model to viewmodel

  self.model_song.delegate_on_set_song:add(function()
    local song_name = self.model_song:get_song_path()
    self:callback_update_song(song_name)
  end)

  -- view to viewmodel
  self.view.get_song_title:add(self.callback_get_song_name)
end


function MEDIATOR_VIEWMODEL:show_user_interface()
  -- TODO ok this is overkill to add it in the VIEWMODEL
  print("VIEWMODEL: So you want to show the interface")
  self.model_user_interface.user_interface.interface:show()
end

function MEDIATOR_VIEWMODEL:on_click_button_stop()
  print("VIEWMODEL: So you want press button stop")
  self.model_user_interface.user_interface.buttonstop:DoClick()
end

-- =====-- =====-- =====-- =====-- =====-- =====-- =====-- =====-- =====--


local MEDIATOR_VIEW = class()

function MEDIATOR_VIEW:ctor()
  --[[
    VIEW SCOPE:
      - it has its own events such as DoClick, DoRightClick and maps them to the VIEWMODEL
      - it takes data from the `VIEWMODEL`, it does not set it directly

  ]]

  self.get_song_title = Delegate:new()

  self.viewmodel = MEDIATOR_VIEWMODEL.new(self)





end

function MEDIATOR_VIEW:show_interface()

  print("VIEW: User want to show interface")
  self.viewmodel:show_user_interface()
end

function MEDIATOR_VIEW:click_button_stop()
  print("VIEW: User want to click button stop")
  self.viewmodel:click_button_stop() -- actually viewmodel here should be an interface
end

function MEDIATOR_VIEW:update_song(new_song)
  self.viewmodel:callback_update_song(new_song)
end

----------

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
  local ui_gmusic = include("includes/modules/meth_base_wip_mvvm.lua")(
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
  obj._main = {}

  --[[
    Private
  ]]
  local function setup()

    local ui_gmusic = init_derma()
    while not ui_gmusic.main and isfunction(ui_gmusic.main.IsVisible) do
      MsgC(Color(144, 219, 232), "[gMusic Player]", Color(255, 0, 0), " Failed to initialize - retrying\n")
      ui_gmusic = init_derma()
    end

    -- local ingame_screen = ui_gmusic.main:GetParent()

    -- ui_gmusic.mediaplayer:net_init()
    -- load_audio_from_disk(ui_gmusic)

    ui_gmusic.create()
    -- ui_gmusic.painter:update_colors()

    -- init_timers(ui_gmusic)

    -- configure_cvars(ui_gmusic)

    obj._interface = ui_gmusic.interface


  end

  --[[
    Public
  ]]

  function obj.interface(...)
    return obj.get()._interface
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

  --- TESTING for MVVM

  function obj.show_user_interface()
    -- setup()

    local view = MEDIATOR_VIEW.new()

    local view_main_frame = include("includes/modules/view/main_frame.lua")

    -- local view_song_list = include("includes/modules/view/song_list.lua")
    -- if not view_song_list then return end

    view_main_frame:show()

    -- view_song_list:parent_to(view_main_frame:get_panel())
    -- view_song_list:show()


    -- view:setup_song_list()

    -- view:show_interface()
    -- view:click_button_stop()

    -- view:update_song("new_song_yee")

    -- local view = obj.interface()
    -- local live_host = net.ReadType()
    -- gmusic_ui_lowlevel.set_song_host(live_host)
    -- gmusic_ui.InvalidateUI()
    -- view.show()
  end

  return obj
end

return create_gmusic()
