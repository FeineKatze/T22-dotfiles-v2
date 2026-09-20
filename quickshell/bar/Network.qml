import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../shared"
import "../network"

Rectangle {
    id: rec
    radius: Theme.barRadius
    color: Theme.widgetBg
    implicitHeight: Theme.barHeight
    implicitWidth: contentRow.implicitWidth + 20

    // per-instance (Network {} is created once per monitor) - see
    // network/NetworkCenter.qml's centerMode comment for why this can't
    // live on the shared Connectivity singleton
    property bool centerOpen: false

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: Connectivity.wiredConnected
            text: String.fromCodePoint(0xF0200) // md-ethernet
            color: Theme.textColor
            style: Theme.style
            styleColor: Theme.styleColor
            font {
                family: Theme.fontFamily
                pointSize: Theme.pointSize
                bold: Theme.fontBold
            }
        }

        Text {
            id: text
            text: Connectivity.label
            color: Theme.textColor
            style: Theme.style
            styleColor: Theme.styleColor
            font {
                family: Theme.fontFamily
                bold: true
                pointSize: Theme.pointSize
            }
        }

        Text {
            visible: Connectivity.btActive
            text: String.fromCodePoint(0xF00B1) // md-bluetooth_connect
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

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: rec.centerOpen = !rec.centerOpen
    }

    NetworkCenter {
        id: networkCenter
        anchorItem: rec
        centerOpen: rec.centerOpen
    }

    HyprlandFocusGrab {
        id: networkGrab
        windows: [networkCenter]
        active: rec.centerOpen
        onCleared: rec.centerOpen = false
    }

    PopupWindow {
        id: tooltipPopup

        anchor.item: rec
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6

        implicitWidth: tooltipLabel.implicitWidth + 16
        implicitHeight: tooltipLabel.implicitHeight + 10
        color: "transparent"

        visible: mouseArea.containsMouse && !rec.centerOpen

        Rectangle {
            anchors.fill: parent
            radius: Theme.tooltipRadius
            color: Theme.tooltipBg
            border.color: Theme.tooltipBorder
            border.width: Theme.tooltipBorderWidth

            Text {
                id: tooltipLabel
                anchors.centerIn: parent
                color: Theme.textColor
                style: Theme.style
                styleColor: Theme.styleColor
                font {
                    family: Theme.fontFamily
                    pointSize: Theme.pointSize
                    bold: true
                }

                text: {
                    const parts = [];
                    if (Connectivity.activeWifi)
                        parts.push(Connectivity.activeWifi.name);
                    if (Connectivity.wiredConnected)
                        parts.push("Ethernet");
                    if (parts.length === 0)
                        parts.push("Offline");
                    for (const dev of Connectivity.btConnectedDevices)
                        parts.push(dev.name);
                    return parts.join(" · ");
                }
            }
        }
    }
}
