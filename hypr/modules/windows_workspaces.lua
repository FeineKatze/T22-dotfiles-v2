--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

hl.workspace_rule({ workspace = "1", monitor = "DP-1", persistent = true, layout = "scrolling" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", persistent = true, layout = "monocle" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-1", persistent = true, layout = "monocle" })
hl.workspace_rule({ workspace = "5", monitor = "DP-1", persistent = true, layout = "scrolling" })

hl.workspace_rule({ workspace = "6", monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "10", monitor = "DP-2", persistent = true })

hl.workspace_rule({ workspace = "11", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "12", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "13", monitor = "HDMI-A-1", persistent = true })

hl.window_rule({
	name = "Discord",
	match = {
		title = "(.*)(Discord)(.*)",
	},
	workspace = "11",
})
hl.window_rule({
	name = "Floorp",
	match = {
		title = "(.*)(Floorp)(.*)",
	},
	workspace = "6",
})
hl.window_rule({
	name = "VLC",
	match = {
		title = "(.*)(VLC)(.*)",
	},
	workspace = "7",
})
hl.window_rule({
	name = "StreamLink",
	match = {
		title = "(.*)(StreamLink Twitch GUI)(.*)",
	},
	workspace = "8",
})
hl.window_rule({
	name = "Minecraft",
	match = {
		title = "(.*)(Minecraft)(.*)",
	},
	workspace = "2",
})
hl.window_rule({
	name = "Prism",
	match = {
		title = "(.*)(Prism Launcher)(.*)",
	},
	workspace = "1",
})
hl.window_rule({
	name = "Steam",
	match = {
		title = "(.*)(Steam)(.*)",
	},
	workspace = "3",
	tile = true,
})

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	name = "PiP",
	match = {
		title = "^(Picture-in-Picture)",
		class = "^(floorp)$",
	},
	float = true,
	pin = true,
})
hl.window_rule({
	name = "HoyoPlay",
	match = {
		class = "^(steam_app_3046681983)",
	},
	rounding = 0,
	float = true,
	confine_pointer = true,
})
hl.window_rule({
	name = "STL",
	match = {
		title = "(.*)(SteamTinkerLaunch)(.*)",
	},
	float = true,
})
hl.window_rule({
	name = "7d2d",
	match = {
		class = "^(steam_app_251570)",
	},
	confine_pointer = true,
})
hl.window_rule({
	name = "PowerWash",
	match = {
		class = "^(steam_app_1290000)",
	},
	confine_pointer = true,
})
hl.window_rule({
	name = "CIV",
	match = {
		title = "(.*)(Sid Meier's Civilization)(.*)",
	},
	confine_pointer = true,
})

hl.layer_rule({
	match = { namespace = "quickshell" },
	blur = true,
	ignore_alpha = 0.15,
})
