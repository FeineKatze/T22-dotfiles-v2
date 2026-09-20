import QtQuick
import Quickshell
import Quickshell.Widgets
import "../shared"

Rectangle {
    id: tile

    required property var toplevel
    required property int index // index within Switcher.visibleWindows

    readonly property bool selected: Switcher.scrollOffset + tile.index === Switcher.selectedIndex

    // fixed square, same shape as launcher/AppTile.qml, but each tile
    // carries its own squircle background instead of the window having one
    implicitWidth: 96
    implicitHeight: 96
    radius: 6
    color: Theme.tooltipBg
    border.color: tile.selected ? Theme.tooltipBorder : "transparent"
    border.width: 1

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: (tile.selected || hover.hovered) ? Theme.menuItemHoverBg : "transparent"
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Switcher.activate(tile.toplevel)
    }

    IconImage {
        anchors.centerIn: parent
        width: 48
        height: 48
        source: Switcher.iconFor(tile.toplevel)
    }
}
