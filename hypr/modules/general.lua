-------------
---General---
-------------
---https://wiki.hypr.land/Configuring/Basics/Variables/#general

hl.config({
	general = {
		border_size = 2, --size of the border around windows; int; 1
		gaps_in = 5, --gaps between windows; css_gaps; 5
		gaps_out = 10, --gaps between windows and monitor edges; css_gaps; 20
		float_gaps = 0, --gaps between windows and monitor edges for floating windows -1 means default; css_gaps; 0
		gaps_workspaces = 0, --gaps between workspaces. Stacks with gaps_out.; css_gaps; 0
		col = {
			inactive_border = "rgba(595959aa)", --border color for inactive windows; gradient; 0xff444444
			active_border = { --border color for the active window; gradient; 0xffffffff
				colors = { "rgba(33ccffee)", "rgba(00ff99ee)" },
				angle = 45,
			},
			nogroup_border = 0xffffaaff, --inactive border color for window that cannot be added to a group (see denywindowfromgroup dispatcher); gradient; 0xffffaaff
			nogroup_border_active = 0xffff00ff, --active border color for window that cannot be added to a group; gradient; 0xffff00ff
		},
		layout = "dwindle", --which layout to use. [dwindle/master/scrolling/monocle]; str; dwindle
		no_focus_fallback = true, --if true, will not fall back to the next available window when moving focus in a direction where no window was found; bool; false
		resize_on_border = false, --enables resizing windows by clicking and dragging on borders and gaps; bool; false
		extend_border_grab_area = 15, --extends the area around the border where you can click and drag on, only used when general:resize_on_border is on.; int; 15
		hover_icon_on_border = true, --show a cursor icon when hovering over borders, only used when general:resize_on_border is on.; bool; true
		allow_tearing = false, --master switch for allowing tearing to occur. See the Tearing page.; bool; false
		resize_corner = 0, --force floating windows to use a specific corner when being resized (1-4 going clockwise from top left, 0 to disable); int; 0
		modal_parent_blocking = true, --whether parent windows of modals will be interactive; bool; true
		locale = "", --overrides the system locale (e.g. en_US, es); str; [[Empty]]

		----------
		---Snap---
		----------
		---https://wiki.hypr.land/Configuring/Basics/Variables/#snap

		snap = {
			enabled = false, --enable snapping for floating windows; bool; false
			window_gap = 10, --minimum gap in pixels between windows before snapping; int; 10
			monitor_gap = 10, --minimum gap in pixels between window and monitor edges before snapping; int; 10
			border_overlap = false, --if true, windows snap such that only one border’s worth of space is between them; bool; false
			respect_gaps = false, --if true, snapping will respect gaps between windows(set in general:gaps_in); bool; false
		},
	},
})
