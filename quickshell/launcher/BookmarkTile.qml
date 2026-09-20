import QtQuick
import QtQuick.Layouts
import "../shared"

Rectangle {
    id: tile

    required property var entry // { title, url }
    required property int index

    readonly property bool selected: tile.index === Launcher.selectedIndex

    // same fixed square as AppTile/PinnedTile, so every grid lines up the same way
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
        onClicked: Launcher.openBookmark(tile.entry)
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "🔖"
            font.pixelSize: 28
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: tile.entry.title
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
