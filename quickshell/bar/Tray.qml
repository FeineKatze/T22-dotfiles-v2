import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../shared"

Rectangle {
    id: trayRoot

    // ADD THIS: Require the parent window to be passed in
    required property var trayWindow

    Layout.alignment: Qt.AlignVCenter
    implicitHeight: Theme.barHeight
    implicitWidth: trayLayout.implicitWidth + 26

    radius: Theme.barRadius
    color: Theme.widgetBg

    visible: SystemTray.items.values.length > 0

    RowLayout {
        id: trayLayout
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items

            Item {
                id: itemWrapper
                required property SystemTrayItem modelData
                property real lastClickX: 0
                property real lastClickY: 0
                property bool menuOpen: false

                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                    anchors.fill: parent
                    source: itemWrapper.modelData.icon
                }

                HoverHandler {
                    id: hoverHandler
                }

                PopupWindow {
                    id: tooltipPopup

                    anchor.item: itemWrapper
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                    anchor.margins.top: 6

                    implicitWidth: tooltipLabel.implicitWidth + 20
                    implicitHeight: tooltipLabel.implicitHeight + 14
                    color: "transparent"

                    visible: hoverHandler.hovered

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.barRadius
                        color: Theme.tooltipBg
                        border.color: Theme.tooltipBorder
                        border.width: Theme.tooltipBorderWidth

                        Text {
                            id: tooltipLabel
                            anchors.centerIn: parent
                            text: itemWrapper.modelData.title || itemWrapper.modelData.tooltipTitle || itemWrapper.modelData.id
                            color: Theme.textColor
                            style: Theme.style
                            styleColor: Theme.styleColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                                bold: Theme.fontBold
                            }
                        }
                    }
                }
                // --- Original native-styled menu (anchored to the icon's top-left corner,
                // spawned via QsMenuAnchor.open()). Kept here commented out so it's easy to
                // swap back: comment out the QsMenuOpener/PopupWindow block below, uncomment
                // this, and change the RightButton handler in the MouseArea back to
                // `menuAnchor.open()`.
                // FIX IS HERE: Bind anchor.window to the passed property
                // QsMenuAnchor {
                //     id: menuAnchor
                //     menu: itemWrapper.modelData.menu
                //     anchor.window: trayRoot.trayWindow
                //     anchor.rect: Qt.rect(0, 0, itemWrapper.width, itemWrapper.height)
                // }

                // --- Custom-styled menu, spawned at the click position ---
                QsMenuOpener {
                    id: menuOpener
                    menu: itemWrapper.modelData.menu
                }

                HyprlandFocusGrab {
                    id: menuGrab
                    windows: [contextMenuPopup]
                    active: itemWrapper.menuOpen
                    onCleared: itemWrapper.menuOpen = false
                }

                PopupWindow {
                    id: contextMenuPopup

                    anchor.item: itemWrapper
                    anchor.rect: Qt.rect(itemWrapper.lastClickX, itemWrapper.lastClickY, 1, 1)
                    anchor.edges: Edges.Bottom | Edges.Right
                    anchor.gravity: Edges.Bottom | Edges.Right

                    implicitWidth: menuColumn.implicitWidth + 12
                    implicitHeight: menuColumn.implicitHeight + 10
                    color: "transparent"

                    visible: itemWrapper.menuOpen

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.tooltipRadius
                        color: Theme.tooltipBg
                        border.color: Theme.tooltipBorder
                        border.width: Theme.tooltipBorderWidth

                        ColumnLayout {
                            id: menuColumn
                            anchors.centerIn: parent
                            spacing: 1

                            Repeater {
                                model: menuOpener.children

                                Item {
                                    id: entryItem
                                    required property QsMenuEntry modelData

                                    Layout.fillWidth: true
                                    implicitWidth: Math.max(entryLabel.implicitWidth + 20, 100)
                                    implicitHeight: entryItem.modelData.isSeparator ? 7 : (entryLabel.implicitHeight + 8)

                                    // separator line
                                    Rectangle {
                                        visible: entryItem.modelData.isSeparator
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: 4
                                        height: 1
                                        color: Theme.tooltipBorder
                                    }

                                    // normal entry row
                                    Rectangle {
                                        visible: !entryItem.modelData.isSeparator
                                        anchors.fill: parent
                                        radius: 4
                                        color: entryHover.hovered ? Theme.menuItemHoverBg : "transparent"

                                        Text {
                                            id: entryLabel
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 8
                                            anchors.right: parent.right
                                            anchors.rightMargin: 8
                                            text: (entryItem.modelData.buttonType === QsMenuButtonType.CheckBox && entryItem.modelData.checkState === Qt.Checked ? "✓ " : "") + entryItem.modelData.text
                                            opacity: entryItem.modelData.enabled ? 1.0 : 0.4
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
                                            id: entryHover
                                            enabled: !entryItem.modelData.isSeparator && entryItem.modelData.enabled
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !entryItem.modelData.isSeparator && entryItem.modelData.enabled
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                entryItem.modelData.triggered();
                                                itemWrapper.menuOpen = false;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: itemMouseArea

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            itemWrapper.modelData.activate();
                        } else if (mouse.button === Qt.MiddleButton) {
                            itemWrapper.modelData.secondaryActivate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (itemWrapper.modelData.hasMenu) {
                                if (!itemWrapper.menuOpen) {
                                    itemWrapper.lastClickX = mouse.x;
                                    itemWrapper.lastClickY = mouse.y;
                                }
                                itemWrapper.menuOpen = !itemWrapper.menuOpen;
                            }
                        }
                    }
                }
            }
        }
    }
}
