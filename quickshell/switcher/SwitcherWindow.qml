import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../shared"

PanelWindow {
    id: switcherWindow
    // screen is supplied by the Variants loop in shell.qml (one instance per
    // monitor) - which of these instances is actually visible is decided
    // below, per Switcher.displayMode

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-switcher"

    visible: Switcher.visible && (Switcher.displayMode === "all" || (Switcher.displayMode === "focused" && screen && screen.name === Switcher.targetScreenName) || (Switcher.displayMode === "primary" && screen && screen.name === Switcher.primaryScreenName))

    exclusiveZone: 0
    color: "transparent"

    implicitWidth: mainColumn.implicitWidth + 32
    implicitHeight: mainColumn.implicitHeight + 32

    // the focus grab is centralized in shell.qml (covering every monitor's
    // instance at once) - see the comment there for why: one grab per
    // instance would mean multiple simultaneous global grabs when
    // displayMode is "all", which they'd fight each other over

    Item {
        anchors.fill: parent

        // no window-wide background per design - just the row of tiles and
        // a title line, floating over the desktop
        focus: true

        Keys.onPressed: event => {
            if (Switcher.handleKey(event.key, event.modifiers))
                event.accepted = true;
        }

        ColumnLayout {
            id: mainColumn
            anchors.centerIn: parent
            spacing: 10

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                // fixed-width, opacity-only toggling (not visible:) so
                // appearing/disappearing doesn't shift the row's width and
                // make the window jitter horizontally as you scroll
                Text {
                    text: "◀"
                    opacity: Switcher.scrollOffset > 0 ? 0.7 : 0
                    color: Theme.textColor
                    style: Theme.style
                    styleColor: Theme.styleColor
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                        bold: true
                    }
                }

                RowLayout {
                    id: tileRow
                    spacing: 8

                    Repeater {
                        model: Switcher.visibleWindows

                        SwitcherTile {
                            required property var modelData

                            toplevel: modelData
                        }
                    }
                }

                Text {
                    text: "▶"
                    opacity: (Switcher.scrollOffset + Switcher.columns < Switcher.windows.length) ? 0.7 : 0
                    color: Theme.textColor
                    style: Theme.style
                    styleColor: Theme.styleColor
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                        bold: true
                    }
                }
            }

            Text {
                id: titleText
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: tileRow.width
                // fixed height (not the implicit content height) so glyphs
                // with taller natural line metrics (eg. CJK) don't nudge
                // the tile row up/down when the title changes
                Layout.preferredHeight: fontMetrics.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: Switcher.windows[Switcher.selectedIndex]?.title ?? ""
                color: Theme.textColor
                style: Theme.style
                styleColor: Theme.styleColor
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                    bold: true
                }

                FontMetrics {
                    id: fontMetrics
                    font: titleText.font
                }
            }
        }
    }
}
