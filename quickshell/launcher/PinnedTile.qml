import QtQuick
import QtQuick.Layouts
import "../shared"
import "fileicon.js" as FileIcon

Rectangle {
    id: tile

    required property string path
    required property int index
    // set when this tile's Repeater shares Launcher.selectedIndex with
    // another one ahead of it in the grid (eg. app search results before
    // these pinned matches) - 0 leaves the dedicated "pinned" mode grid
    // unaffected
    property int indexOffset: 0

    readonly property bool selected: tile.index + tile.indexOffset === Launcher.selectedIndex

    // same fixed square as AppTile, so both grids line up the same way
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
        onClicked: Launcher.openPath(tile.path)
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: FileIcon.iconFor(tile.path)
            color: Theme.textColor
            font {
                family: Theme.fontFamily
                pixelSize: 32
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            text: FileIcon.baseName(tile.path)
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
