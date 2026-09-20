import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../shared"

PanelWindow {
    id: popupWindow

    // preferred monitor order, skipping past any that currently have a
    // fullscreen client - a layer-shell surface can end up rendered *under*
    // a fullscreen window while still being an interactive region, which is
    // both invisible (can't see the notification) and can steal pointer
    // input from the fullscreen app; picking a monitor with nothing
    // fullscreen avoids both
    readonly property var monitorOrder: ["DP-1", "DP-2", "HDMI-A-1"]
    readonly property string targetScreenName: {
        for (const name of popupWindow.monitorOrder) {
            const mon = Hyprland.monitors.values.find(m => m.name === name);
            const hasFullscreen = mon && mon.activeWorkspace && mon.activeWorkspace.hasFullscreen;
            if (mon && !hasFullscreen)
                return name;
        }
        return popupWindow.monitorOrder[0];
    }

    screen: Quickshell.screens.find(s => s.name === popupWindow.targetScreenName) ?? Quickshell.screens[0] ?? null

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-popups"

    anchors {
        top: true
        right: true
    }
    margins {
        top: 6
        right: 8
    }

    exclusiveZone: 0
    color: "transparent"

    implicitWidth: popupColumn.implicitWidth
    implicitHeight: popupColumn.implicitHeight

    ColumnLayout {
        id: popupColumn
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 6

        Repeater {
            model: Notifications.popupEntries

            NotificationItem {
                id: item
                required property var modelData

                entry: modelData

                Timer {
                    running: true
                    interval: item.entry.expireTimeout > 0 ? item.entry.expireTimeout : Notifications.defaultTimeout
                    onTriggered: Notifications.expirePopup(item.entry.id)
                }

                onDismissRequested: Notifications.dismissPopup(item.entry.id)
            }
        }
    }
}
