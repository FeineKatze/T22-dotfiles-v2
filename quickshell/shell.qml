//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "./shared"
import "./bar"
import "./notifications"
import "./osd"
import "./polkit"
import "./launcher"
import "./notes"
import "./switcher"

ShellRoot {
    IpcHandler {
        target: "notifications"

        function toggle(): void {
            Notifications.toggleCenter();
        }
        function debug(): string {
            Notifications.debugLogging = !Notifications.debugLogging;
            return Notifications.debugLogging ? "notification logging on" : "notification logging off";
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            Launcher.toggle();
        }
    }

    IpcHandler {
        target: "notes"

        function toggle(): void {
            Notes.toggle();
        }
    }

    IpcHandler {
        target: "switcher"

        function toggle(): void {
            Switcher.toggle();
        }
        // hold-to-cycle IPC surface (see ~/.config/hypr/modules/binds.lua's
        // "alttab" submap) - next/prev auto-open on the first call
        function next(): void {
            Switcher.next();
        }
        function prev(): void {
            Switcher.prev();
        }
        function confirm(): void {
            Switcher.activateSelected();
        }
        function cancel(): void {
            Switcher.close();
        }
    }

    Center {}

    HotCorner {}

    VolumeOsd {}

    PolkitDialog {}

    LauncherWindow {}

    NotesWindow {}

    // one instance per monitor - Switcher.displayMode decides which of them
    // are actually visible at any given time (see SwitcherWindow.qml)
    Variants {
        id: switcherVariants
        model: Quickshell.screens

        SwitcherWindow {
            required property var modelData
            screen: modelData
        }
    }

    // centralized here (not inside SwitcherWindow.qml) covering every
    // monitor's instance via Variants.instances - one shared grab, not one
    // per instance, so "all monitors" mode doesn't end up with several
    // simultaneous global grabs fighting each other (the same class of bug
    // fixed for the per-monitor Network module)
    HyprlandFocusGrab {
        windows: switcherVariants.instances
        active: Switcher.visible
        onCleared: Switcher.close()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panelWindow
            required property var modelData
            screen: modelData

            property var wsRanges: ({
                    "DP-1": [1, 2, 3, 4, 5],
                    "DP-2": [6, 7, 8, 9, 10],
                    "HDMI-A-1": [11, 12, 13]
                })
            property var myWorkspaces: wsRanges[modelData.name] ?? []

            readonly property var hyprMonitor: Hyprland.monitors.values.find(m => m.name === modelData.name)
            readonly property bool fullscreenActive: !!(panelWindow.hyprMonitor && panelWindow.hyprMonitor.activeWorkspace && panelWindow.hyprMonitor.activeWorkspace.hasFullscreen)

            // fully unmap the bar while this monitor has a fullscreen client -
            // a mapped top-layer surface can end up rendered *under* a
            // fullscreen window while still receiving pointer input, ie. an
            // invisible-but-clickable bar-shaped dead zone over the game
            visible: !panelWindow.fullscreenActive

            anchors {
                top: true
            }
            implicitHeight: Theme.barHeight
            implicitWidth: 1440
            color: "transparent"

            // Bar background
            Rectangle {
                anchors.fill: parent
                radius: Theme.barRadius
                color: Theme.barBg
            }

            // Bar content layout
            RowLayout {
                anchors.fill: parent
                anchors.rightMargin: 0

                Workspaces {
                    workspacesList: panelWindow.myWorkspaces
                    screenName: modelData.name
                }

                Tray {
                    trayWindow: panelWindow
                }

                Mpris {}

                ActiveWindow {}

                Network {}

                Pipewire {}

                Clock {}

                Power {}
            }
        }
    }

    Popups {}
}
