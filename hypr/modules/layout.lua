hl.config({
	layout = {},
	-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
	dwindle = {
		preserve_split = true, -- You probably want this
	},
	-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
	master = {
		new_status = "master",
	},
	-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
	scrolling = {
		fullscreen_on_one_column = true,
		column_width = 0.5,
		focus_fit_method = 1,
		follow_focus = true,
		follow_min_visible = 0.4,
		explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
		wrap_focus = true,
		wrap_swapcol = true,
		direction = "right",
	},
})
