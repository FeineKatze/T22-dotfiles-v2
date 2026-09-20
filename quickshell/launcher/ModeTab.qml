import QtQuick
import QtQuick.Layouts
import "../shared"

// One icon-only, purely informative side-tab indicating a Launcher mode.
// Rounded only on its outer edge (away from the launcher body) - "left" for
// the left-side column, "right" for the right-side one.
Rectangle {
    id: modeTab

    required property string modelData
    required property string side // "left" | "right"
    required property real size

    readonly property bool active: Launcher.mode === modelData

    implicitWidth: size
    implicitHeight: size
    topLeftRadius: side === "left" ? Theme.tooltipRadius : 0
    bottomLeftRadius: side === "left" ? Theme.tooltipRadius : 0
    topRightRadius: side === "right" ? Theme.tooltipRadius : 0
    bottomRightRadius: side === "right" ? Theme.tooltipRadius : 0
    color: modeTab.active ? Theme.menuItemHoverBg : Theme.tooltipBg
    border.color: Theme.tooltipBorder
    border.width: Theme.tooltipBorderWidth

    Text {
        anchors.centerIn: parent
        opacity: modeTab.active ? 1 : 0.4
        text: Launcher.modeGlyphs[modeTab.modelData] ?? "?"
        color: Theme.textColor
        style: Theme.style
        styleColor: Theme.styleColor

        font {
            family: Theme.fontFamily
            pixelSize: Theme.fontSize
        }
    }
}
