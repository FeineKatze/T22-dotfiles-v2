import QtQuick
import "../shared"

// One "file" pill in the notes header row - deliberately styled after
// bar/WorkspaceButton.qml (small pill, same hover/active color scheme)
// rather than the launcher's big square tiles.
Rectangle {
    id: tab

    required property int slotIndex

    readonly property bool isActive: tab.slotIndex === Notes.activeIndex

    implicitWidth: Math.max(26, label.implicitWidth + 12)
    height: Theme.barHeight
    radius: Theme.barRadius
    color: tab.isActive ? Theme.wsActiveBg : (hoverHandler.hovered ? Theme.wsHoverBg : Theme.wsDefaultBg)

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Notes.setActiveIndex(tab.slotIndex)
    }

    HoverHandler {
        id: hoverHandler
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: tab.slotIndex + 1
        color: Theme.textColor
        style: Theme.style
        styleColor: Theme.styleColor

        font {
            family: Theme.fontFamily
            pointSize: Theme.pointSize
            bold: Theme.fontBold
        }
    }
}
