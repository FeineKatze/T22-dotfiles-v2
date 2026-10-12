import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../shared"

Rectangle {
    id: root

    required property var entry

    signal dismissRequested

    function resolveIcon(value) {
        if (!value || value.length === 0)
            return "";
        if (value.includes("://"))
            return value; // already a URI (file://, image://qsimage/..., etc.) — use as-is
        if (value.startsWith("/"))
            return "file://" + value; // absolute filesystem path
        return Quickshell.iconPath(value, ""); // bare icon-theme name
    }

    readonly property var buttons: Notifications.buttonsFor(entry)

    readonly property string iconSource: {
        const fromImage = resolveIcon(entry.image);
        return fromImage.length > 0 ? fromImage : resolveIcon(entry.appIcon);
    }

    implicitWidth: 320
    implicitHeight: contentRow.implicitHeight + 16
    radius: Theme.tooltipRadius
    color: Theme.tooltipBg
    border.width: Theme.tooltipBorderWidth
    border.color: entry.urgency === NotificationUrgency.Critical ? "#e94b4b" : Theme.tooltipBorder

    // declared before the content so the action buttons below sit above it
    // and get their own clicks
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            // right-click = the app's own "default" action (usually focus
            // the app / open what the notification is about)
            if (mouse.button === Qt.RightButton) {
                const act = root.entry.notif ? root.entry.notif.actions.find(a => a.identifier === "default") : null;
                if (act)
                    act.invoke();
            }
            root.dismissRequested();
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        IconImage {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignTop
            visible: root.iconSource.length > 0
            source: root.iconSource
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.entry.summary || root.entry.appName
                elide: Text.ElideRight
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
                visible: root.entry.body.length > 0
                text: root.entry.body
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                opacity: 0.8
                color: Theme.textColor
                style: Theme.style
                styleColor: Theme.styleColor
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                    bold: false
                }
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: root.buttons.length > 0
                spacing: 6

                Repeater {
                    model: root.buttons

                    Rectangle {
                        id: btn
                        required property var modelData

                        implicitWidth: btnLabel.implicitWidth + 16
                        implicitHeight: btnLabel.implicitHeight + 8
                        radius: 4
                        color: btnHover.hovered ? Theme.menuItemHoverBg : Theme.widgetBg

                        HoverHandler {
                            id: btnHover
                        }

                        Text {
                            id: btnLabel
                            anchors.centerIn: parent
                            text: btn.modelData.label
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: Theme.fontSize - 2
                                bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                btn.modelData.run(root.entry);
                                root.dismissRequested();
                            }
                        }
                    }
                }
            }
        }
    }

}
