hl.config({
	binds = {},
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(
	mainMod .. " + M",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(notes))
-- Windows-style hold-to-cycle Alt+Tab (quickshell window switcher, see
-- ~/.config/quickshell/switcher/). Entry bind both advances the switcher
-- (which auto-opens on its first call, landing on the 2nd-most-recent
-- window) and drops into the "alttab" submap for the rest of the hold;
-- submap-local binds shadow the global ones below (eg. ALT+SPACE normally
-- opens the launcher) only while the submap is active.
--
-- Confirm-on-Alt-release is done by polling hl.is_key_down("ALT_L") on a
-- timer rather than a `release = true` bindrt-style bind: bindrt inside a
-- submap only fired on a *second* Alt press (the classic ALT/ALT_L release
-- bind from the wiki's own alt-tab example didn't fire on the first hold
-- either, with or without the `transparent` flag) - this matches known
-- upstream "release binds don't fire on the first press in a submap" reports
-- (eg. hyprwm/Hyprland#3058), so it's sidestepped entirely here.
local alttabAltTimer = nil

local function alttabConfirm()
	hl.exec_cmd("qs ipc call switcher confirm")
	hl.dispatch(hl.dsp.submap("reset"))
	if alttabAltTimer then
		alttabAltTimer:set_enabled(false)
	end
end

local function alttabCancel()
	hl.exec_cmd("qs ipc call switcher cancel")
	hl.dispatch(hl.dsp.submap("reset"))
	if alttabAltTimer then
		alttabAltTimer:set_enabled(false)
	end
end

local function alttabPollAlt()
	-- is_key_down's string form is a strict XKB keysym lookup (case
	-- sensitive - "Alt_L", not "ALT_L" like bind key names accept)
	if not hl.is_key_down("Alt_L") then
		alttabConfirm()
	end
end

hl.define_submap("alttab", function()
	hl.bind("ALT + TAB", function()
		hl.exec_cmd("qs ipc call switcher next")
	end)
	hl.bind("ALT + SHIFT + TAB", function()
		hl.exec_cmd("qs ipc call switcher prev")
	end)
	hl.bind("ALT + RETURN", alttabConfirm)
	hl.bind("ALT + SPACE", alttabConfirm)
	hl.bind("ESCAPE", alttabCancel)
end)

hl.bind("ALT + TAB", function()
	hl.exec_cmd("qs ipc call switcher next")
	hl.dispatch(hl.dsp.submap("alttab"))
	if not alttabAltTimer then
		alttabAltTimer = hl.timer(alttabPollAlt, { timeout = 50, type = "repeat" })
	else
		alttabAltTimer:set_enabled(true)
	end
end)
-- hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind("ALT + BACKSPACE", hl.dsp.exec_cmd("~/.local/bin/fuzzel-run.sh"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/waybar/scripts/launch.sh"))
hl.bind("F11", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + HOME", hl.dsp.exec_cmd("wayscriber --active"))

hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("CTRL + PRINT", hl.dsp.exec_cmd("hyprshot -m active -m output"))

hl.bind(mainMod .. " + COMMA", hl.dsp.exec_cmd("~/.local/bin/change_layout_dwindle.sh"))
hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd("~/.local/bin/change_layout_scrolling.sh"))
hl.bind(mainMod .. " + MINUS", hl.dsp.exec_cmd("~/.local/bin/change_layout_monocle.sh"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + SSHARP", hl.dsp.focus({ workspace = 11 }))
hl.bind(mainMod .. " + DEAD_ACUTE", hl.dsp.focus({ workspace = 12 }))

hl.bind(mainMod .. " + SHIFT + UP", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + SHIFT + DOWN", hl.dsp.focus({ workspace = "-1" }))

hl.bind(mainMod .. " + SHIFT + LEFT", hl.dsp.exec_cmd("~/.local/bin/hyprland_layout_check_l.sh"))
hl.bind(mainMod .. " + SHIFT + RIGHT", hl.dsp.exec_cmd("~/.local/bin/hyprland_layout_check_r.sh"))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.layout("cycleprev"))
hl.bind(mainMod .. " + mouse_up", hl.dsp.layout("cyclenext"))

hl.bind(mainMod .. " + P", hl.dsp.layout("promote"))
hl.bind(mainMod .. " + code:47", hl.dsp.layout("fit active"))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("XF86Tools", hl.dsp.exec_cmd("/home/christopher/.local/bin/exit.sh 1"))

-- old single-window scratchpad, superseded by modules/stash.lua -- 2026-08-27
-- hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("/home/christopher/.local/bin/hyprland_minimize.sh"))

local stash = require("modules.stash")

hl.bind(mainMod .. " + S", function()
	stash.toggle()
end)
hl.bind(mainMod .. " + SHIFT + S", function()
	stash.push()
end)
hl.bind(mainMod .. " + ALT + S", function()
	stash.shift()
end) -- oldest first (FIFO)

hl.bind("SUPER + code:127", hl.dsp.exec_cmd("hyprpicker"), { locked = true })

local MAX_ZOOM = 3
local MIN_ZOOM = 1
local ZOOM_TOGGLE_FACTOR = 1.5

---@param offset number
---@return nil
local function zoom(offset)
	local current = hl.get_config("cursor.zoom_factor")
	if offset ~= nil then
		current = current + offset
	elseif current ~= MIN_ZOOM then
		current = MIN_ZOOM
	else
		current = ZOOM_TOGGLE_FACTOR
	end
	current = math.max(MIN_ZOOM, math.min(MAX_ZOOM, current))
	hl.config({ cursor = { zoom_factor = current } })
end

hl.bind("SUPER + Z", zoom)
hl.bind("SUPER + KP_ADD", function()
	zoom(0.5)
end)
hl.bind("SUPER + KP_SUBTRACT", function()
	zoom(-0.5)
end)
