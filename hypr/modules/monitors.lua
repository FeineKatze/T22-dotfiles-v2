------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
	output = "DP-1", --Output name or desc:... description prefix;default=required String
	mode = "1920x1080@240", --Resolution and refresh rate, e.g. 1920x1080@144; default=preferred String
	position = "0x0", --Position in the virtual layout, e.g. 1920x0; default=auto string
	scale = "1", --Scale factor, e.g. 1.5; default=auto String/Float
	disabled = false, --Removes the monitor from the layout; default=false Boolean
	transform = 0, --Rotation/flip transform (0–7); default=0 Integer
	mirror = "", --Output name to mirror; default=  String
	bitdepth = 8, --Bit depth (8 or 10); default=8 Integer
	cm = "srgb", --Color management preset; default=srgb String
	sdr_eotf = "default", --SDR transfer function (default, gamma22, srgb); default=default String
	sdrbrightness = "1.0", --SDR brightness in HDR mode; default=1.0 Float
	sdrsaturation = "1.0", --SDR saturation in HDR mode; default=1.0 Float
	vrr = 0, --VRR mode; default=0 Integer
	--icc = "", --Absolute path to an ICC profile; default=  String
	reserved_area = "0", --Reserved area - integer for all sides, or table with top/right/bottom/left; default=0 Integer/Table
	supports_wide_color = 0, --Force wide color gamut (-1 = off, 0 = auto, 1 = on); default=0 Integer
	supports_hdr = 0, --Force HDR support (-1 = off, 0 = auto, 1 = on); default=0 Integer
	sdr_min_luminance = 0.2, --SDR minimum luminance for SDR→HDR mapping; default=0.2 Float
	sdr_max_luminance = 80, --SDR maximum luminance; default=80 Integer
	min_luminance = -1, --Monitor minimum luminance; default=-1 Float
	max_luminance = -1, --Monitor maximum possible luminance; default=-1 Integer
	max_avg_luminance = -1, --Monitor maximum average luminance; default=-1 Integer
})
hl.monitor({
	output = "DP-2", --Output name or desc:... description prefix;default=required String
	mode = "1920x1080@240", --Resolution and refresh rate, e.g. 1920x1080@144; default=preferred String
	position = "1920x0", --Position in the virtual layout, e.g. 1920x0; default=auto string
	scale = "1", --Scale factor, e.g. 1.5; default=auto String/Float
	disabled = false, --Removes the monitor from the layout; default=false Boolean
	transform = 0, --Rotation/flip transform (0–7); default=0 Integer
	mirror = "", --Output name to mirror; default=  String
	bitdepth = 8, --Bit depth (8 or 10); default=8 Integer
	cm = "srgb", --Color management preset; default=srgb String
	sdr_eotf = "default", --SDR transfer function (default, gamma22, srgb); default=default String
	sdrbrightness = "1.0", --SDR brightness in HDR mode; default=1.0 Float
	sdrsaturation = "1.0", --SDR saturation in HDR mode; default=1.0 Float
	vrr = 0, --VRR mode; default=0 Integer
	--icc = "", --Absolute path to an ICC profile; default=  String
	reserved_area = "0", --Reserved area - integer for all sides, or table with top/right/bottom/left; default=0 Integer/Table
	supports_wide_color = 0, --Force wide color gamut (-1 = off, 0 = auto, 1 = on); default=0 Integer
	supports_hdr = 0, --Force HDR support (-1 = off, 0 = auto, 1 = on); default=0 Integer
	sdr_min_luminance = 0.2, --SDR minimum luminance for SDR→HDR mapping; default=0.2 Float
	sdr_max_luminance = 80, --SDR maximum luminance; default=80 Integer
	min_luminance = -1, --Monitor minimum luminance; default=-1 Float
	max_luminance = -1, --Monitor maximum possible luminance; default=-1 Integer
	max_avg_luminance = -1, --Monitor maximum average luminance; default=-1 Integer
})
hl.monitor({
	output = "HDMI-A-1", --Output name or desc:... description prefix;default=required String
	mode = "1920x1080@60", --Resolution and refresh rate, e.g. 1920x1080@144; default=preferred String
	position = "0x1080", --Position in the virtual layout, e.g. 1920x0; default=auto string
	scale = "1", --Scale factor, e.g. 1.5; default=auto String/Float
	disabled = false, --Removes the monitor from the layout; default=false Boolean
	transform = 0, --Rotation/flip transform (0–7); default=0 Integer
	mirror = "", --Output name to mirror; default=  String
	bitdepth = 8, --Bit depth (8 or 10); default=8 Integer
	cm = "srgb", --Color management preset; default=srgb String
	sdr_eotf = "default", --SDR transfer function (default, gamma22, srgb); default=default String
	sdrbrightness = "1.0", --SDR brightness in HDR mode; default=1.0 Float
	sdrsaturation = "1.0", --SDR saturation in HDR mode; default=1.0 Float
	vrr = 0, --VRR mode; default=0 Integer
	--icc = "", --Absolute path to an ICC profile; default=  String
	reserved_area = "0", --Reserved area - integer for all sides, or table with top/right/bottom/left; default=0 Integer/Table
	supports_wide_color = 0, --Force wide color gamut (-1 = off, 0 = auto, 1 = on); default=0 Integer
	supports_hdr = 0, --Force HDR support (-1 = off, 0 = auto, 1 = on); default=0 Integer
	sdr_min_luminance = 0.2, --SDR minimum luminance for SDR→HDR mapping; default=0.2 Float
	sdr_max_luminance = 80, --SDR maximum luminance; default=80 Integer
	min_luminance = -1, --Monitor minimum luminance; default=-1 Float
	max_luminance = -1, --Monitor maximum possible luminance; default=-1 Integer
	max_avg_luminance = -1, --Monitor maximum average luminance; default=-1 Integer
})
