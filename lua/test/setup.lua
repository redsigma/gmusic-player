_G.__asd = describe

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
local dermaBase = {}
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
    if status == 0 then
        color_context_title = color.Play
        color_title = color.White
        color_bg = color.Play
        title = " Playing:" .. title
    -- auto play
    elseif status == 1 then
        color_context_title = color.APlay
        color_title = color.Black
        color_bg = color.APlay
        title = " Auto Playing:" .. title
    -- pause
    elseif status == 2 then
        color_context_title = color.Pause
        color_title = color.Black
        color_bg = color.Pause
        title = " Paused:" .. title
    -- loop
    elseif status == 3 then
        color_context_title = color.Loop
        color_title = color.Black
        color_bg = color.Loop
        title = " Looping:" .. title
    end

    local panel_title = dermaBase.main:GetTitle()
    local panel_color = dermaBase.main:GetTitleColor()
    local panel_bg = dermaBase.main.title_color
    local context_title = dermaBase.contextmedia.title:GetText()
    local context_color = dermaBase.contextmedia:GetTextColor()
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
    -1 stop, 0 play, 1 autoplay, 2 pause, 3 loop
--]]
local function line_highlight(state, args)
    local is_result_expected = true
    local status = args[1]
    local media = args[2]
    local curr_line = args[3]
    local prev_line = args[4]


    local color_bg = nil
    local color_revert = color.dark.text
    local color_text = color_revert

    -- play
    if status == 0 then
        color_bg = color.Play
        color_text = color.dark.text
    -- auto play
    elseif status == 1 then
        color_bg = color.APlay
        color_text = color.Black
    -- pause
    elseif status == 2 then
        color_bg = color.Pause
        color_text = color.Black
    -- loop
    elseif status == 3 then
        color_bg = color.Loop
        color_text = color.Black
    end

    local is_same_line = curr_line == prev_line
    if media.song_index ~= curr_line or media.song_prev_index ~= prev_line then
        is_result_expected = false
    end

    local selected_color = dermaBase.songlist:GetLine(curr_line):GetTextColor()
    local selected_bg = dermaBase.songlist:GetLine(curr_line):GetBGColor()

    -- check if line text and bg doesnt match
    if selected_color ~= color_text and
        (selected_bg.r ~= nil or selected_bg ~= color_bg) then
        is_result_expected = false
    end

    -- check if prev line still selected
    local select_prev_line = dermaBase.songlist:GetLine(prev_line)
    local prev_line_selected = false
    if select_prev_line ~= nil then
      local prev_line_color = select_prev_line:GetTextColor()
      local prev_line_bg = select_prev_line:GetBGColor()
      if prev_line_color ~= color_revert or prev_line_bg.r ~= nil then

          prev_line_selected = true
          if curr_line ~= prev_line then
            is_result_expected = false
          end
      end
    end

    if not is_result_expected then
        args[1] = media.song_index
        args[2] = curr_line
        args[3] = selected_color .. ""
        args[4] = color_text .. ""
        if (selected_bg.r == nil) then
            args[5] = "nil"
        else
            args[5] = selected_bg .. ""
        end
        args[6] = color_bg .. ""

        args[7] = media.song_prev_index
        args[8] = prev_line
        if curr_line ~= prev_line and prev_line_selected then
          args[9] = colors.red(prev_line_selected)
        else
          args[9] = colors.green(prev_line_selected)
        end

    end
    return is_result_expected
end
assert:register("assertion", "line_highlight", line_highlight,
    "msg_expect_highlight", "msg_expect_highlight")

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


local function set_derma(state, arguments)
    if not type(arguments[1]) == "table" then
        return false
    end
    dermaBase = arguments[1]
    return true
end
say:set("assertion.set_derma_message",
    "Expected %s to be a table with derma panels\n")
assert:register("assertion", "set_derma", set_derma,
    "assertion.set_derma_message", "assertion.set_derma_message")

-- Set busted funcs for shared unit tests
set_shared_interface(insulate, describe, it, assert)
