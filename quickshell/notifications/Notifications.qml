pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property bool muted: false
    property bool centerVisible: false

    property var popupEntries: []
    property var historyEntries: []

    readonly property int historyLimit: 50
    readonly property int defaultTimeout: 5000

    property int _localIdCounter: -1

    // for locally-generated entries (e.g. alarms) with no backing DBus Notification
    function notifyLocal(appName, summary, body, urgency) {
        const entry = {
            id: root._localIdCounter--,
            appName: appName,
            appIcon: "",
            summary: summary,
            body: body,
            urgency: urgency ?? NotificationUrgency.Normal,
            image: "",
            expireTimeout: -1,
            time: new Date(),
            notif: null
        };

        root.historyEntries = [entry, ...root.historyEntries].slice(0, root.historyLimit);
        root.popupEntries = [entry, ...root.popupEntries];
    }

    function makeEntry(notification) {
        return {
            id: notification.id,
            appName: notification.appName,
            appIcon: notification.appIcon,
            summary: notification.summary,
            body: notification.body,
            urgency: notification.urgency,
            image: notification.image,
            expireTimeout: notification.expireTimeout,
            time: new Date(),
            notif: notification
        };
    }

    property NotificationServer server: NotificationServer {
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const entry = root.makeEntry(notification);
            root.historyEntries = [entry, ...root.historyEntries].slice(0, root.historyLimit);

            if (!root.muted)
                root.popupEntries = [entry, ...root.popupEntries];

            notification.closed.connect(reason => {
                root.popupEntries = root.popupEntries.filter(e => e.id !== notification.id);
            });
        }
    }

    // called by the popup's own timeout timer
    function expirePopup(id) {
        const entry = root.popupEntries.find(e => e.id === id);
        if (entry && entry.notif)
            entry.notif.expire();
        root.popupEntries = root.popupEntries.filter(e => e.id !== id);
    }

    // called on left-click; an explicit dismiss means it's been seen, so drop it from history too
    function dismissPopup(id) {
        const entry = root.popupEntries.find(e => e.id === id);
        if (entry && entry.notif)
            entry.notif.dismiss();
        root.popupEntries = root.popupEntries.filter(e => e.id !== id);
        root.historyEntries = root.historyEntries.filter(e => e.id !== id);
    }

    function dismissHistory(id) {
        root.historyEntries = root.historyEntries.filter(e => e.id !== id);
    }

    function clearHistory() {
        root.historyEntries = [];
    }

    function toggleCenter() {
        root.centerVisible = !root.centerVisible;
    }

    function toggleMute() {
        root.muted = !root.muted;
    }
}
