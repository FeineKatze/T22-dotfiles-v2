import QtQuick
import QtQuick.Layouts
import Quickshell
import "../shared"

PopupWindow {
    id: popup

    required property var anchorItem
    required property bool centerOpen

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: mainColumn.implicitWidth + 34
    implicitHeight: mainColumn.implicitHeight + 30
    color: "transparent"

    visible: centerOpen

    readonly property var weekdayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    property int newHour: 7
    property int newMinute: 0
    property string newType: "once"
    property var newWeekdays: []
    property string newLabel: ""
    property string newDate: Qt.formatDate(new Date(), "yyyy-MM-dd")

    property string newTimerMinutes: "10"
    property string newTimerLabel: ""

    Rectangle {
        anchors.fill: parent
        radius: Theme.tooltipRadius
        color: Theme.tooltipBg
        border.color: Theme.tooltipBorder
        border.width: Theme.tooltipBorderWidth

        ColumnLayout {
            id: mainColumn
            anchors.centerIn: parent
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    implicitWidth: alarmsTabLabel.implicitWidth + 22
                    implicitHeight: alarmsTabLabel.implicitHeight + 10
                    radius: 4
                    color: (Alarms.centerMode === "alarms" || alarmsTabHover.hovered) ? Theme.menuItemHoverBg : "transparent"

                    Text {
                        id: alarmsTabLabel
                        anchors.centerIn: parent
                        text: "Alarms"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: true
                        }
                    }

                    HoverHandler {
                        id: alarmsTabHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Alarms.centerMode = "alarms"
                    }
                }

                Rectangle {
                    implicitWidth: timersTabLabel.implicitWidth + 22
                    implicitHeight: timersTabLabel.implicitHeight + 10
                    radius: 4
                    color: (Alarms.centerMode === "timers" || timersTabHover.hovered) ? Theme.menuItemHoverBg : "transparent"

                    Text {
                        id: timersTabLabel
                        anchors.centerIn: parent
                        text: "Timers"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: true
                        }
                    }

                    HoverHandler {
                        id: timersTabHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Alarms.centerMode = "timers"
                    }
                }

                Rectangle {
                    implicitWidth: appointmentsTabLabel.implicitWidth + 22
                    implicitHeight: appointmentsTabLabel.implicitHeight + 10
                    radius: 4
                    color: (Alarms.centerMode === "appointments" || appointmentsTabHover.hovered) ? Theme.menuItemHoverBg : "transparent"

                    Text {
                        id: appointmentsTabLabel
                        anchors.centerIn: parent
                        text: "Termine"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: true
                        }
                    }

                    HoverHandler {
                        id: appointmentsTabHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Alarms.centerMode = "appointments"
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: settingsGlyph.implicitWidth + 14
                    implicitHeight: settingsGlyph.implicitHeight + 10
                    radius: 4
                    color: (Alarms.centerMode === "settings" || settingsTabHover.hovered) ? Theme.menuItemHoverBg : "transparent"

                    Text {
                        id: settingsGlyph
                        anchors.centerIn: parent
                        text: "⚙"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: true
                        }
                    }

                    HoverHandler {
                        id: settingsTabHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Alarms.centerMode = "settings"
                    }
                }
            }

            // --- Alarms view ---
            ColumnLayout {
                visible: Alarms.centerMode === "alarms"
                spacing: 6
                Layout.preferredWidth: 260

                Text {
                    visible: Alarms.alarms.length === 0
                    text: "No alarms"
                    opacity: 0.6
                    color: Theme.textColor
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }
                }

                Repeater {
                    model: Alarms.alarms

                    Rectangle {
                        id: alarmRow
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: alarmRowLayout.implicitHeight + 12
                        radius: 4
                        color: alarmHover.hovered ? Theme.menuItemHoverBg : "transparent"

                        HoverHandler {
                            id: alarmHover
                        }

                        RowLayout {
                            id: alarmRowLayout
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 8
                            spacing: 10

                            Rectangle {
                                implicitWidth: 10
                                implicitHeight: 10
                                radius: 5
                                color: alarmRow.modelData.enabled ? "#3DC24D" : Theme.tooltipBorder

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Alarms.toggleAlarm(alarmRow.modelData.id)
                                }
                            }

                            Text {
                                text: String(alarmRow.modelData.hour).padStart(2, "0") + ":" + String(alarmRow.modelData.minute).padStart(2, "0")
                                color: Theme.textColor
                                style: Theme.style
                                styleColor: Theme.styleColor
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize
                                    bold: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: {
                                    const m = alarmRow.modelData;
                                    const detail = m.type === "once" ? m.date : m.weekdays.map(i => popup.weekdayNames[i]).join(",");
                                    return (m.label.length > 0 ? m.label + " · " : "") + detail;
                                }
                                elide: Text.ElideRight
                                opacity: 0.8
                                color: Theme.textColor
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize
                                }
                            }

                            Text {
                                text: "✕"
                                color: Theme.textColor
                                opacity: 0.7
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Alarms.removeAlarm(alarmRow.modelData.id)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    height: 1
                    color: Theme.tooltipBorder
                }

                RowLayout {
                    spacing: 6

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 26
                        implicitHeight: hourInput.implicitHeight + 6
                        radius: 4
                        color: Theme.widgetBg

                        TextInput {
                            id: hourInput
                            anchors.fill: parent
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            text: String(popup.newHour).padStart(2, "0")
                            validator: RegularExpressionValidator {
                                regularExpression: /\d{0,2}/
                            }
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                                bold: true
                            }

                            // clamp down live as you type - eg "37" becomes 24
                            onTextChanged: {
                                if (text.length === 0)
                                    return;
                                let v = parseInt(text, 10);
                                if (isNaN(v))
                                    v = 0;
                                if (v > 24) {
                                    v = 24;
                                    text = String(v);
                                }
                                popup.newHour = v;
                            }

                            onEditingFinished: text = String(popup.newHour).padStart(2, "0")

                            // keep the field in sync when newHour changes elsewhere (arrows, wheel)
                            Connections {
                                target: popup
                                function onNewHourChanged() {
                                    if (!hourInput.activeFocus)
                                        hourInput.text = String(popup.newHour).padStart(2, "0");
                                }
                            }
                        }

                        // scroll to bump the hour up/down, same step as the arrows
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            onWheel: event => {
                                popup.newHour = (popup.newHour + (event.angleDelta.y > 0 ? 1 : 23)) % 24;
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0
                        Item {
                            implicitWidth: 18
                            implicitHeight: 14
                            Text {
                                anchors.centerIn: parent
                                text: "▲"
                                font.pixelSize: 11
                                color: Theme.textColor
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: popup.newHour = (popup.newHour + 1) % 24
                            }
                        }
                        Item {
                            implicitWidth: 18
                            implicitHeight: 14
                            Text {
                                anchors.centerIn: parent
                                text: "▼"
                                font.pixelSize: 11
                                color: Theme.textColor
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: popup.newHour = (popup.newHour + 23) % 24
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        verticalAlignment: Text.AlignVCenter
                        text: ":"
                        color: Theme.textColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: true
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 26
                        implicitHeight: minuteInput.implicitHeight + 6
                        radius: 4
                        color: Theme.widgetBg

                        TextInput {
                            id: minuteInput
                            anchors.fill: parent
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            text: String(popup.newMinute).padStart(2, "0")
                            validator: RegularExpressionValidator {
                                regularExpression: /\d{0,2}/
                            }
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                                bold: true
                            }

                            // clamp down live as you type - eg "75" becomes 60
                            onTextChanged: {
                                if (text.length === 0)
                                    return;
                                let v = parseInt(text, 10);
                                if (isNaN(v))
                                    v = 0;
                                if (v > 60) {
                                    v = 60;
                                    text = String(v);
                                }
                                popup.newMinute = v;
                            }

                            onEditingFinished: text = String(popup.newMinute).padStart(2, "0")

                            // keep the field in sync when newMinute changes elsewhere (arrows, wheel)
                            Connections {
                                target: popup
                                function onNewMinuteChanged() {
                                    if (!minuteInput.activeFocus)
                                        minuteInput.text = String(popup.newMinute).padStart(2, "0");
                                }
                            }
                        }

                        // scroll to bump the minute up/down, same step as the arrows
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            onWheel: event => {
                                popup.newMinute = (popup.newMinute + (event.angleDelta.y > 0 ? 1 : 59)) % 60;
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0
                        Item {
                            implicitWidth: 18
                            implicitHeight: 14
                            Text {
                                anchors.centerIn: parent
                                text: "▲"
                                font.pixelSize: 11
                                color: Theme.textColor
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: popup.newMinute = (popup.newMinute + 1) % 60
                            }
                        }
                        Item {
                            implicitWidth: 18
                            implicitHeight: 14
                            Text {
                                anchors.centerIn: parent
                                text: "▼"
                                font.pixelSize: 11
                                color: Theme.textColor
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: popup.newMinute = (popup.newMinute + 59) % 60
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: onceLabel.implicitWidth + 14
                        implicitHeight: onceLabel.implicitHeight + 8
                        radius: 4
                        color: (popup.newType === "once" || onceHover.hovered) ? Theme.menuItemHoverBg : "transparent"
                        Text {
                            id: onceLabel
                            anchors.centerIn: parent
                            text: "Once"
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                            }
                        }
                        HoverHandler {
                            id: onceHover
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.newType = "once"
                        }
                    }

                    Rectangle {
                        implicitWidth: weeklyLabel.implicitWidth + 14
                        implicitHeight: weeklyLabel.implicitHeight + 8
                        radius: 4
                        color: (popup.newType === "weekly" || weeklyHover.hovered) ? Theme.menuItemHoverBg : "transparent"
                        Text {
                            id: weeklyLabel
                            anchors.centerIn: parent
                            text: "Weekly"
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                            }
                        }
                        HoverHandler {
                            id: weeklyHover
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.newType = "weekly"
                        }
                    }
                }

                RowLayout {
                    visible: popup.newType === "once"
                    spacing: 6

                    Text {
                        text: "Date:"
                        color: Theme.textColor
                        opacity: 0.7
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }
                    }

                    Rectangle {
                        implicitWidth: 90
                        implicitHeight: dateInput.implicitHeight + 8
                        radius: 4
                        color: Theme.widgetBg

                        TextInput {
                            id: dateInput
                            anchors.fill: parent
                            anchors.margins: 6
                            verticalAlignment: TextInput.AlignVCenter
                            text: popup.newDate
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                            }
                            onTextChanged: popup.newDate = text
                        }
                    }
                }

                RowLayout {
                    visible: popup.newType === "weekly"
                    spacing: 4

                    Repeater {
                        model: popup.weekdayNames

                        Rectangle {
                            id: dayChip
                            required property string modelData
                            required property int index

                            implicitWidth: dayLabel.implicitWidth + 12
                            implicitHeight: dayLabel.implicitHeight + 8
                            radius: 4
                            color: (popup.newWeekdays.includes(dayChip.index) || dayHover.hovered) ? Theme.menuItemHoverBg : "transparent"

                            Text {
                                id: dayLabel
                                anchors.centerIn: parent
                                text: dayChip.modelData
                                color: Theme.textColor
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize
                                }
                            }

                            HoverHandler {
                                id: dayHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    popup.newWeekdays = popup.newWeekdays.includes(dayChip.index) ? popup.newWeekdays.filter(d => d !== dayChip.index) : [...popup.newWeekdays, dayChip.index];
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: labelInput.implicitHeight + 8
                        radius: 4
                        color: Theme.widgetBg

                        TextInput {
                            id: labelInput
                            anchors.fill: parent
                            anchors.margins: 6
                            verticalAlignment: TextInput.AlignVCenter
                            text: popup.newLabel
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                            }
                            onTextChanged: popup.newLabel = text
                        }

                        Text {
                            anchors.fill: labelInput
                            verticalAlignment: Text.AlignVCenter
                            visible: labelInput.text.length === 0
                            text: "Label"
                            opacity: 0.4
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: addAlarmLabel.implicitWidth + 16
                        implicitHeight: addAlarmLabel.implicitHeight + 10
                        radius: 4
                        color: addAlarmHover.hovered ? Theme.menuItemHoverBg : "transparent"

                        HoverHandler {
                            id: addAlarmHover
                        }

                        Text {
                            id: addAlarmLabel
                            anchors.centerIn: parent
                            text: "Add"
                            color: Theme.textColor
                            style: Theme.style
                            styleColor: Theme.styleColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                                bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (popup.newType === "weekly" && popup.newWeekdays.length === 0)
                                    return;
                                Alarms.addAlarm(popup.newLabel, popup.newHour, popup.newMinute, popup.newType, popup.newDate, popup.newWeekdays);
                                popup.newLabel = "";
                                labelInput.text = "";
                            }
                        }
                    }
                }
            }

            // --- Timers view ---
            ColumnLayout {
                visible: Alarms.centerMode === "timers"
                spacing: 6
                Layout.preferredWidth: 220

                Text {
                    visible: Alarms.timers.length === 0
                    text: "No timers"
                    opacity: 0.6
                    color: Theme.textColor
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }
                }

                Repeater {
                    model: Alarms.timers

                    Rectangle {
                        id: timerRow
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: timerRowLayout.implicitHeight + 12
                        radius: 4
                        color: timerHover.hovered ? Theme.menuItemHoverBg : "transparent"

                        HoverHandler {
                            id: timerHover
                        }

                        RowLayout {
                            id: timerRowLayout
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 6
                            spacing: 8

                            Text {
                                readonly property int remainingSec: Math.max(0, Math.ceil((timerRow.modelData.endTime - Alarms.now) / 1000))
                                text: String(Math.floor(remainingSec / 60)).padStart(2, "0") + ":" + String(remainingSec % 60).padStart(2, "0")
                                color: Theme.textColor
                                style: Theme.style
                                styleColor: Theme.styleColor
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize
                                    bold: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: timerRow.modelData.label
                                elide: Text.ElideRight
                                opacity: 0.8
                                color: Theme.textColor
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize
                                }
                            }

                            Text {
                                text: "✕"
                                color: Theme.textColor
                                opacity: 0.7
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Alarms.cancelTimer(timerRow.modelData.id)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    height: 1
                    color: Theme.tooltipBorder
                }

                RowLayout {
                    spacing: 6

                    Repeater {
                        model: [5, 10, 15, 30]

                        Rectangle {
                            id: presetChip
                            required property int modelData

                            implicitWidth: presetLabel.implicitWidth + 14
                            implicitHeight: presetLabel.implicitHeight + 8
                            radius: 4
                            color: presetHover.hovered ? Theme.menuItemHoverBg : "transparent"

                            Text {
                                id: presetLabel
                                anchors.centerIn: parent
                                text: presetChip.modelData + "m"
                                color: Theme.textColor
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: Theme.fontSize
                                }
                            }

                            HoverHandler {
                                id: presetHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Alarms.addTimer(presetChip.modelData, "")
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 6

                    Rectangle {
                        implicitWidth: 50
                        implicitHeight: minutesInput.implicitHeight + 8
                        radius: 4
                        color: Theme.widgetBg

                        TextInput {
                            id: minutesInput
                            anchors.fill: parent
                            anchors.margins: 6
                            verticalAlignment: TextInput.AlignVCenter
                            text: popup.newTimerMinutes
                            validator: IntValidator {
                                bottom: 1
                                top: 999
                            }
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                            }
                            onTextChanged: popup.newTimerMinutes = text
                        }
                    }

                    Text {
                        text: "min"
                        opacity: 0.6
                        color: Theme.textColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: timerLabelInput.implicitHeight + 8
                        radius: 4
                        color: Theme.widgetBg

                        TextInput {
                            id: timerLabelInput
                            anchors.fill: parent
                            anchors.margins: 6
                            verticalAlignment: TextInput.AlignVCenter
                            text: popup.newTimerLabel
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                            }
                            onTextChanged: popup.newTimerLabel = text
                        }

                        Text {
                            anchors.fill: timerLabelInput
                            verticalAlignment: Text.AlignVCenter
                            visible: timerLabelInput.text.length === 0
                            text: "Label"
                            opacity: 0.4
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: startLabel.implicitWidth + 16
                        implicitHeight: startLabel.implicitHeight + 10
                        radius: 4
                        color: startHover.hovered ? Theme.menuItemHoverBg : "transparent"

                        HoverHandler {
                            id: startHover
                        }

                        Text {
                            id: startLabel
                            anchors.centerIn: parent
                            text: "Start"
                            color: Theme.textColor
                            style: Theme.style
                            styleColor: Theme.styleColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize
                                bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const mins = parseInt(popup.newTimerMinutes, 10);
                                if (!mins || mins <= 0)
                                    return;
                                Alarms.addTimer(mins, popup.newTimerLabel);
                                popup.newTimerLabel = "";
                                timerLabelInput.text = "";
                            }
                        }
                    }
                }
            }

            // --- Appointments view (placeholder) ---
            ColumnLayout {
                visible: Alarms.centerMode === "appointments"
                spacing: 6
                Layout.preferredWidth: 260
            }

            // --- Settings view ---
            ColumnLayout {
                visible: Alarms.centerMode === "settings"
                spacing: 6
                Layout.preferredWidth: 260

                Text {
                    text: "Calendar"
                    opacity: 0.6
                    color: Theme.textColor
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                        bold: true
                    }
                }

                SettingsToggleRow {
                    label: "Weekend colors"
                    value: Alarms.showWeekendColors
                    onToggle: () => Alarms.toggleShowWeekendColors()
                }

                SettingsToggleRow {
                    label: "Appointments"
                    value: Alarms.showAppointments
                    onToggle: () => Alarms.toggleShowAppointments()
                }

                SettingsToggleRow {
                    label: "Feiertage"
                    value: Alarms.showGermanHolidays
                    onToggle: () => Alarms.toggleShowGermanHolidays()
                }

                SettingsToggleRow {
                    label: "Ferien"
                    value: Alarms.showGermanSchoolHolidays
                    onToggle: () => Alarms.toggleShowGermanSchoolHolidays()
                }
            }
        }
    }
}
