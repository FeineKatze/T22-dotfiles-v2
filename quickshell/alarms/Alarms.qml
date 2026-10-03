pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../notifications"

QtObject {
    id: root

    property string centerMode: "alarms" // "alarms" | "timers" | "appointments" | "settings"

    property var alarms: [] // {id, label, hour, minute, type: "once"|"weekly", date, weekdays, enabled}
    property var timers: [] // {id, label, endTime}

    // {id, name, color, startDate: "YYYY-MM-DD", startTime: "HH:MM"|null,
    //  endDate: "YYYY-MM-DD"|null, endTime: "HH:MM"|null} - endDate null or
    // equal to startDate means a single-day event. Nothing writes to this
    // yet (the Termine tab's editor isn't built); bar/Clock.qml's "Upcoming"
    // tooltip page already reads it.
    property var appointments: []

    // set via the Upcoming list's right-click-to-edit hook
    // (bar/Clock.qml), appointments only (not the read-only holiday
    // lists) - captures which appointment to edit and switches to the
    // Termine tab. Just the entry point for now; the actual edit UI comes
    // with the appointments editor
    property var editingAppointmentId: null

    function editAppointment(id) {
        root.editingAppointmentId = id;
        root.centerMode = "appointments";
    }

    // same shape as appointments - Bavarian public holidays (Feiertage) and
    // school holidays (Ferien), loaded from plain JSON files (converted
    // once from feiertage-deutschland.de / feiertage-api.de ICS/API data -
    // see germanHolidaysFile/germanSchoolHolidaysFile below). Re-generate
    // those JSON files directly to refresh; no script/API call happens here
    // at runtime.
    property var germanHolidays: []
    property var germanSchoolHolidays: []

    property Process icsDirProcess: Process {
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/share/quickshell/ics"]
        running: true
        onExited: running = false
    }

    property FileView germanHolidaysFile: FileView {
        id: germanHolidaysFile
        path: Quickshell.env("HOME") + "/.local/share/quickshell/ics/bayern_feiertage.json"
        watchChanges: true
        printErrors: true
        onLoaded: {
            try {
                root.germanHolidays = JSON.parse(germanHolidaysFile.text());
            } catch (e) {
                root.germanHolidays = [];
            }
        }
        onLoadFailed: error => {
            root.germanHolidays = [];
        }
        onFileChanged: germanHolidaysFile.reload()
    }

    property FileView germanSchoolHolidaysFile: FileView {
        id: germanSchoolHolidaysFile
        path: Quickshell.env("HOME") + "/.local/share/quickshell/ics/bayern_schulferien.json"
        watchChanges: true
        printErrors: true
        onLoaded: {
            try {
                root.germanSchoolHolidays = JSON.parse(germanSchoolHolidaysFile.text());
            } catch (e) {
                root.germanSchoolHolidays = [];
            }
        }
        onLoadFailed: error => {
            root.germanSchoolHolidays = [];
        }
        onFileChanged: germanSchoolHolidaysFile.reload()
    }

    // calendar display settings, persisted below alongside alarms
    property bool showWeekendColors: true
    property bool showAppointments: true
    property bool showGermanHolidays: true
    property bool showGermanSchoolHolidays: true

    function toggleShowWeekendColors() {
        root.showWeekendColors = !root.showWeekendColors;
        root._persistSettings();
    }

    function toggleShowAppointments() {
        root.showAppointments = !root.showAppointments;
        root._persistSettings();
    }

    function toggleShowGermanHolidays() {
        root.showGermanHolidays = !root.showGermanHolidays;
        root._persistSettings();
    }

    function toggleShowGermanSchoolHolidays() {
        root.showGermanSchoolHolidays = !root.showGermanSchoolHolidays;
        root._persistSettings();
    }

    function _persistSettings() {
        adapter.showWeekendColors = root.showWeekendColors;
        adapter.showAppointments = root.showAppointments;
        adapter.showGermanHolidays = root.showGermanHolidays;
        adapter.showGermanSchoolHolidays = root.showGermanSchoolHolidays;
        root.fileView.writeAdapter();
    }

    property double now: Date.now() // ticks every second while timers are running, drives countdown UI

    property var _pendingFireIds: []

    function mondayIndex(date) {
        return (date.getDay() + 6) % 7;
    }

    function nextTrigger(alarm, from) {
        if (alarm.type === "once") {
            const parts = alarm.date.split("-").map(Number);
            const dt = new Date(parts[0], parts[1] - 1, parts[2], alarm.hour, alarm.minute, 0, 0);
            return dt.getTime() > from.getTime() ? dt : null;
        }

        for (let offset = 0; offset <= 7; offset++) {
            const candidate = new Date(from);
            candidate.setDate(candidate.getDate() + offset);
            candidate.setHours(alarm.hour, alarm.minute, 0, 0);
            if (alarm.weekdays.includes(root.mondayIndex(candidate)) && candidate.getTime() > from.getTime())
                return candidate;
        }
        return null;
    }

    function _rescheduleAlarms() {
        const nowDate = new Date();
        let soonestTime = null;
        let soonestIds = [];

        for (const alarm of root.alarms) {
            if (!alarm.enabled)
                continue;
            const t = root.nextTrigger(alarm, nowDate);
            if (!t)
                continue;
            if (soonestTime === null || t.getTime() < soonestTime.getTime()) {
                soonestTime = t;
                soonestIds = [alarm.id];
            } else if (t.getTime() === soonestTime.getTime()) {
                soonestIds.push(alarm.id);
            }
        }

        root.schedulerTimer.stop();
        root._pendingFireIds = soonestIds;
        if (soonestTime) {
            root.schedulerTimer.interval = Math.max(0, soonestTime.getTime() - nowDate.getTime());
            root.schedulerTimer.start();
        }
    }

    function _onSchedulerTriggered() {
        const ids = root._pendingFireIds;
        root._pendingFireIds = [];
        for (const id of ids) {
            const alarm = root.alarms.find(a => a.id === id);
            if (alarm)
                root.fireAlarm(alarm);
        }
        root._rescheduleAlarms();
    }

    function fireAlarm(alarm) {
        root._playSound();
        Notifications.notifyLocal("Alarm", alarm.label.length > 0 ? alarm.label : "Alarm", "Alarm fired", NotificationUrgency.Critical);

        if (alarm.type === "once")
            root.removeAlarm(alarm.id);
    }

    function fireTimer(timer) {
        root._playSound();
        Notifications.notifyLocal("Timer", timer.label.length > 0 ? timer.label : "Timer", "Timer finished", NotificationUrgency.Normal);
    }

    function _tickTimers() {
        root.now = Date.now();
        const due = root.timers.filter(t => t.endTime <= root.now);
        if (due.length > 0) {
            root.timers = root.timers.filter(t => t.endTime > root.now);
            for (const t of due)
                root.fireTimer(t);
        }
    }

    function _persist() {
        adapter.alarms = root.alarms;
        root.fileView.writeAdapter();
    }

    function addAlarm(label, hour, minute, type, date, weekdays) {
        const alarm = {
            id: Date.now(),
            label: label ?? "",
            hour: hour,
            minute: minute,
            type: type,
            date: date ?? "",
            weekdays: weekdays ?? [],
            enabled: true
        };
        root.alarms = [...root.alarms, alarm];
        root._persist();
        root._rescheduleAlarms();
    }

    function removeAlarm(id) {
        root.alarms = root.alarms.filter(a => a.id !== id);
        root._persist();
        root._rescheduleAlarms();
    }

    function toggleAlarm(id) {
        root.alarms = root.alarms.map(a => a.id === id ? Object.assign({}, a, {
            enabled: !a.enabled
        }) : a);
        root._persist();
        root._rescheduleAlarms();
    }

    function addTimer(minutes, label) {
        root.now = Date.now();
        const timer = {
            id: Date.now() + Math.floor(Math.random() * 1000),
            label: label ?? "",
            endTime: root.now + minutes * 60000
        };
        root.timers = [...root.timers, timer];
    }

    function cancelTimer(id) {
        root.timers = root.timers.filter(t => t.id !== id);
    }

    property Timer schedulerTimer: Timer {
        id: schedulerTimer
        repeat: false
        onTriggered: root._onSchedulerTriggered()
    }

    property Timer tickTimer: Timer {
        id: tickTimer
        interval: 1000
        repeat: true
        running: root.timers.length > 0
        onTriggered: root._tickTimers()
    }

    property Process soundProcess: Process {
        id: soundProcess
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"]
        onExited: running = false
    }

    function _playSound() {
        soundProcess.running = true;
    }

    property Process mkdirProcess: Process {
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/quickshell"]
        running: true
        onExited: running = false
    }

    property FileView fileView: FileView {
        id: fileView
        path: Quickshell.env("HOME") + "/.local/state/quickshell/alarms.json"
        watchChanges: true
        blockWrites: false
        printErrors: true

        adapter: JsonAdapter {
            id: adapter
            property var alarms: []
            property bool showWeekendColors: true
            property bool showAppointments: true
            property bool showGermanHolidays: true
            property bool showGermanSchoolHolidays: true
        }

        onLoaded: {
            root.alarms = adapter.alarms ?? [];
            root.showWeekendColors = adapter.showWeekendColors ?? true;
            root.showAppointments = adapter.showAppointments ?? true;
            root.showGermanHolidays = adapter.showGermanHolidays ?? true;
            root.showGermanSchoolHolidays = adapter.showGermanSchoolHolidays ?? true;
            root._rescheduleAlarms();
        }
        onLoadFailed: error => {
            root.alarms = [];
        }
    }
}
