import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../shared"

PanelWindow {
    id: centerWindow
    screen: Quickshell.screens.find(s => s.name === "DP-1") ?? null

    WlrLayershell.layer: WlrLayer.Overlay

    visible: Notifications.centerVisible

    anchors {
        top: true
        right: true
    }
    margins {
        top: 6
        right: 8
    }

    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 340
    implicitHeight: containerColumn.implicitHeight + 16

    Timer {
        running: Notifications.centerVisible
        interval: 10000
        onTriggered: Notifications.centerVisible = false
    }

    HyprlandFocusGrab {
        id: grab
        windows: [centerWindow]
        active: Notifications.centerVisible
        onCleared: Notifications.centerVisible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.tooltipRadius
        color: Theme.tooltipBg
        border.color: Theme.tooltipBorder
        border.width: Theme.tooltipBorderWidth

        ColumnLayout {
            id: containerColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: Theme.textColor
                    style: Theme.style
                    styleColor: Theme.styleColor
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                        bold: true
                    }
                }

                Rectangle {
                    id: muteButton
                    implicitWidth: muteLabel.implicitWidth + 12
                    implicitHeight: muteLabel.implicitHeight + 6
                    radius: 4
                    color: muteHover.hovered ? Theme.menuItemHoverBg : "transparent"

                    Text {
                        id: muteLabel
                        anchors.centerIn: parent
                        text: Notifications.muted ? "🔕" : "🔔"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: Theme.fontBold
                        }
                    }

                    HoverHandler {
                        id: muteHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.toggleMute()
                    }
                }

                Rectangle {
                    id: clearButton
                    implicitWidth: clearLabel.implicitWidth + 12
                    implicitHeight: clearLabel.implicitHeight + 6
                    radius: 4
                    color: clearHover.hovered ? Theme.menuItemHoverBg : "transparent"

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                            bold: Theme.fontBold
                        }
                    }

                    HoverHandler {
                        id: clearHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.clearHistory()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: Notifications.historyEntries.length === 0
                text: "No notifications"
                opacity: 0.6
                color: Theme.textColor
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: Notifications.historyEntries

                    NotificationItem {
                        id: histItem
                        required property var modelData

                        entry: modelData

                        onDismissRequested: Notifications.dismissHistory(histItem.entry.id)
                    }
                }
            }
        }
    }
}
