pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth

// Shared Wi-Fi/Bluetooth state for the bar's Network module and its
// click-to-open panel (network/NetworkCenter.qml) - one place doing the
// device lookups/sorting so neither has to duplicate them.
QtObject {
    id: root

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired)

    readonly property var activeWifi: root.wifiDevice ? root.wifiDevice.networks.values.find(n => n.connected) : null
    readonly property bool wiredConnected: !!(root.wiredDevice && root.wiredDevice.connected)

    readonly property string label: {
        if (root.activeWifi)
            return root.activeWifi.name;
        if (root.wiredConnected)
            return "Ethernet";
        return "Offline";
    }

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property var btConnectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property bool btActive: root.btConnectedDevices.length > 0

    // connected first, then already-known, then by signal strength - blank
    // SSIDs (hidden networks broadcasting no name) are dropped, nothing
    // useful to show/click for those
    readonly property var sortedNetworks: {
        if (!root.wifiDevice)
            return [];
        const nets = root.wifiDevice.networks.values.filter(n => n.name.length > 0);
        return nets.slice().sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.known !== b.known)
                return a.known ? -1 : 1;
            return b.signalStrength - a.signalStrength;
        });
    }

    // connected first, then paired, then discovered-but-unpaired
    readonly property var sortedBtDevices: {
        const devs = Bluetooth.devices.values;
        return devs.slice().sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
    }

    // signal-strength glyph for a WifiNetwork - locked variant when secured,
    // "off" glyph when Wi-Fi itself is disabled
    function wifiIcon(network) {
        if (!Networking.wifiEnabled)
            return String.fromCodePoint(0xF092D);
        const locked = network.security !== WifiSecurityType.Open;
        const s = network.signalStrength;
        if (s >= 75)
            return String.fromCodePoint(locked ? 0xF092A : 0xF0928);
        if (s >= 50)
            return String.fromCodePoint(locked ? 0xF0927 : 0xF0925);
        if (s >= 25)
            return String.fromCodePoint(locked ? 0xF0924 : 0xF0922);
        return String.fromCodePoint(locked ? 0xF0921 : 0xF091F);
    }
}
