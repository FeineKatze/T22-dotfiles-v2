pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Networking

QtObject {
    id: root

    property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink && sink.ready
    readonly property bool muted: ready && sink.audio.muted
    readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0

    property var networkDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired)
    property var networkActive: networkDevice ? networkDevice.networks.values.find(n => n.connected) : null
    readonly property bool networkConnected: !!networkActive

    // currently displayed content - set by showVolume()/showNetwork(),
    // whichever event fired most recently
    property string icon: ""
    property string label: ""

    property bool visible: false

    // ignore the very first volume/mute/network report after startup, since
    // that's state becoming ready, not an actual user-driven change
    property bool armed: false

    property Timer armTimer: Timer {
        interval: 1000
        running: true
        onTriggered: root.armed = true
    }

    property Timer hideTimer: Timer {
        interval: 1500
        onTriggered: root.visible = false
    }

    function show() {
        root.visible = true;
        root.hideTimer.restart();
    }

    function showVolume() {
        if (!root.ready) {
            root.icon = String.fromCodePoint(0xF075F);
            root.label = "-";
        } else if (root.muted || root.vol === 0) {
            root.icon = String.fromCodePoint(0xF0581);
            root.label = root.muted ? "Muted" : root.vol + "%";
        } else if (root.vol <= 32) {
            root.icon = String.fromCodePoint(0xF057F);
            root.label = root.vol + "%";
        } else if (root.vol <= 65) {
            root.icon = String.fromCodePoint(0xF0580);
            root.label = root.vol + "%";
        } else {
            root.icon = String.fromCodePoint(0xF057E);
            root.label = root.vol + "%";
        }
        root.show();
    }

    // no icon for network events, just the text, per request
    function showNetwork() {
        root.icon = "";
        root.label = root.networkConnected ? "Connected" : "Disconnected";
        root.show();
    }

    onVolChanged: if (root.armed)
        root.showVolume()
    onMutedChanged: if (root.armed)
        root.showVolume()
    onNetworkConnectedChanged: if (root.armed)
        root.showNetwork()

    property PwObjectTracker tracker: PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
