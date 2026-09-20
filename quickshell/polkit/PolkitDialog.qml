import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../shared"

PanelWindow {
    id: dialogWindow
    screen: Quickshell.screens.find(s => s.name === "DP-1") ?? null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Polkit.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-polkit"

    visible: Polkit.isActive

    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 340
    implicitHeight: mainColumn.implicitHeight + 32

    property string password: ""

    // reset the field whenever a new authentication attempt starts (including retries after a wrong password)
    Connections {
        target: Polkit
        function onFlowChanged() {
            dialogWindow.password = "";
        }
    }

    function trySubmit() {
        if (!Polkit.flow || !Polkit.flow.isResponseRequired)
            return;
        Polkit.submit(dialogWindow.password);
        dialogWindow.password = "";
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.tooltipBg
        border.color: Theme.tooltipBorder
        border.width: Theme.tooltipBorderWidth

        ColumnLayout {
            id: mainColumn
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                IconImage {
                    id: dialogIcon

                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    visible: source.toString().length > 0

                    readonly property string iconName: (Polkit.flow && Polkit.flow.iconName.length > 0) ? Polkit.flow.iconName : "gcr-password"
                    source: Polkit.flow ? Quickshell.iconPath(dialogIcon.iconName, "gcr-password") : ""
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: Polkit.flow ? Polkit.flow.message : ""
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

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: passwordInput.implicitHeight + 12
                radius: 4
                color: Theme.widgetBg
                visible: Polkit.flow && Polkit.flow.isResponseRequired

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: 6
                    verticalAlignment: TextInput.AlignVCenter
                    focus: dialogWindow.visible
                    echoMode: (Polkit.flow && Polkit.flow.responseVisible) ? TextInput.Normal : TextInput.Password
                    text: dialogWindow.password
                    color: Theme.textColor
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }
                    onTextChanged: dialogWindow.password = text
                    onAccepted: dialogWindow.trySubmit()
                    Keys.onEscapePressed: Polkit.cancel()
                }

                Text {
                    anchors.fill: passwordInput
                    verticalAlignment: Text.AlignVCenter
                    visible: passwordInput.text.length === 0
                    text: Polkit.flow ? Polkit.flow.inputPrompt : ""
                    opacity: 0.4
                    color: Theme.textColor
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                visible: Polkit.flow && Polkit.flow.supplementaryMessage.length > 0
                text: Polkit.flow ? Polkit.flow.supplementaryMessage : ""
                color: (Polkit.flow && Polkit.flow.supplementaryIsError) ? "#e94b4b" : Theme.textColor
                style: Theme.style
                styleColor: Theme.styleColor

                font {
                    family: Theme.fontFamily
                    pointSize: Theme.pointSize - 2
                    bold: Theme.fontBold
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: cancelLabel.implicitWidth + 16
                    implicitHeight: cancelLabel.implicitHeight + 10
                    radius: 4
                    color: cancelHover.hovered ? Theme.menuItemHoverBg : "transparent"

                    HoverHandler {
                        id: cancelHover
                    }

                    Text {
                        id: cancelLabel
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pointSize: Theme.pointSize
                            bold: Theme.fontBold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Polkit.cancel()
                    }
                }

                Rectangle {
                    implicitWidth: authLabel.implicitWidth + 16
                    implicitHeight: authLabel.implicitHeight + 10
                    radius: 4
                    color: authHover.hovered ? Theme.menuItemHoverBg : "transparent"

                    HoverHandler {
                        id: authHover
                    }

                    Text {
                        id: authLabel
                        anchors.centerIn: parent
                        text: "Authenticate"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pointSize: Theme.pointSize
                            bold: Theme.fontBold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialogWindow.trySubmit()
                    }
                }
            }
        }
    }
}
