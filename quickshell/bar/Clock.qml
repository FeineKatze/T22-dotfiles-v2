import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../shared"
import "../alarms"

Rectangle {
    id: rec

    implicitHeight: Theme.barHeight
    implicitWidth: 190
    radius: Theme.barRadius
    color: Theme.widgetBg

    readonly property var weekdayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property int cellSize: 18
    readonly property int miniCellSize: 14

    // Upcoming page footprint - wider than the month grid so a full date
    // range (eg "Mo 24.12.26 - Di 06.01.27") fits on one line; height is an
    // estimate of 4 two-line event blocks (date line + name line + a
    // separator, minus one separator since the first entry has none) -
    // nudge if it's a bit off, it's still scrollable either way
    readonly property int upcomingWidth: 210
    readonly property int upcomingRowHeight: 44

    property string calendarMode: "month"
    property int viewMonth: new Date().getMonth()
    property int viewYear: new Date().getFullYear()
    property bool alarmsOpen: false

    // debounced hover-open state for calendarPopup - see the visible:
    // binding on calendarPopup below for why this can't just be
    // mouseArea.containsMouse || calendarPopupHover.hovered directly
    readonly property bool calendarWantsOpen: (mouseArea.containsMouse || calendarPopupHover.hovered) && !rec.alarmsOpen
    property bool calendarActuallyOpen: false

    onCalendarWantsOpenChanged: {
        if (rec.calendarWantsOpen) {
            calendarCloseTimer.stop();
            rec.calendarActuallyOpen = true;
        } else {
            calendarCloseTimer.restart();
        }
    }

    Timer {
        id: calendarCloseTimer
        interval: 150
        onTriggered: rec.calendarActuallyOpen = false
    }

    // weekend tinting - Sunday a bit more saturated than Saturday, both
    // desaturated red so they read as a quiet hint, not an alert. Gated by
    // Alarms.showWeekendColors (Settings screen).
    readonly property color sundayColor: Qt.hsla(0.0, 0.50, 0.60, 1.0)
    readonly property color saturdayColor: Qt.hsla(0.0, 0.30, 0.60, 1.0)

    // filter palette for the Upcoming list's toggle dots - [0]/[1] are the
    // existing Feiertage/Ferien grid highlighting colors (taken from the
    // Samsung Calendar app's own palette), [2]-[5] are unassigned
    // placeholders reserved for future event categories (eg. once the
    // appointments editor lets you pick a color)
    readonly property var filterColors: ["#086535", "#9D1248", "#3B82F6", "#F59E0B", "#8B5CF6", "#14B8A6"]

    // per-color on/off state for the Upcoming list filter dots, same
    // indices as filterColors - all on by default. Reassigned wholesale
    // (not mutated in place) since QML property bindings don't pick up
    // in-place array mutation
    property var filterActive: [true, true, true, true, true, true]

    function toggleFilter(i) {
        let arr = rec.filterActive.slice();
        arr[i] = !arr[i];
        rec.filterActive = arr;
    }

    // per-day custom colors, keyed by "YYYY-MM-DD" - empty until the
    // day-coloring popup (not built yet) starts writing to this
    property var customDayColors: ({})

    function dateInRange(dateKey, event) {
        const end = event.endDate ?? event.startDate;
        return dateKey >= event.startDate && dateKey <= end;
    }

    // Feiertage take priority over Ferien when both cover the same day
    // (a single-day public holiday landing inside a school break, say)
    function holidayColorFor(dateKey) {
        if (Alarms.showGermanHolidays) {
            const h = Alarms.germanHolidays.find(e => rec.dateInRange(dateKey, e));
            if (h)
                return h.color ?? rec.filterColors[0];
        }
        if (Alarms.showGermanSchoolHolidays) {
            const f = Alarms.germanSchoolHolidays.find(e => rec.dateInRange(dateKey, e));
            if (f)
                return f.color ?? rec.filterColors[1];
        }
        return null;
    }

    // same precedence as holidayColorFor, plus personal appointments last -
    // used for the day-cell hover tooltip/underline below
    function eventForDate(dateKey) {
        if (Alarms.showGermanHolidays) {
            const h = Alarms.germanHolidays.find(e => rec.dateInRange(dateKey, e));
            if (h)
                return h;
        }
        if (Alarms.showGermanSchoolHolidays) {
            const f = Alarms.germanSchoolHolidays.find(e => rec.dateInRange(dateKey, e));
            if (f)
                return f;
        }
        if (Alarms.showAppointments) {
            const a = Alarms.appointments.find(e => rec.dateInRange(dateKey, e));
            if (a)
                return a;
        }
        return null;
    }

    // set by whichever day cell (month or year grid) is currently hovered;
    // "" when none. hoveredEvent derives the actual event so a single-day
    // hover only underlines that day, but a holiday hover underlines its
    // whole range (dateInRange naturally covers both cases)
    property string hoveredDateKey: ""
    readonly property var hoveredEvent: rec.hoveredDateKey.length > 0 ? rec.eventForDate(rec.hoveredDateKey) : null

    // priority: an explicit custom color > today's highlight > a holiday >
    // weekend tint > normal text
    function dayColor(cell) {
        const custom = rec.customDayColors[cell.dateKey];
        if (custom)
            return custom;
        if (cell.today)
            return "#00fff7";
        const holiday = rec.holidayColorFor(cell.dateKey);
        if (holiday)
            return holiday;
        if (Alarms.showWeekendColors) {
            if (cell.dow === 6)
                return rec.sundayColor;
            if (cell.dow === 5)
                return rec.saturdayColor;
        }
        return Theme.textColor;
    }

    // same weekend tint for the "Mo Tu We Th Fr Sa Su" header row - dow
    // convention matches weekdayNames' own order (0=Mo ... 6=Su)
    function weekdayHeaderColor(dow) {
        if (Alarms.showWeekendColors) {
            if (dow === 6)
                return rec.sundayColor;
            if (dow === 5)
                return rec.saturdayColor;
        }
        return Theme.textColor;
    }

    // shared by the bar widget's own wheel handler and the popup's (below)
    // so scrolling works whether the mouse is over the bar or the tooltip.
    // No-op in "upcoming" mode - same reasoning as the click handler not
    // touching month/year there.
    function handleCalendarWheel(angleDeltaY) {
        if (rec.calendarMode === "upcoming")
            return;
        let delta = angleDeltaY < 0 ? 1 : -1;
        if (rec.calendarMode === "year")
            rec.viewYear += delta;
        else
            rec.shiftMonth(delta);
    }

    // "Mo dd.MM.yy" for a single-day event, "Mo dd.MM.yy - Di dd.MM.yy" for
    // a range (eg. a Ferien week) - weekday abbreviation reuses
    // weekdayNames (same Monday-first order as the header row)
    function formatEventDate(event) {
        function fmt(dateStr) {
            const d = new Date(dateStr);
            const dow = rec.weekdayNames[(d.getDay() + 6) % 7];
            return dow + " " + Qt.formatDate(d, "dd.MM.yy");
        }
        if (event.endDate && event.endDate !== event.startDate)
            return fmt(event.startDate) + " - " + fmt(event.endDate);
        return fmt(event.startDate);
    }

    function shiftMonth(delta) {
        let m = rec.viewMonth + delta;
        let y = rec.viewYear;
        if (m < 0) {
            m = 11;
            y -= 1;
        } else if (m > 11) {
            m = 0;
            y += 1;
        }
        rec.viewMonth = m;
        rec.viewYear = y;
    }

    // Monday-first day cells for one month, 42 entries (6 weeks x 7 days).
    // Overflow cells (prev/next month) carry their own real date too, not
    // just a day number, so weekday tinting and custom colors are correct
    // for them as well.
    function monthCells(year, month) {
        let firstIdx = (new Date(year, month, 1).getDay() + 6) % 7;
        let numDays = new Date(year, month + 1, 0).getDate();
        let prevNumDays = new Date(year, month, 0).getDate();
        let today = new Date();

        function makeCell(y, m, d, current) {
            let dow = (new Date(y, m, d).getDay() + 6) % 7; // 0=Mo ... 6=Su
            let isToday = current && today.getFullYear() === y && today.getMonth() === m && today.getDate() === d;
            return {
                day: d,
                current: current,
                today: isToday,
                dow: dow,
                dateKey: y + "-" + String(m + 1).padStart(2, "0") + "-" + String(d).padStart(2, "0")
            };
        }

        let prevMonth = month - 1, prevYear = year;
        if (prevMonth < 0) {
            prevMonth = 11;
            prevYear -= 1;
        }
        let nextMonth = month + 1, nextYear = year;
        if (nextMonth > 11) {
            nextMonth = 0;
            nextYear += 1;
        }

        let cells = [];
        for (let i = 0; i < firstIdx; i++)
            cells.push(makeCell(prevYear, prevMonth, prevNumDays - firstIdx + 1 + i, false));
        for (let d = 1; d <= numDays; d++)
            cells.push(makeCell(year, month, d, true));
        let nextDay = 1;
        while (cells.length < 42)
            cells.push(makeCell(nextYear, nextMonth, nextDay++, false));
        return cells;
    }

    readonly property var currentMonthCells: monthCells(viewYear, viewMonth)

    // right-click cycle order for the hover tooltip's calendarMode
    readonly property var calendarModes: ["month", "upcoming", "year"]

    // Alarms.appointments + germanHolidays + germanSchoolHolidays (each
    // gated by its own Settings toggle), filtered to events that haven't
    // fully ended yet, soonest first; same-start ties prefer single-day
    // events over multi-day ones (eg. holidays) so a long-running holiday
    // doesn't bury a same-day single appointment
    readonly property var upcomingEvents: {
        const nowMs = Date.now();
        // resolve each source's own fallback color here (eg. a Feiertag
        // with no explicit color) - once merged there's no way to tell
        // which list an event came from, so this has to happen before that
        let combined = [];
        if (Alarms.showAppointments)
            combined = combined.concat(Alarms.appointments);
        if (Alarms.showGermanHolidays)
            combined = combined.concat(Alarms.germanHolidays.map(e => Object.assign({}, e, {
                    color: e.color ?? rec.filterColors[0]
                })));
        if (Alarms.showGermanSchoolHolidays)
            combined = combined.concat(Alarms.germanSchoolHolidays.map(e => Object.assign({}, e, {
                    color: e.color ?? rec.filterColors[1]
                })));

        // filter dots: an event whose color matches one of the 6 filter
        // slots is hidden while that slot is toggled off; an event with an
        // unrecognized color (eg. a future custom appointment color not in
        // the palette) is unaffected since there's no dot for it
        const list = combined.filter(e => {
            const colorIdx = rec.filterColors.indexOf(e.color);
            if (colorIdx !== -1 && !rec.filterActive[colorIdx])
                return false;
            const endDate = e.endDate ?? e.startDate;
            const endTime = e.endTime ?? "23:59";
            return new Date(endDate + "T" + endTime + ":00").getTime() >= nowMs;
        });
        list.sort((a, b) => {
            const aStart = a.startDate + "T" + (a.startTime ?? "00:00");
            const bStart = b.startDate + "T" + (b.startTime ?? "00:00");
            if (aStart !== bStart)
                return aStart < bStart ? -1 : 1;
            const aMulti = !!(a.endDate && a.endDate !== a.startDate);
            const bMulti = !!(b.endDate && b.endDate !== b.startDate);
            return aMulti === bMulti ? 0 : (aMulti ? 1 : -1);
        });
        return list;
    }

    Text {
        text: Qt.formatDateTime(clock.date, "hh:mm:ss|dd.MM.yy")
        color: Theme.textColor
        anchors.centerIn: parent
        style: Theme.style
        styleColor: Theme.styleColor

        font {
            family: Theme.fontFamily
            pointSize: Theme.pointSize
            bold: Theme.fontBold
        }

        SystemClock {
            id: clock
            precision: SystemClock.Seconds
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                rec.alarmsOpen = !rec.alarmsOpen;
            } else if (mouse.button === Qt.RightButton) {
                const i = rec.calendarModes.indexOf(rec.calendarMode);
                rec.calendarMode = rec.calendarModes[(i + 1) % rec.calendarModes.length];
            } else if (mouse.button === Qt.MiddleButton) {
                let today = new Date();
                rec.viewMonth = today.getMonth();
                rec.viewYear = today.getFullYear();
            }
        }

        onWheel: event => rec.handleCalendarWheel(event.angleDelta.y)
    }

    AlarmsCenter {
        id: alarmsCenter
        anchorItem: rec
        centerOpen: rec.alarmsOpen
    }

    HyprlandFocusGrab {
        id: alarmsGrab
        windows: [alarmsCenter]
        active: rec.alarmsOpen
        onCleared: rec.alarmsOpen = false
    }

    PopupWindow {
        id: calendarPopup

        anchor.item: rec
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6

        implicitWidth: calendarColumn.implicitWidth + 20
        implicitHeight: calendarColumn.implicitHeight + 16
        color: "transparent"

        // stays open while the mouse is over either the bar widget or the
        // popup itself, so you can move the cursor into it and interact
        // with whatever's inside without it closing underneath you.
        // Debounced (see calendarWantsOpen/calendarCloseTimer below): the
        // ~6px gap between the widget and the popup is a real dead zone
        // neither region covers, and an instant hide there would unmap the
        // popup - killing calendarPopupHover along with it - before the
        // cursor ever reaches the popup, so it could never re-open by hover
        visible: rec.calendarActuallyOpen

        Rectangle {
            anchors.fill: parent
            radius: Theme.tooltipRadius
            color: Theme.tooltipBg
            border.color: Theme.tooltipBorder
            border.width: Theme.tooltipBorderWidth

            HoverHandler {
                id: calendarPopupHover
            }

            // wheel-only (acceptedButtons: NoButton so clicks on anything
            // inside still reach it) - lets month/year scrolling work while
            // the mouse is over the popup, not just the bar widget. The
            // Upcoming list's own Flickable is a descendant and consumes
            // wheel over itself first, so this only fires when hovering
            // elsewhere in the popup (matching handleCalendarWheel's own
            // no-op-in-upcoming-mode guard for the rest of it)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: event => rec.handleCalendarWheel(event.angleDelta.y)
            }

            ColumnLayout {
                id: calendarColumn
                anchors.centerIn: parent
                spacing: 4

                // --- Month view ---
                ColumnLayout {
                    visible: rec.calendarMode === "month"
                    spacing: 4

                    Text {
                        id: monthTitle
                        Layout.alignment: Qt.AlignHCenter
                        text: rec.monthNames[rec.viewMonth] + " " + rec.viewYear
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pointSize: Theme.pointSize
                            bold: true
                        }
                    }

                    GridLayout {
                        id: monthGrid
                        Layout.alignment: Qt.AlignHCenter
                        columns: 7
                        rowSpacing: 0
                        columnSpacing: 6

                        Repeater {
                            model: rec.weekdayNames

                            Text {
                                required property string modelData
                                required property int index

                                Layout.preferredWidth: rec.cellSize
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: rec.weekdayHeaderColor(index)
                                style: Theme.style
                                styleColor: Theme.styleColor
                                font {
                                    family: Theme.fontFamily
                                    pointSize: Theme.pointSize - 2
                                    bold: true
                                }
                            }
                        }

                        Repeater {
                            model: rec.currentMonthCells

                            Text {
                                id: monthDayCell
                                required property var modelData

                                Layout.preferredWidth: rec.cellSize
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.day
                                opacity: modelData.current ? 1.0 : 0.35
                                color: rec.dayColor(modelData)
                                style: Theme.style
                                styleColor: Theme.styleColor
                                font {
                                    family: Theme.fontFamily
                                    pointSize: Theme.pointSize - 2
                                    bold: modelData.today
                                    underline: modelData.today || (rec.hoveredEvent && rec.dateInRange(monthDayCell.modelData.dateKey, rec.hoveredEvent))
                                }

                                HoverHandler {
                                    onHoveredChanged: {
                                        if (hovered)
                                            rec.hoveredDateKey = monthDayCell.modelData.dateKey;
                                        else if (rec.hoveredDateKey === monthDayCell.modelData.dateKey)
                                            rec.hoveredDateKey = "";
                                    }
                                }
                            }
                        }
                    }
                }

                // --- Upcoming view (barebones - reads Alarms.appointments,
                // which nothing writes to yet; will be populated once the
                // Termine tab gets an editor) ---
                ColumnLayout {
                    visible: rec.calendarMode === "upcoming"
                    spacing: 4

                    // "Upcoming" flanked by 3 filter dots on each side (one
                    // per filterColors slot) - click to toggle that color's
                    // events on/off in the list below. Filled = on, hollow
                    // (border only) = off. Sized to the header text's own
                    // line height so they read as inline punctuation, not
                    // separate UI
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        // matches monthTitle's height so the header doesn't
                        // jump size when switching pages
                        Layout.preferredHeight: monthTitle.height
                        spacing: 4

                        Repeater {
                            model: 3

                            Rectangle {
                                id: filterDotLeft
                                required property int index

                                readonly property int colorIndex: index
                                readonly property bool active: rec.filterActive[colorIndex]

                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: upcomingTitleText.implicitHeight - 5
                                implicitHeight: upcomingTitleText.implicitHeight - 5
                                radius: width / 2
                                color: active ? rec.filterColors[colorIndex] : "transparent"
                                border.color: rec.filterColors[colorIndex]
                                border.width: 1.5

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rec.toggleFilter(filterDotLeft.colorIndex)
                                }
                            }
                        }

                        Text {
                            id: upcomingTitleText
                            text: "Upcoming"
                            color: Theme.textColor
                            style: Theme.style
                            styleColor: Theme.styleColor
                            font {
                                family: Theme.fontFamily
                                pointSize: Theme.pointSize
                                bold: true
                            }
                        }

                        Repeater {
                            model: 3

                            Rectangle {
                                id: filterDotRight
                                required property int index

                                readonly property int colorIndex: index + 3
                                readonly property bool active: rec.filterActive[colorIndex]

                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: upcomingTitleText.implicitHeight - 5
                                implicitHeight: upcomingTitleText.implicitHeight - 5
                                radius: width / 2
                                color: active ? rec.filterColors[colorIndex] : "transparent"
                                border.color: rec.filterColors[colorIndex]
                                border.width: 1.5

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rec.toggleFilter(filterDotRight.colorIndex)
                                }
                            }
                        }
                    }

                    Text {
                        visible: rec.upcomingEvents.length === 0
                        Layout.preferredWidth: rec.upcomingWidth
                        horizontalAlignment: Text.AlignHCenter
                        text: "No upcoming events"
                        opacity: 0.5
                        color: Theme.textColor
                        font {
                            family: Theme.fontFamily
                            pointSize: Theme.pointSize - 2
                        }
                    }

                    // wide enough for a full date range, tall enough for
                    // ~4 events - scrollable, no artificial cap on how many
                    // events show, so this is "infinite" scroll in practice
                    // since nothing trims the underlying list
                    Flickable {
                        visible: rec.upcomingEvents.length > 0
                        Layout.preferredWidth: rec.upcomingWidth
                        Layout.preferredHeight: rec.upcomingRowHeight * 4 - 6
                        contentWidth: width
                        contentHeight: upcomingColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: upcomingColumn
                            width: parent.width
                            spacing: 0

                            Repeater {
                                model: rec.upcomingEvents

                                ColumnLayout {
                                    id: eventBlock
                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    spacing: 1

                                    // thin separator between entries (none
                                    // above the first one)
                                    Rectangle {
                                        visible: eventBlock.index > 0
                                        Layout.fillWidth: true
                                        Layout.topMargin: 3
                                        Layout.bottomMargin: 2
                                        height: 1
                                        color: Theme.tooltipBorder
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Rectangle {
                                            Layout.alignment: Qt.AlignVCenter
                                            implicitWidth: 6
                                            implicitHeight: 6
                                            radius: 3
                                            color: eventBlock.modelData.color ?? Theme.textColor
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            text: rec.formatEventDate(eventBlock.modelData)
                                            color: eventBlock.modelData.color ?? Theme.textColor
                                            font {
                                                family: Theme.fontFamily
                                                pointSize: Theme.pointSize - 3
                                                bold: true
                                            }
                                        }
                                    }

                                    // name only - the date line above stays
                                    // put. Elided/static normally; hovering
                                    // it marquees the full text instead
                                    Item {
                                        id: nameContainer
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 10
                                        implicitHeight: nameText.implicitHeight
                                        clip: true

                                        HoverHandler {
                                            id: nameHover
                                        }

                                        Text {
                                            id: nameText

                                            readonly property real overflow: Math.max(0, implicitWidth - nameContainer.width)
                                            property real marqueeX: 0

                                            width: nameHover.hovered ? implicitWidth : nameContainer.width
                                            x: (nameHover.hovered && overflow > 0) ? marqueeX : 0
                                            elide: Text.ElideRight
                                            text: eventBlock.modelData.name
                                            color: Theme.textColor
                                            font {
                                                family: Theme.fontFamily
                                                pointSize: Theme.pointSize - 3
                                            }

                                            SequentialAnimation {
                                                running: nameHover.hovered && nameText.overflow > 0
                                                loops: Animation.Infinite

                                                onRunningChanged: if (!running)
                                                    nameText.marqueeX = 0

                                                PauseAnimation {
                                                    duration: 500
                                                }
                                                NumberAnimation {
                                                    target: nameText
                                                    property: "marqueeX"
                                                    from: 0
                                                    to: -nameText.overflow
                                                    duration: Math.max(800, nameText.overflow * 30)
                                                    easing.type: Easing.Linear
                                                }
                                                PauseAnimation {
                                                    duration: 500
                                                }
                                                NumberAnimation {
                                                    target: nameText
                                                    property: "marqueeX"
                                                    from: -nameText.overflow
                                                    to: 0
                                                    duration: Math.max(800, nameText.overflow * 30)
                                                    easing.type: Easing.Linear
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --- Year view ---
                ColumnLayout {
                    visible: rec.calendarMode === "year"
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: rec.viewYear
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pointSize: Theme.pointSize
                            bold: true
                        }
                    }

                    GridLayout {
                        id: yearGrid
                        columns: 3
                        rowSpacing: 8
                        columnSpacing: 12

                        Repeater {
                            model: 12

                            ColumnLayout {
                                required property int index
                                spacing: 2

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: rec.monthNames[index]
                                    color: Theme.textColor
                                    style: Theme.style
                                    styleColor: Theme.styleColor
                                    font {
                                        family: Theme.fontFamily
                                        pointSize: Theme.pointSize - 3
                                        bold: true
                                    }
                                }

                                GridLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    columns: 7
                                    rowSpacing: 0
                                    columnSpacing: 2

                                    Repeater {
                                        model: rec.monthCells(rec.viewYear, index)

                                        Text {
                                            id: yearDayCell
                                            required property var modelData

                                            Layout.preferredWidth: rec.miniCellSize
                                            horizontalAlignment: Text.AlignRight
                                            verticalAlignment: Text.AlignVCenter
                                            text: modelData.current ? modelData.day : ""
                                            color: rec.dayColor(modelData)
                                            font {
                                                family: Theme.fontFamily
                                                pointSize: Theme.pointSize - 5
                                                bold: modelData.today
                                                underline: modelData.today || (rec.hoveredEvent && rec.dateInRange(yearDayCell.modelData.dateKey, rec.hoveredEvent))
                                            }

                                            HoverHandler {
                                                enabled: yearDayCell.modelData.current
                                                onHoveredChanged: {
                                                    if (hovered)
                                                        rec.hoveredDateKey = yearDayCell.modelData.dateKey;
                                                    else if (rec.hoveredDateKey === yearDayCell.modelData.dateKey)
                                                        rec.hoveredDateKey = "";
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // hovered day's event name (month/year grids only - see the
                // HoverHandlers on the day cells above) - shown below
                // whichever page is active. Fixed width (clipped) so a long
                // name can't resize the popup out from under the cursor
                // mid-hover; text past that width marquees instead of
                // wrapping/eliding. Deliberately no visible: toggle either -
                // ColumnLayout excludes invisible children from its height
                // calculation entirely, so that would reflow everything
                // above it (title, grid) by this row's height every time a
                // hover starts/ends. Stays in the layout permanently,
                // showing empty text (still its normal line height) instead.
                Item {
                    id: hoverNameContainer
                    Layout.alignment: Qt.AlignHCenter
                    // year view is a lot wider (3 mini-month columns) than
                    // the month grid, so give it the extra room there
                    Layout.preferredWidth: rec.calendarMode === "year" ? yearGrid.implicitWidth : monthGrid.implicitWidth
                    implicitHeight: hoverNameText.implicitHeight
                    clip: true

                    Text {
                        id: hoverNameText

                        readonly property real overflow: Math.max(0, implicitWidth - hoverNameContainer.width)
                        property real marqueeX: 0

                        x: overflow > 0 ? marqueeX : (hoverNameContainer.width - implicitWidth) / 2
                        text: rec.hoveredEvent ? rec.hoveredEvent.name : ""
                        color: rec.hoveredEvent ? (rec.hoveredEvent.color ?? Theme.textColor) : Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pointSize: Theme.pointSize - 3
                            bold: true
                        }

                        SequentialAnimation {
                            running: hoverNameText.overflow > 0
                            loops: Animation.Infinite

                            onRunningChanged: if (!running)
                                hoverNameText.marqueeX = 0

                            PauseAnimation {
                                duration: 700
                            }
                            NumberAnimation {
                                target: hoverNameText
                                property: "marqueeX"
                                from: 0
                                to: -hoverNameText.overflow
                                duration: Math.max(1000, hoverNameText.overflow * 35)
                                easing.type: Easing.Linear
                            }
                            PauseAnimation {
                                duration: 700
                            }
                            NumberAnimation {
                                target: hoverNameText
                                property: "marqueeX"
                                from: -hoverNameText.overflow
                                to: 0
                                duration: Math.max(1000, hoverNameText.overflow * 35)
                                easing.type: Easing.Linear
                            }
                        }
                    }
                }
            }
        }
    }
}
