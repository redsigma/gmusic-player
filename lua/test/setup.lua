local colors = require 'term.colors'
local say = require("say")
say:set_namespace("en")

--[[
    Custom expected messages
--]]
say:set("msg_expect", "Media has:\n - title " .. colors.red("%s") ..
" expected " .. colors.green("%s") .. "\n - text color " .. colors.red("'%s'") .. " expected " .. colors.green("'%s'") .. "\n - bg color " .. colors.red("'%s'") .. " expected " .. colors.green("'%s'") .. "\n")

say:set("msg_expect_highlight", "Media has:" ..
"\n - line " .. colors.red('%s') .. " expected " .. colors.green('%s') ..
"\n - line text color " .. colors.red('%s') .. " expected " .. colors.green('%s') ..
"\n - line bg color " .. colors.red("'%s'") .. " expected " .. colors.green("'%s'") ..
"\n - prev line " .. colors.red("'%s'") .. " expected " .. colors.green("'%s'") .. ", is selected: '%s'\n")

say:set("msg_expect_theme", "Media theme colors:" ..
"\n - bg " .. colors.red("%s") .. " expected " .. colors.green("%s") ..
"\n - bg hover " .. colors.red("'%s'") .. " expected " .. colors.green("'%s'") ..
"\n - text " .. colors.red("'%s'") .. " expected " .. colors.green("'%s'") ..
"\n - slider " .. colors.red("'%s'") .. " expected " .. colors.green("'%s'") ..
"\n - bg list " .. colors.red("'%s'") .. " expected " .. colors.green("'%s'"))
--------------------------------------------------------------------------------
local function has_property(state, arguments)
    local has_key = false

    if not type(arguments[1]) == "table" or #arguments ~= 2 then
        return false
    end

    for key, value in pairs(arguments[1]) do
        if key == arguments[2] then
            has_key = true
        end
    end

    return has_key
end
say:set("assertion.has_property.positive", "Expected %s \nto have property: %s")
say:set("assertion.has_property.negative", "Expected %s \nto not have property: %s")
assert:register("assertion", "has_property", has_property,
    "assertion.has_property.positive", "assertion.has_property.negative")
--------------------------------------------------------------------------------
--[[
    Check text and bg of panel title and context button
    -1 stop, 0 play, 1 autoplay, 2 pause, 3 loop
--]]
local function ui_top_bar_color(state, args)
    local status = args[1]
    local title = " " .. args[2]

    local color_context_title = color.Black
    local color_title = color.White
    local color_bg = color.Stop

    -- play
    if status == 1 then
        color_context_title = color.Play
        color_title = color.White
        color_bg = color.Play
        title = " Playing:" .. title
    -- auto play
    elseif status == 2 then
        color_context_title = color.APlay
        color_title = color.Black
        color_bg = color.APlay
        title = " Auto Playing:" .. title
    -- pause
    elseif status == 3 then
        color_context_title = color.Pause
        color_title = color.Black
        color_bg = color.Pause
        title = " Paused:" .. title
    -- loop
    elseif status == 4 then
        color_context_title = color.Loop
        color_title = color.Black
        color_bg = color.Loop
        title = " Looping:" .. title
    -- pause live seek
    elseif status == 5 then
      color_context_title = color.APause
      color_title = color.Black
      color_bg = color.APause
      title = " Muted:" .. title
    end

    local panel_title = _dermaBase.main:GetTitle()
    local panel_color = _dermaBase.main:GetTitleColor()
    local panel_bg = _dermaBase.main.title_color
    local context_title = _dermaBase.contextmedia.title:GetText()
    local context_color = _dermaBase.contextmedia:GetTextColor()
    if panel_title ~= title or context_title ~= args[2] or
        panel_color ~= color_title or panel_bg ~= color_bg or
        context_color ~= color_context_title then
        args[1] = panel_title
        args[2] = title
        args[3] = panel_color.r .. " " .. panel_color.g .. " " .. panel_color.b
        args[4] = color_title.r .. " " .. color_title.g .. " " .. color_title.b
        args[5] = panel_bg.r .. " " .. panel_bg.g .. " " .. panel_bg.b
        args[6] = color_bg.r .. " " .. color_bg.g .. " " .. color_bg.b
        return false
    end
    return true
end
assert:register("assertion", "ui_top_bar_color", ui_top_bar_color,
  "msg_expect", "msg_expect")


--[[
    Check highlight of current and previous line
    -1 stop, 0 play, 1 autoplay, 2 pause, 3 loop, 4 pause live
--]]
local function line_highlight(status, curr_line, prev_line, channel)
    local is_result_expected = true

    local no_color = Color(-1, -1, -1)
    local color_bg = color.Stop
    local color_revert = color.dark.text
    local color_text = color_revert

    local curr_color_bg = no_color
    local curr_color_text = color_revert

    -- no highlight
    if status == -1 then
      color_bg = no_color
      color_text = color_revert
    -- stop
    elseif status == 0 then
      color_bg = color.Stop
      color_text = color.dark.text
    -- play
    elseif status == 1 then
      color_bg = color.Play
      color_text = color.dark.text
    -- auto play
    elseif status == 2 then
      color_bg = color.APlay
      color_text = color.Black
    -- pause
    elseif status == 3 then
      color_bg = color.Pause
      color_text = color.Black
    -- loop
    elseif status == 4 then
      color_bg = color.Loop
      color_text = color.Black
    -- pause live seek
    elseif status == 5 then
      color_bg = color.APause
      color_text = color.Black
    end

    if channel == nil then
      channel = _dermaBase.mediaplayer:get_channel()
    end

    local is_current_line_different = channel.song_index ~= curr_line
    local is_previous_line_different =  channel.song_prev_index ~= prev_line
    if is_current_line_different or is_previous_line_different then
      is_result_expected = false
    end

    local select_curr_line = _dermaBase.songlist:GetLine(curr_line)
    if select_curr_line ~= nil then
      curr_color_text = select_curr_line:GetTextColor()
      curr_color_bg = select_curr_line:GetBGColor()

      -- check if line text or bg doesnt match the expected
      if curr_color_text ~= color_text or
          (curr_color_bg.r ~= nil and curr_color_bg ~= color_bg) then
          is_result_expected = false
      end
    end

    -- check if prev line still selected
    local prev_line_selected = false
    local select_prev_line = _dermaBase.songlist:GetLine(prev_line)
    if select_prev_line ~= nil then
      local prev_color_text = select_prev_line:GetTextColor()
      local prev_color_bg = select_prev_line:GetBGColor()
      if prev_color_text ~= color_revert or prev_color_bg.r ~= nil then

          prev_line_selected = true
          if curr_line ~= prev_line then
            is_result_expected = false
          end
      end
    end

    if not is_result_expected then
        args[1] = channel.song_index
        args[2] = curr_line
        args[3] = curr_color_text .. ""
        args[4] = color_text .. ""
        if (curr_color_bg.r == nil) then
            args[5] = "nil"
        else
            args[5] = curr_color_bg .. ""
        end
        args[6] = color_bg .. ""

        args[7] = channel.song_prev_index
        args[8] = prev_line
        if curr_line ~= prev_line and prev_line_selected then
          args[9] = colors.red(prev_line_selected)
        else
          args[9] = colors.green(prev_line_selected)
        end

    end
    return is_result_expected
end

local function line_highlight_no_color(_, args)
  local song_line = args[1]
  local previous_line = args[2]
  local channel = args[3]

  return line_highlight(-1, song_line, previous_line, channel)
end
local function line_highlight_stop(_, args)
  local song_line = args[1]
  local previous_line = args[2]
  local channel = args[3]

  return line_highlight(0, song_line, previous_line, channel)
end
local function line_highlight_play(_, args)
  local song_line = args[1]
  local previous_line = args[2]
  local channel = args[3]

  return line_highlight(1, song_line, previous_line, channel)
end
local function line_highlight_autoplay(_, args)
  local song_line = args[1]
  local previous_line = args[2]
  local channel = args[3]

  return line_highlight(2, song_line, previous_line, channel)
end
local function line_highlight_pause(_, args)
  local song_line = args[1]
  local previous_line = args[2]
  local channel = args[3]

  return line_highlight(3, song_line, previous_line, channel)
end
local function line_highlight_loop(_, args)
  local song_line = args[1]
  local previous_line = args[2]
  local channel = args[3]

  return line_highlight(4, song_line, previous_line, channel)
end
local function line_highlight_autoplay_paused(_, args)
  local song_line = args[1]
  local previous_line = args[2]
  local channel = args[3]

  return line_highlight(5, song_line, previous_line, channel)
end

assert:register("assertion", "line_highlight_no_color", line_highlight_no_color,
  "msg_expect_highlight", "msg_expect_highlight")
assert:register("assertion", "line_highlight_stop", line_highlight_stop,
"msg_expect_highlight", "msg_expect_highlight")
assert:register("assertion", "line_highlight_play", line_highlight_play,
"msg_expect_highlight", "msg_expect_highlight")
assert:register("assertion", "line_highlight_autoplay", line_highlight_autoplay,
"msg_expect_highlight", "msg_expect_highlight")
assert:register("assertion", "line_highlight_pause", line_highlight_pause,
"msg_expect_highlight", "msg_expect_highlight")
assert:register("assertion", "line_highlight_loop", line_highlight_loop,
"msg_expect_highlight", "msg_expect_highlight")
assert:register("assertion", "line_highlight_autoplay_paused",
  line_highlight_autoplay_paused, "msg_expect_highlight", "msg_expect_highlight")

--[[
    Check theme colors
    -1 light, 0 dark
--]]
local function ui_theme(state, args)
    local status = args[1]
    local painter = args[2]

    local colors = color.light
    if status == 0 then
        colors = color.dark
    end

    if painter.colors.bg ~= colors.bg or
        painter.colors.bghover ~= colors.bghover or
        painter.colors.text ~= colors.text or
        painter.colors.slider ~= colors.slider or
        painter.colors.bglist ~= colors.bglist then
        args[1] = painter.colors.bg .. ""
        args[2] = colors.bg .. ""
        args[3] = painter.colors.bghover .. ""
        args[4] = colors.bghover .. ""

        args[5] = painter.colors.text .. ""
        args[6] = colors.text .. ""
        args[7] = painter.colors.slider .. ""
        args[8] = colors.slider .. ""

        args[9] = painter.colors.bglist .. ""
        args[10] = colors.bglist .. ""
        return false
    end
    return true
end
assert:register(
  "assertion", "ui_theme", ui_theme, "msg_expect_theme", "msg_expect_theme")


-- local function set_derma(state, arguments)
--     if not type(arguments[1]) == "table" then
--         return false
--     end
--     _dermaBase = arguments[1]
--     return true
-- end
say:set("assertion.set_derma_message",
  "Expected %s to be a table with derma panels\n")
assert:register("assertion", "set_derma", _G.set_derma,
  "assertion.set_derma_message", "assertion.set_derma_message")

-- Set busted funcs for shared unit tests
init_unit_test_func(insulate, describe, it, assert)
setup_sh_interface(insulate, describe, it, assert)