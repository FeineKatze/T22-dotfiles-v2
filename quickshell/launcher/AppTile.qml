import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../shared"

Rectangle {
    id: tile

    required property var entry
    required property int index

    readonly property bool selected: tile.index === Launcher.selectedIndex

    // fixed square so every tile (and its hover/selection highlight) is
    // exactly the same size, regardless of how long the app name is
    implicitWidth: 96
    implicitHeight: 96
    radius: 6
    color: (tile.selected || hover.hovered) ? Theme.menuItemHoverBg : "transparent"

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Launcher.launch(tile.entry)
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 4

        IconImage {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            source: Quickshell.iconPath(tile.entry.icon, "")
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            text: tile.entry.name
            color: Theme.textColor
            style: Theme.style
            styleColor: Theme.styleColor

            font {
                family: Theme.fontFamily
                pointSize: Theme.pointSize - 2
                bold: Theme.fontBold
            }
        }
    }
}
