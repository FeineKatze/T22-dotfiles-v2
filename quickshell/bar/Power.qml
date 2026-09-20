import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../shared"

Rectangle {
    id: rec

    property bool menuOpen: false

    radius: Theme.barRadius
    color: Theme.widgetBg
    implicitHeight: Theme.barHeight
    implicitWidth: label.implicitWidth + 16

    Text {
        id: label
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: "⏻"
        color: Theme.textColor
        style: Theme.style
        styleColor: Theme.styleColor

        font {
            family: Theme.fontFamily
            pointSize: Theme.pointSize
            bold: Theme.fontBold
        }
    }

    Process {
        id: checkProcess
        command: ["bash", "-c", "~/.local/bin/hypridle_inhibit_check.sh"]
        stdout: StdioCollector {
            onStreamFinished: label.text = text.trim()
        }
        onExited: running = false
    }

    Process {
        id: toggleProcess
        command: ["bash", "-c", "~/.local/bin/hypridle_inhibit.sh"]
        stdout: StdioCollector {
            onStreamFinished: checkProcess.running = true
        }
        onExited: running = false
    }

    Component.onCompleted: checkProcess.running = true

    HyprlandFocusGrab {
        id: grab
        windows: [menuPopup]
        active: rec.menuOpen
        onCleared: rec.menuOpen = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                toggleProcess.running = true;
            } else if (mouse.button === Qt.LeftButton) {
                rec.menuOpen = !rec.menuOpen;
            }
        }
    }

    PopupWindow {
        id: menuPopup

        anchor.item: rec
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6

        implicitWidth: menuColumn.implicitWidth + 20
        implicitHeight: menuColumn.implicitHeight + 16
        color: "transparent"

        visible: rec.menuOpen

        Rectangle {
            anchors.fill: parent
            radius: Theme.tooltipRadius
            color: Theme.tooltipBg
            border.color: Theme.tooltipBorder
            border.width: Theme.tooltipBorderWidth

            ColumnLayout {
                id: menuColumn
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: [
                        {
                            label: "Suspend",
                            command: ["systemctl", "suspend"]
                        },
                        {
                            label: "Shutdown",
                            command: ["poweroff"]
                        },
                        {
                            label: "Reboot",
                            command: ["reboot"]
                        }
                    ]

                    Rectangle {
                        id: menuItem
                        required property var modelData

                        Layout.fillWidth: true
                        implicitWidth: itemLabel.implicitWidth + 16
                        implicitHeight: itemLabel.implicitHeight + 8
                        radius: 4
                        color: itemHover.hovered ? Theme.menuItemHoverBg : "transparent"

                        Text {
                            id: itemLabel
                            anchors.centerIn: parent
                            text: menuItem.modelData.label
                            color: Theme.textColor
                            style: Theme.style
                            styleColor: Theme.styleColor
                            horizontalAlignment: Text.AlignHCenter

                            font {
                                family: Theme.fontFamily
                                pointSize: Theme.pointSize
                                bold: Theme.fontBold
                            }
                        }

                        HoverHandler {
                            id: itemHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(menuItem.modelData.command);
                                rec.menuOpen = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
