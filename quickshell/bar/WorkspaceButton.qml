import QtQuick
import Quickshell.Hyprland
import "../shared"

Rectangle {
    id: workspaceRect

    required property int workspaceId

    property bool isActive: Hyprland.focusedWorkspace?.id === workspaceId

    property bool isUrgent: {
        let toplevels = Hyprland.toplevels.values;
        for (let i = 0; i < toplevels.length; i++) {
            let win = toplevels[i];
            if (win.workspace?.id === workspaceId && win.urgent) {
                return true;
            }
        }
        return false;
    }

    property bool hasWindow: {
        let toplevels = Hyprland.toplevels.values;
        for (let i = 0; i < toplevels.length; i++) {
            if (toplevels[i].workspace?.id === workspaceId) {
                return true;
            }
        }
        return false;
    }

    implicitWidth: (workspaceId < 10) ? 26 : 28
    height: Theme.barHeight
    radius: Theme.barRadius
    color: Theme.wsDefaultBg

    states: [
        State {
            name: "urgent"
            when: workspaceRect.isUrgent
            PropertyChanges {
                workspaceRect.color: Theme.wsUrgentBg
            }
        },
        State {
            name: "hover"
            when: hoverHandler.hovered
            PropertyChanges {
                workspaceRect.color: Theme.wsHoverBg
            }
        },
        State {
            name: "active"
            when: workspaceRect.isActive
            PropertyChanges {
                workspaceRect.color: Theme.wsActiveBg
            }
        },
        State {
            name: "default"
            when: workspaceRect.hasWindow
            PropertyChanges {
                workspaceRect.color: Theme.wsHasWindowBg
            }
        }
    ]

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (parent.workspaceId) + " })")
    }

    HoverHandler {
        id: hoverHandler
    }

    Text {
        text: workspaceRect.workspaceId
        color: Theme.textColor
        anchors.centerIn: parent
        style: Theme.style
        styleColor: Theme.styleColor

        font {
            family: Theme.fontFamily
            pointSize: Theme.pointSize
            bold: Theme.fontBold
        }
    }
}
