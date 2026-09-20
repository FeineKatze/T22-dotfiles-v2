import QtQuick
import QtQuick.Layouts
import "../shared"

// One tile in the power-mode row - same square/hover shape as AppTile, but a
// glyph instead of an app icon and no library metadata. A null command marks
// an unimplemented placeholder slot: dimmed, unclickable, unselectable.
Rectangle {
    id: tile

    required property var entry
    required property int index

    readonly property bool enabledSlot: tile.entry.command !== null
    readonly property bool selected: tile.enabledSlot && tile.index === Launcher.selectedIndex

    implicitWidth: 96
    implicitHeight: 96
    radius: 6
    color: (tile.selected || hover.hovered) ? Theme.menuItemHoverBg : "transparent"
    opacity: tile.enabledSlot ? 1 : 0.35

    HoverHandler {
        id: hover
        enabled: tile.enabledSlot
    }

    MouseArea {
        anchors.fill: parent
        enabled: tile.enabledSlot
        cursorShape: Qt.PointingHandCursor
        onClicked: Launcher.activatePower(tile.entry)
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.entry.glyph
            color: Theme.textColor
            style: Theme.style
            styleColor: Theme.styleColor
            font {
                family: Theme.fontFamily
                pointSize: Theme.pointSize + 10
                bold: Theme.fontBold
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            text: tile.entry.label
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
