----------------
---Decoration---
----------------
---https://wiki.hypr.land/Configuring/Basics/Variables/#decoration

hl.config({
	decoration = {
		rounding = 10, --rounded corners’ radius (in layout px); int; 0
		rounding_power = 3.0, --adjusts the curve used for rounding corners, larger is smoother, 2.0 is a circle, 4.0 is a squircle, 1.0 is a triangular corner. [1.0 - 10.0]; float; 2.0
		active_opacity = 1.0, --opacity of active windows. [0.0 - 1.0]; float; 1.0
		inactive_opacity = 1.0, --opacity of inactive windows. [0.0 - 1.0]; float; 1.0
		fullscreen_opacity = 1.0, --opacity of inactive windows. [0.0 - 1.0]; float; 1.0
		dim_modal = true, --enables dimming of parents of modal windows; bool; true
		dim_inactive = false, --enables dimming of inactive windows; bool; false
		dim_strength = 0.5, --how much inactive windows should be dimmed [0.0 - 1.0]; float; 0.5
		dim_special = 0.2, --how much to dim the rest of the screen by when a special workspace is open. [0.0 - 1.0]; float; 0.2
		dim_around = 0.4, --how much the dim_around window rule should dim by. [0.0 - 1.0]; float; 0.4
		screen_shader = "", --a path to a custom shader to be applied at the end of rendering. See examples/screenShader.frag for an example.; str; [[Empty]]
		border_part_of_window = true, --whether the window border should be a part of the window; bool; true

		----------
		---Blur---
		----------
		---https://wiki.hypr.land/Configuring/Basics/Variables/#blur

		blur = {
			enabled = true, --enable kawase window background blur; bool; true
			size = 3,
			passes = 1,
			ignore_opacity = true,
			new_optimizations = true,
			xray = false,
			noise = 0.0117,
			contrast = 0.8916,
			brightness = 0.8172,
			vibrancy = 0.1696,
			vibrancy_darkness = 0.0,
			special = false,
			popups = false,
			popups_ignorealpha = 0.2,
			input_methods = false,
			input_methods_ignorealpha = 0.2,
		},

		------------
		---Shadow---
		------------
		---https://wiki.hypr.land/Configuring/Basics/Variables/#shadow

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			sharp = false,
			color = 0xee1a1a1a,
			color_inactive = 0xee1a1a1a,
			offset = { 0, 0 },
			scale = 1.0,
		},

		----------
		---Glow---
		----------
		---https://wiki.hypr.land/Configuring/Basics/Variables/#glow

		glow = {
			enabled = false,
			range = 10,
			render_power = 3,
			color = 0xee1a1a1a,
			color_inactive = 0xee1a1a1a,
		},
	},
})
