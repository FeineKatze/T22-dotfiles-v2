import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../shared"

// One tile in the "kill" grid - same icon+title shape as StashTile, for a
// window Enter/Shift+Enter can SIGTERM/SIGKILL by pid.
Rectangle {
    id: tile

    required property var entry
    required property int index

    readonly property bool selected: tile.index === Launcher.selectedIndex

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
        acceptedButtons: Qt.LeftButton
        onClicked: {
            Launcher.selectedIndex = tile.index;
            Launcher.killSelected("-TERM");
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 4

        IconImage {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            source: {
                const found = DesktopEntries.heuristicLookup(tile.entry.appClass);
                return Quickshell.iconPath(found ? found.icon : tile.entry.appClass, "application-x-executable");
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
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
