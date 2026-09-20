import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import "../shared"

PopupWindow {
    id: popup

    required property var anchorItem
    required property bool centerOpen

    // owned per-instance (there's one NetworkCenter per monitor) rather than
    // shared on the Connectivity singleton - sharing it made every monitor's
    // HyprlandFocusGrab activate together on a single click, which fight
    // each other for the global grab and immediately clear
    property string centerMode: "wifi" // "wifi" | "bluetooth"

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: mainColumn.implicitWidth + 34
    implicitHeight: mainColumn.implicitHeight + 30
    color: "transparent"

    visible: centerOpen

    // SSID of the network whose inline password row is currently expanded,
    // "" when none - only one at a time
    property string pendingPasswordNetwork: ""

    // only scan/discover while the panel is actually open, and only on the
    // relevant tab - same "don't poll when nobody's looking" convention as
    // bar/Mpris.qml's timer
    readonly property bool wifiTabOpen: popup.centerOpen && popup.centerMode === "wifi"
    readonly property bool btTabOpen: popup.centerOpen && popup.centerMode === "bluetooth"

    onWifiTabOpenChanged: if (Connectivity.wifiDevice)
        Connectivity.wifiDevice.scannerEnabled = popup.wifiTabOpen
    onBtTabOpenChanged: if (!popup.btTabOpen && Connectivity.btAdapter)
        Connectivity.btAdapter.discovering = false
    onCenterOpenChanged: if (!popup.centerOpen)
        popup.pendingPasswordNetwork = ""

    Rectangle {
        anchors.fill: parent
        radius: Theme.tooltipRadius
        color: Theme.tooltipBg
        border.color: Theme.tooltipBorder
        border.width: Theme.tooltipBorderWidth

        ColumnLayout {
            id: mainColumn
            anchors.centerIn: parent
            spacing: 9

            RowLayout {
                spacing: 6

                Rectangle {
                    implicitWidth: wifiTabLabel.implicitWidth + 22
                    implicitHeight: wifiTabLabel.implicitHeight + 10
                    radius: 4
                    color: (popup.centerMode === "wifi" || wifiTabHover.hovered) ? Theme.menuItemHoverBg : "transparent"

                    Text {
                        id: wifiTabLabel
                        anchors.centerIn: parent
                        text: "Wi-Fi"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: true
                        }
                    }

                    HoverHandler {
                        id: wifiTabHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.centerMode = "wifi"
                    }
                }

                Rectangle {
                    implicitWidth: btTabLabel.implicitWidth + 22
                    implicitHeight: btTabLabel.implicitHeight + 10
                    radius: 4
                    color: (popup.centerMode === "bluetooth" || btTabHover.hovered) ? Theme.menuItemHoverBg : "transparent"

                    Text {
                        id: btTabLabel
                        anchors.centerIn: parent
                        text: "Bluetooth"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: true
                        }
                    }

                    HoverHandler {
                        id: btTabHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.centerMode = "bluetooth"
                    }
                }
            }

            // --- Wi-Fi view ---
            ColumnLayout {
                visible: popup.centerMode === "wifi"
                spacing: 6
                Layout.preferredWidth: 300

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "Wi-Fi"
                        opacity: 0.7
                        color: Theme.textColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }
                    }

                    Rectangle {
                        implicitWidth: wifiToggleLabel.implicitWidth + 16
                        implicitHeight: wifiToggleLabel.implicitHeight + 8
                        radius: 4
                        opacity: Networking.wifiHardwareEnabled ? 1 : 0.4
                        color: (Networking.wifiEnabled || wifiToggleHover.hovered) ? Theme.menuItemHoverBg : "transparent"

                        Text {
                            id: wifiToggleLabel
                            anchors.centerIn: parent
                            text: Networking.wifiEnabled ? "On" : "Off"
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                                bold: true
                            }
                        }

                        HoverHandler {
                            id: wifiToggleHover
                            enabled: Networking.wifiHardwareEnabled
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: Networking.wifiHardwareEnabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                        }
                    }
                }

                Text {
                    visible: Connectivity.sortedNetworks.length === 0
                    text: Networking.wifiEnabled ? "No networks found" : "Wi-Fi is off"
                    opacity: 0.6
                    color: Theme.textColor
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 260)
                    visible: Connectivity.sortedNetworks.length > 0
                    clip: true
                    spacing: 2
                    // default Flickable behavior lets wheel-driven flicks
                    // carry past the top/bottom and rubber-band back - stop
                    // dead at the edge instead
                    boundsBehavior: Flickable.StopAtBounds
                    model: Connectivity.sortedNetworks

                    delegate: ColumnLayout {
                        id: netRow
                        required property var modelData

                        readonly property bool expanded: popup.pendingPasswordNetwork === netRow.modelData.name

                        width: ListView.view.width
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: netRowLayout.implicitHeight + 10
                            radius: 4
                            color: netHover.hovered ? Theme.menuItemHoverBg : "transparent"

                            HoverHandler {
                                id: netHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const net = netRow.modelData;
                                    if (net.connected) {
                                        net.disconnect();
                                    } else if (net.known || net.security === WifiSecurityType.Open) {
                                        popup.pendingPasswordNetwork = "";
                                        net.connect();
                                    } else {
                                        popup.pendingPasswordNetwork = netRow.expanded ? "" : net.name;
                                    }
                                }
                            }

                            RowLayout {
                                id: netRowLayout
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 6
                                spacing: 8

                                Text {
                                    text: Connectivity.wifiIcon(netRow.modelData)
                                    color: Theme.textColor
                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: Theme.fontSize
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: netRow.modelData.name
                                    elide: Text.ElideRight
                                    color: Theme.textColor
                                    style: Theme.style
                                    styleColor: Theme.styleColor
                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: Theme.fontSize
                                        bold: netRow.modelData.connected
                                    }
                                }

                                Text {
                                    visible: netRow.modelData.stateChanging
                                    text: "Connecting…"
                                    opacity: 0.6
                                    color: Theme.textColor
                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: Theme.fontSize - 2
                                    }
                                }

                                Text {
                                    visible: netRow.modelData.known && !netRow.modelData.stateChanging
                                    text: "✕"
                                    color: Theme.textColor
                                    opacity: 0.7
                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: Theme.fontSize
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: netRow.modelData.forget()
                                    }
                                }
                            }
                        }

                        // inline password entry for a secured, not-yet-known network
                        RowLayout {
                            visible: netRow.expanded
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: pskInput.implicitHeight + 8
                                radius: 4
                                color: Theme.widgetBg

                                TextInput {
                                    id: pskInput
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    color: Theme.textColor
                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: Theme.fontSize
                                    }

                                    Keys.onReturnPressed: netRow.submitPsk()
                                    Keys.onEnterPressed: netRow.submitPsk()
                                }

                                Text {
                                    anchors.fill: pskInput
                                    verticalAlignment: Text.AlignVCenter
                                    visible: pskInput.text.length === 0
                                    text: "Password"
                                    opacity: 0.4
                                    color: Theme.textColor
                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: Theme.fontSize
                                    }
                                }
                            }

                            Rectangle {
                                implicitWidth: connectLabel.implicitWidth + 16
                                implicitHeight: connectLabel.implicitHeight + 8
                                radius: 4
                                color: connectHover.hovered ? Theme.menuItemHoverBg : "transparent"

                                HoverHandler {
                                    id: connectHover
                                }

                                Text {
                                    id: connectLabel
                                    anchors.centerIn: parent
                                    text: "Connect"
                                    color: Theme.textColor
                                    style: Theme.style
                                    styleColor: Theme.styleColor
                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: Theme.fontSize
                                        bold: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: netRow.submitPsk()
                                }
                            }
                        }

                        function submitPsk() {
                            if (pskInput.text.length === 0)
                                return;
                            netRow.modelData.connectWithPsk(pskInput.text);
                            pskInput.text = "";
                            popup.pendingPasswordNetwork = "";
                        }
                    }
                }
            }

            // --- Bluetooth view ---
            ColumnLayout {
                visible: popup.centerMode === "bluetooth"
                spacing: 6
                Layout.preferredWidth: 300

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "Bluetooth"
                        opacity: 0.7
                        color: Theme.textColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }
                    }

                    Rectangle {
                        visible: Connectivity.btAdapter && Connectivity.btAdapter.enabled
                        implicitWidth: scanLabel.implicitWidth + 16
                        implicitHeight: scanLabel.implicitHeight + 8
                        radius: 4
                        color: (Connectivity.btAdapter && Connectivity.btAdapter.discovering || scanHover.hovered) ? Theme.menuItemHoverBg : "transparent"

                        Text {
                            id: scanLabel
                            anchors.centerIn: parent
                            text: (Connectivity.btAdapter && Connectivity.btAdapter.discovering) ? "Scanning…" : "Scan"
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                            }
                        }

                        HoverHandler {
                            id: scanHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Connectivity.btAdapter.discovering = !Connectivity.btAdapter.discovering
                        }
                    }

                    Rectangle {
                        implicitWidth: btToggleLabel.implicitWidth + 16
                        implicitHeight: btToggleLabel.implicitHeight + 8
                        radius: 4
                        color: ((Connectivity.btAdapter && Connectivity.btAdapter.enabled) || btToggleHover.hovered) ? Theme.menuItemHoverBg : "transparent"

                        Text {
                            id: btToggleLabel
                            anchors.centerIn: parent
                            text: (Connectivity.btAdapter && Connectivity.btAdapter.enabled) ? "On" : "Off"
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                                bold: true
                            }
                        }

                        HoverHandler {
                            id: btToggleHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Connectivity.btAdapter.enabled = !Connectivity.btAdapter.enabled
                        }
                    }
                }

                Text {
                    visible: Connectivity.sortedBtDevices.length === 0
                    text: (Connectivity.btAdapter && Connectivity.btAdapter.enabled) ? "No devices" : "Bluetooth is off"
                    opacity: 0.6
                    color: Theme.textColor
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 260)
                    visible: Connectivity.sortedBtDevices.length > 0
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: Connectivity.sortedBtDevices

                    delegate: Rectangle {
                        id: btRow
                        required property var modelData

                        Layout.fillWidth: true
                        width: ListView.view.width
                        implicitHeight: btRowLayout.implicitHeight + 10
                        radius: 4
                        color: btHover.hovered ? Theme.menuItemHoverBg : "transparent"

                        HoverHandler {
                            id: btHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const dev = btRow.modelData;
                                if (dev.pairing) {
                                    dev.cancelPair();
                                } else if (dev.connected) {
                                    dev.disconnect();
                                } else {
                                    // active discovery shares radio time with
                                    // a freshly established connection and is
                                    // a common cause of an audio device
                                    // connecting then dropping ~1s later -
                                    // stop scanning before pairing/connecting
                                    if (Connectivity.btAdapter)
                                        Connectivity.btAdapter.discovering = false;
                                    if (dev.paired)
                                        dev.connect();
                                    else
                                        dev.pair();
                                }
                            }
                        }

                        RowLayout {
                            id: btRowLayout
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 6
                            spacing: 10

                            Rectangle {
                                implicitWidth: 10
                                implicitHeight: 10
                                radius: 5
                                color: btRow.modelData.connected ? "#3DC24D" : Theme.tooltipBorder
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: btRow.modelData.name
                                    elide: Text.ElideRight
                                    color: Theme.textColor
                                    style: Theme.style
                                    styleColor: Theme.styleColor
                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: Theme.fontSize
                                        bold: btRow.modelData.connected
                                    }
                                }

                                // shown so two entries with the same/similar
                                // name (eg. a headset's audio identity vs its
                                // secondary BLE identity) can be told apart
                                Text {
                                    Layout.fillWidth: true
                                    text: btRow.modelData.address
                                    elide: Text.ElideRight
                                    opacity: 0.45
                                    color: Theme.textColor
                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: Theme.fontSize - 4
                                    }
                                }
                            }

                            Text {
                                visible: btRow.modelData.pairing
                                text: "Pairing…"
                                opacity: 0.6
                                color: Theme.textColor
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize - 2
                                }
                            }

                            Text {
                                visible: btRow.modelData.batteryAvailable
                                // battery is normalized 0-1 per BlueZ's Battery1
                                // percentage as Quickshell reports it elsewhere
                                // (same convention as Pipewire audio volume in
                                // bar/Pipewire.qml) - guard in case it's ever
                                // already 0-100 on some backend
                                text: "· " + Math.round(btRow.modelData.battery > 1 ? btRow.modelData.battery : btRow.modelData.battery * 100) + "%"
                                opacity: 0.6
                                color: Theme.textColor
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize - 2
                                }
                            }

                            Text {
                                visible: btRow.modelData.paired && !btRow.modelData.pairing
                                text: "✕"
                                color: Theme.textColor
                                opacity: 0.7
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: btRow.modelData.forget()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
