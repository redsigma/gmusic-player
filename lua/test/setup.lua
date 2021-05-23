local colors = require 'term.colors'
local say = require("say")
say:set_namespace("en")

--[[
    Custom expected messages
--]]
say:set("msg_expect", "Expected " .. colors.green("%s") .. " but has "
    .. colors.red("'%s'") .."\n")
say:set("msg_expect_highlight", "Media has:\n - line %s, expected %s with color %s, expected %s\n - prev line %s, expected %s, is selected: %s\n")


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
    Expect panel title ui is playing. Checks text, color, and bg color
--]]
local function ui_is_playing(state, arguments)
    arguments[1] = " Playing: " .. arguments[1]
    local status_title = dermaBase.main:GetTitle()
    local context_title = dermaBase.contextmedia.title:GetText()
    local context_color = dermaBase.contextmedia:GetTextColor()
    if status_title ~= arguments[1] and context_title ~= arguments[1] and
        dermaBase.main:GetTitleColor() ~= color.White and
        dermaBase.main.title_color ~= color.Play and
        context_color ~= color.Play then
        table.insert(arguments, status_title)
        return false
    end
    return true
end
assert:register(
    "assertion", "ui_is_playing", ui_is_playing, "msg_expect", "msg_expect")

--[[
    Expect panel title ui is paused
--]]
local function ui_is_paused(state, arguments)
    arguments[1] = " Paused: " .. arguments[1]
    local status_title = dermaBase.main:GetTitle()
    local context_title = dermaBase.contextmedia.title:GetText()
    local context_color = dermaBase.contextmedia:GetTextColor()
    if status_title ~= arguments[1] and context_title ~= arguments[1] and
        dermaBase.main:GetTitleColor() ~= color.Black and
        dermaBase.main.title_color ~= color.Pause and
        context_color ~= color.Pause then
        table.insert(arguments, status_title)
        return false
    end
    return true
end
assert:register(
    "assertion", "ui_is_paused", ui_is_paused, "msg_expect", "msg_expect")

--[[
    Expect panel title ui is looped
--]]
local function ui_is_looped(state, arguments)
    arguments[1] = " Looping: " .. arguments[1]
    local status_title = dermaBase.main:GetTitle()
    local context_title = dermaBase.contextmedia.title:GetText()
    local context_color = dermaBase.contextmedia:GetTextColor()
    if status_title ~= arguments[1] and context_title ~= arguments[1] and
        dermaBase.main:GetTitleColor() ~= color.Black and
        dermaBase.main.title_color ~= color.Loop and
        context_color ~= color.Loop then
        table.insert(arguments, status_title)
        return false
    end
    return true
end
assert:register(
    "assertion", "ui_is_looped", ui_is_looped, "msg_expect", "msg_expect")

--[[
    Expect panel title ui is auto played
--]]
local function ui_is_autoplay(state, arguments)
    arguments[1] = " Auto Playing: " .. arguments[1]
    local status_title = dermaBase.main:GetTitle()
    local context_title = dermaBase.contextmedia.title:GetText()
    local context_color = dermaBase.contextmedia:GetTextColor()
    if status_title ~= arguments[1] and context_title ~= arguments[1] and
        dermaBase.main:GetTitleColor() ~= color.Black and
        dermaBase.main.title_color ~= color.APlay and
        context_color ~= color.APlay then
        table.insert(arguments, status_title)
        return false
    end
    return true
end
assert:register(
    "assertion", "ui_is_autoplay", ui_is_autoplay, "msg_expect", "msg_expect")

--[[
    Expect panel title ui is stopped
--]]
local function ui_is_stopped(state, arguments)
    local status_title = dermaBase.main:GetTitle()
    local context_title = dermaBase.contextmedia.title:GetText()
    local context_color = dermaBase.contextmedia:GetTextColor()
    if status_title ~= arguments[1] and context_title ~= arguments[1] and
        dermaBase.main:GetTitleColor() ~= color.White and
        dermaBase.main.title_color ~= color.Stop and
        context_color ~= color.Black then
        table.insert(arguments, status_title)
        return false
    end
    return true
end
assert:register(
    "assertion", "ui_is_stopped", ui_is_stopped, "msg_expect", "msg_expect")

--[[
    Check highlight of current and previous line when playing
--]]
local function line_highlight_play(state, arguments)
    local is_correct = true
    local media = arguments[1]
    local curr_line = arguments[2]
    local prev_line = arguments[3]
    local color_bg = color.Play
    local color_text = color_dark.text
    if media.song_index ~= curr_line or media.song_prev_index ~= prev_line then
        is_correct = false
    end

    local selected_color = dermaBase.songlist:GetLine(curr_line):GetTextColor()
    local selected_bg = dermaBase.songlist:GetLine(curr_line):GetBGColor()
    if selected_color.r ~= color_text.r or
        selected_color.g ~= color_text.g or
        selected_color.b ~= color_text.b or
        selected_bg.r ~= color_bg.r or selected_bg.g ~= color_bg.g or
        selected_bg.b ~= color_bg.b then
        is_correct = false
    end

    local select_prev_line = dermaBase.songlist:GetLine(prev_line)
    local line_selected = false
    if select_prev_line ~= nil then
        local prev_line_color = select_prev_line:GetTextColor()
        local prev_line_bg = select_prev_line:GetBGColor()
        if prev_line_color.r ~= color_dark.text.r or
            prev_line_color.g ~= color_dark.text.g or
            prev_line_color.b ~= color_dark.text.b or
            prev_line_bg.r ~= nil then

            line_selected = true
            is_correct = false
        end
    end
    if not is_correct then
        arguments[1] = media.song_index
        arguments[2] = curr_line
        arguments[3] = { selected_color.r, selected_color.g, selected_color.b }
        arguments[4] = color_dark.text.r .. " " .. color_dark.text.g .. " "
            .. color_dark.text.b

        arguments[5] = media.song_prev_index
        arguments[6] = prev_line
        arguments[7] = line_selected
    end
    return is_correct
end
assert:register("assertion", "line_highlight_play", line_highlight_play,
    "msg_expect_highlight", "msg_expect_highlight")

--[[
    Check highlight of current and previous line when paused
--]]
local function line_highlight_pause(state, arguments)
    local is_correct = true
    local media = arguments[1]
    local curr_line = arguments[2]
    local prev_line = arguments[3]
    local color_bg = color.Pause
    local color_text = color.Black
    if media.song_index ~= curr_line or media.song_prev_index ~= prev_line then
        is_correct = false
    end

    local selected_color = dermaBase.songlist:GetLine(curr_line):GetTextColor()
    local selected_bg = dermaBase.songlist:GetLine(curr_line):GetBGColor()
    if selected_color.r ~= color_text.r or
        selected_color.g ~= color_text.g or
        selected_color.b ~= color_text.b or
        selected_bg.r ~= color_bg.r or selected_bg.g ~= color_bg.g or
        selected_bg.b ~= color_bg.b then
        is_correct = false
    end

    local select_prev_line = dermaBase.songlist:GetLine(prev_line)
    local line_selected = false
    if select_prev_line ~= nil then
        local prev_line_color = select_prev_line:GetTextColor()
        local prev_line_bg = select_prev_line:GetBGColor()
        if prev_line_color.r ~= color_dark.text.r or
            prev_line_color.g ~= color_dark.text.g or
            prev_line_color.b ~= color_dark.text.b or
            prev_line_bg.r ~= nil then

            line_selected = true
            is_correct = false
        end
    end
    if not is_correct then
        arguments[1] = media.song_index
        arguments[2] = curr_line
        arguments[3] = { selected_color.r, selected_color.g, selected_color.b }
        arguments[4] = color_dark.text.r .. " " .. color_dark.text.g .. " "
            .. color_dark.text.b

        arguments[5] = media.song_prev_index
        arguments[6] = prev_line
        arguments[7] = line_selected
    end
    return is_correct
end
assert:register("assertion", "line_highlight_pause", line_highlight_pause,
    "msg_expect_highlight", "msg_expect_highlight")

--[[
    Check highlight of current and previous line when auto played
--]]
local function line_highlight_autoplay(state, arguments)
    local is_correct = true
    local media = arguments[1]
    local curr_line = arguments[2]
    local prev_line = arguments[3]
    local color_bg = color.APlay
    local color_text = color.Black
    if media.song_index ~= curr_line or media.song_prev_index ~= prev_line then
        is_correct = false
    end

    local selected_color = dermaBase.songlist:GetLine(curr_line):GetTextColor()
    local selected_bg = dermaBase.songlist:GetLine(curr_line):GetBGColor()
    if selected_color.r ~= color_text.r or
        selected_color.g ~= color_text.g or
        selected_color.b ~= color_text.b or
        selected_bg.r ~= color_bg.r or selected_bg.g ~= color_bg.g or
        selected_bg.b ~= color_bg.b then
        is_correct = false
    end

    local select_prev_line = dermaBase.songlist:GetLine(prev_line)
    local line_selected = false
    if select_prev_line ~= nil then
        local prev_line_color = select_prev_line:GetTextColor()
        local prev_line_bg = select_prev_line:GetBGColor()
        if prev_line_color.r ~= color_dark.text.r or
            prev_line_color.g ~= color_dark.text.g or
            prev_line_color.b ~= color_dark.text.b or
            prev_line_bg.r ~= nil then

            line_selected = true
            is_correct = false
        end
    end
    if not is_correct then
        arguments[1] = media.song_index
        arguments[2] = curr_line
        arguments[3] = { selected_color.r, selected_color.g, selected_color.b }
        arguments[4] = color_dark.text.r .. " " .. color_dark.text.g .. " "
            .. color_dark.text.b

        arguments[5] = media.song_prev_index
        arguments[6] = prev_line
        arguments[7] = line_selected
    end
    return is_correct
end
assert:register("assertion", "line_highlight_autoplay", line_highlight_autoplay,
    "msg_expect_highlight", "msg_expect_highlight")

--[[
    Check highlight of current and previous line when auto played
--]]
local function line_highlight_loop(state, arguments)
    local is_correct = true
    local media = arguments[1]
    local curr_line = arguments[2]
    local prev_line = arguments[3]
    local color_bg = color.Loop
    local color_text = color.Black
    if media.song_index ~= curr_line or media.song_prev_index ~= prev_line then
        is_correct = false
    end

    local selected_color = dermaBase.songlist:GetLine(curr_line):GetTextColor()
    local selected_bg = dermaBase.songlist:GetLine(curr_line):GetBGColor()
    if selected_color.r ~= color_text.r or
        selected_color.g ~= color_text.g or
        selected_color.b ~= color_text.b or
        selected_bg.r ~= color_bg.r or selected_bg.g ~= color_bg.g or
        selected_bg.b ~= color_bg.b then
        is_correct = false
    end

    local select_prev_line = dermaBase.songlist:GetLine(prev_line)
    local line_selected = false
    if select_prev_line ~= nil then
        local prev_line_color = select_prev_line:GetTextColor()
        local prev_line_bg = select_prev_line:GetBGColor()
        if prev_line_color.r ~= color_dark.text.r or
            prev_line_color.g ~= color_dark.text.g or
            prev_line_color.b ~= color_dark.text.b or
            prev_line_bg.r ~= nil then

            line_selected = true
            is_correct = false
        end
    end
    if not is_correct then
        arguments[1] = media.song_index
        arguments[2] = curr_line
        arguments[3] = { selected_color.r, selected_color.g, selected_color.b }
        arguments[4] = color_dark.text.r .. " " .. color_dark.text.g .. " "
            .. color_dark.text.b

        arguments[5] = media.song_prev_index
        arguments[6] = prev_line
        arguments[7] = line_selected
    end
    return is_correct
end
assert:register("assertion", "line_highlight_loop", line_highlight_loop,
    "msg_expect_highlight", "msg_expect_highlight")

--[[
    Check highlight of current and previous line when stopped
--]]
local function line_highlight_stop(state, arguments)
    local is_correct = true
    local media = arguments[1]
    local curr_line = arguments[2]
    local prev_line = arguments[3]
    local color_bg = color.APlay
    local color_text = color_dark.text
    if media.song_index ~= curr_line or media.song_prev_index ~= prev_line then
        is_correct = false
    end

    local selected_color = dermaBase.songlist:GetLine(curr_line):GetTextColor()
    local selected_bg = dermaBase.songlist:GetLine(curr_line):GetBGColor()
    if selected_color.r ~= color_text.r or
        selected_color.g ~= color_text.g or
        selected_color.b ~= color_text.b or
        selected_bg.r ~= nil then
        is_correct = false
    end

    local select_prev_line = dermaBase.songlist:GetLine(prev_line)
    local line_selected = false
    if select_prev_line ~= nil then
        local prev_line_color = select_prev_line:GetTextColor()
        local prev_line_bg = select_prev_line:GetBGColor()
        if prev_line_color.r ~= color_dark.text.r or
            prev_line_color.g ~= color_dark.text.g or
            prev_line_color.b ~= color_dark.text.b or
            prev_line_bg.r ~= nil then

            line_selected = true
            is_correct = false
        end
    end
    if not is_correct then
        arguments[1] = media.song_index
        arguments[2] = curr_line
        arguments[3] = { selected_color.r, selected_color.g, selected_color.b }
        arguments[4] = color_dark.text.r .. " " .. color_dark.text.g .. " "
            .. color_dark.text.b

        arguments[5] = media.song_prev_index
        arguments[6] = prev_line
        arguments[7] = line_selected
    end
    return is_correct
end
assert:register("assertion", "line_highlight_stop", line_highlight_stop,
    "msg_expect_highlight", "msg_expect_highlight")


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
