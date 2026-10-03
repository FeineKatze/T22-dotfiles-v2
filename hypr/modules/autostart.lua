-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
	hl.exec_cmd("qs")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("floorp")
	hl.exec_cmd("vesktop")
	hl.exec_cmd("companion")
	hl.exec_cmd("hypridle")
	hl.exec_cmd(
		"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland XDG_RUNTIME_DIR HYPRLAND_INSTANCE_SIGNATURE"
	)
	hl.exec_cmd(
		"systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start hyprland-session.target"
	)
	-- hl.exec_cmd("easyeffects -w")
	hl.exec_cmd("gsr-ui")
end)
