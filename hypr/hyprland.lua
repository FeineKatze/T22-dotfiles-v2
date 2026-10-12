require("modules.my_programs")
require("modules.animations")
require("modules.autostart")
require("modules.binds")
require("modules.cursor")
require("modules.decoration")
require("modules.ecosystem")
require("modules.general")
require("modules.gestures")
require("modules.group")
require("modules.input")
require("modules.layout")
require("modules.misc")
require("modules.monitors")
require("modules.opengl")
require("modules.quirks")
require("modules.render")
require("modules.windows_workspaces")
require("modules.xwayland")

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_THEME", "Adwaita")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GL_VRR_ALLOWED", "0")

hl.env("NVD_BACKEND", "direct")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")

hl.env("HYPRSHOT_DIR", "")
hl.env("XDG_PICTURES_DIR", "/home/christopher/Pictures")
hl.env("XDG_SCREENSHOTS_DIR", "/home/christopher/Pictures/Screenshots")
hl.env("HYPRSHOT_DIR", "/home/christopher/Pictures/Screenshots")

hl.env("WLR_NO_HARDWARE_CURSOR", "1")

hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")
