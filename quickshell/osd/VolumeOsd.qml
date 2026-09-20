import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../shared"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: osdWindow
        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-osd"

        anchors {
            bottom: true
        }
        margins.bottom: 40

        exclusiveZone: 0
        color: "transparent"

        implicitWidth: pill.implicitWidth
        implicitHeight: pill.implicitHeight

        visible: Osd.visible

        Rectangle {
            id: pill
            implicitWidth: row.implicitWidth + 28
            implicitHeight: Theme.barHeight
            radius: height / 2
            color: Theme.widgetBg

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 0

                Text {
                    text: Osd.label
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
                    text: Osd.icon
                    visible: Osd.icon.length > 0
                    color: Theme.textColor
                    style: Theme.style
                    styleColor: Theme.styleColor
                    Layout.leftMargin: 8

                    font {
                        family: Theme.fontFamily
                        pointSize: Theme.pointSize + 3
                        bold: Theme.fontBold
                    }
                }
            }
        }
    }
}
