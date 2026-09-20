import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../shared"

Item {
    id: root
    required property var workspacesList
    required property string screenName

    // any workspace that currently exists on this monitor but isn't in the
    // configured wsRanges list (eg. created ad-hoc via `hyprctl dispatch
    // workspace 97`) - appended after the bound ones, same as waybar does
    // for workspaces outside its persistent-workspaces list
    readonly property var extraWorkspaceIds: {
        const bound = new Set(root.workspacesList);
        const extras = Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor && w.monitor.name === root.screenName && !bound.has(w.id)).map(w => w.id);
        extras.sort((a, b) => a - b);
        return extras;
    }

    readonly property var allWorkspaceIds: root.workspacesList.concat(root.extraWorkspaceIds)

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: root.allWorkspaceIds

            Item {
                required property int modelData

                // Pass explicit layout constraints to RowLayout
                Layout.preferredWidth: btn.implicitWidth
                Layout.preferredHeight: btn.height
                Layout.alignment: Qt.AlignVCenter

                WorkspaceButton {
                    id: btn
                    workspaceId: parent.modelData
                    anchors.centerIn: parent
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            let dir = event.angleDelta.y < 0 ? "m+1" : "m-1";
            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + dir + '" })');
        }
    }
}
