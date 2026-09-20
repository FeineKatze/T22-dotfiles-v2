import QtQuick
import Quickshell
import Quickshell.Wayland
import "../shared"

PanelWindow {
    id: cornerWindow
    screen: Quickshell.screens.find(s => s.name === "DP-1") ?? null

    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
    }
    margins {
        top: -35
        right: 0
    }

    exclusiveZone: 0
    color: "transparent" // TEMP debug color so the hover zone is visible — remove once confirmed working

    implicitWidth: 35
    implicitHeight: 35

    HoverHandler {
        id: cornerHover
        onHoveredChanged: {
            if (cornerHover.hovered)
                openDelay.restart();
            else
                openDelay.stop();
        }
    }

    // brief dwell time so just brushing past the corner doesn't pop the center open
    Timer {
        id: openDelay
        interval: 300
        onTriggered: {
            if (cornerHover.hovered && !Notifications.centerVisible)
                Notifications.centerVisible = true;
        }
    }
}
