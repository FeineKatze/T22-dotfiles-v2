import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../shared"

Item {
    id: root

    readonly property string windowTitle: {
        const title = Hyprland.activeToplevel?.title;
        if (!title) {
            return qsTr("Desktop");
        }
        return title;
    }

    Layout.fillWidth: true

    Text {
        id: label
        text: root.windowTitle
        color: Theme.textColor
        elide: Text.ElideRight
        width: Math.max(0, Math.min(implicitWidth, root.width - 40)) // 20px margin on each side of the free space between the neighboring modules
        style: Theme.style
        styleColor: Theme.styleColor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        font {
            pointSize: Theme.pointSize
            bold: Theme.fontBold
            family: Theme.fontFamily
        }
    }
}
