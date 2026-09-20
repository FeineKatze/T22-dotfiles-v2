pragma Singleton
import QtQuick

QtObject {
    readonly property int barRadius: 10
    readonly property int barHeight: 35

    readonly property color barBg: Qt.rgba(0.1686, 0.1882, 0.2314, 0.75)
    readonly property color widgetBg: Qt.rgba(0.0353, 0.0431, 0.0627, 0.75)
    readonly property color pillBg: "#c0090b10"

    readonly property color menuItemHoverBg: Qt.rgba(1.0, 1.0, 1.0, 0.12)

    readonly property color tooltipBg: "#e9090b10"
    readonly property color tooltipBorder: "#e94b4b4b"
    readonly property int tooltipBorderWidth: 1
    readonly property int tooltipRadius: 6

    readonly property color textColor: "#B0E0E6"

    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 15
    readonly property double pointSize: 13
    readonly property bool fontBold: true
    readonly property var style: Text.Raised
    readonly property color styleColor: "#000000"

    readonly property color wsDefaultBg: Qt.rgba(0.2941, 0.2941, 0.2941, 0.3)
    readonly property color wsUrgentBg: Qt.rgba(0.9216, 0.3020, 0.2941, 1.0)
    readonly property color wsHoverBg: Qt.rgba(0.8824, 0.8824, 0.8824, 0.2)
    readonly property color wsActiveBg: widgetBg
    readonly property color wsHasWindowBg: Qt.rgba(0.0, 0.0, 0.0, 0.3)
}
