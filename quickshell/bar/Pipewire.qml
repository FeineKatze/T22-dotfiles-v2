import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../shared"

Rectangle {
    id: rec

    radius: Theme.barRadius
    color: Theme.widgetBg
    implicitHeight: Theme.barHeight
    implicitWidth: root.implicitWidth + 20

    RowLayout {
        id: root
        spacing: 0
        anchors.centerIn: parent

        property var sink: Pipewire.defaultAudioSink

        // left-click cycles the default sink through these - technical
        // pipewire node names (see `pactl list sinks | grep Name:`), not the
        // human-readable description, so this keeps working across renames.
        // "dual_monitor" and "stereo_split" are virtual sinks, see
        // ~/.config/pipewire/pipewire-pulse.conf.d/20-dual-monitor-sink.conf
        // and 21-stereo-split-sink.conf - the latter's L/R ports are linked
        // one-per-monitor by ~/.local/bin/quickshell-stereo-split-link.sh
        readonly property var toggleSinks: ["alsa_output.usb-MediaTek_Inc_Razer_BlackShark_V2_HS_2.4_0000000000000000-00.analog-stereo", "dual_monitor", "stereo_split"]

        function toggleSink() {
            const i = root.sink ? root.toggleSinks.indexOf(root.sink.name) : -1;
            const targetName = root.toggleSinks[(i + 1) % root.toggleSinks.length];
            const node = Pipewire.nodes.values.find(n => n.isSink && n.name === targetName);
            if (node)
                Pipewire.preferredDefaultAudioSink = node;
        }

        readonly property bool ready: sink && sink.ready
        readonly property bool muted: ready && sink.audio.muted
        readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0

        readonly property string icon: {
            if (!ready) {
                return String.fromCodePoint(0xF075F);
            }
            if (muted)
                return String.fromCodePoint(0xF0581);
            if (vol === 0)
                return String.fromCodePoint(0xF0581);
            if (vol <= 32)
                return String.fromCodePoint(0xF057F);
            if (vol <= 65 && vol > 32)
                return String.fromCodePoint(0xF0580);
            if (vol >= 66)
                return String.fromCodePoint(0xF057E);
        }

        Text {
            text: {
                if (!root.ready)
                    return "-";
                if (root.muted)
                    return "Muted";

                return root.vol + "%";
            }

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
            text: root.icon
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

        PwObjectTracker {
            objects: [root.sink]
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onWheel: event => {
            if (!root.sink)
                return;
            let delta = event.angleDelta.y > 0 ? 0.01 : -0.01;
            root.sink.audio.volume = Math.min(1.0, Math.max(0.0, root.sink.audio.volume + delta));
        }

        onClicked: event => {
            if (event.button === Qt.LeftButton) {
                root.toggleSink();
                return;
            }
            if (root.sink)
                root.sink.audio.muted = !root.sink.audio.muted;
        }
    }

    PopupWindow {
        id: tooltipPopup

        anchor.item: rec
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 30

        implicitWidth: tooltipLabel.implicitWidth + 16
        implicitHeight: tooltipLabel.implicitHeight + 10
        color: "transparent"

        visible: mouseArea.containsMouse

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
                    bold: true
                    family: Theme.fontFamily
                    pointSize: Theme.pointSize
                }
                text: root.sink && root.sink.name ? root.sink.name : ""
            }
        }
    }
}
