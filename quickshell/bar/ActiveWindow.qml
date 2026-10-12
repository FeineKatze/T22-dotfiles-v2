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

        HoverHandler {
            id: labelHover
        }
    }

    // full title, only while hovering and the bar label is actually cut off
    PopupWindow {
        anchor.item: label
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6

        implicitWidth: tooltipLabel.implicitWidth + 16
        implicitHeight: tooltipLabel.implicitHeight + 10
        color: "transparent"

        visible: labelHover.hovered && label.truncated

        Rectangle {
            anchors.fill: parent
            radius: Theme.tooltipRadius
            color: Theme.tooltipBg
            border.color: Theme.tooltipBorder
            border.width: Theme.tooltipBorderWidth

            Text {
                id: tooltipLabel
                anchors.centerIn: parent
                text: root.windowTitle
                color: Theme.textColor
                style: Theme.style
                styleColor: Theme.styleColor
                font {
                    family: Theme.fontFamily
                    pointSize: Theme.pointSize
                    bold: true
                }
            }
        }
    }
}
