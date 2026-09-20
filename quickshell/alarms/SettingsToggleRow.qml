import QtQuick
import QtQuick.Layouts
import "../shared"

// One "label ... On/Off" row for the alarms popup's settings screen
RowLayout {
    id: row

    required property string label
    required property bool value
    required property var onToggle // function() - called on click

    Layout.fillWidth: true

    Text {
        Layout.fillWidth: true
        text: row.label
        color: Theme.textColor
        font {
            family: Theme.fontFamily
            pixelSize: Theme.fontSize
        }
    }

    Rectangle {
        implicitWidth: toggleLabel.implicitWidth + 16
        implicitHeight: toggleLabel.implicitHeight + 8
        radius: 4
        color: (row.value || toggleHover.hovered) ? Theme.menuItemHoverBg : "transparent"

        Text {
            id: toggleLabel
            anchors.centerIn: parent
            text: row.value ? "On" : "Off"
            color: Theme.textColor
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize
                bold: true
            }
        }

        HoverHandler {
            id: toggleHover
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.onToggle()
        }
    }
}
