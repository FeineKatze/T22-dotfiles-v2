import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../shared"

PanelWindow {
    id: notesWindow
    screen: Quickshell.screens.find(s => s.name === Notes.targetScreenName) ?? Quickshell.screens[0] ?? null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notes"

    visible: Notes.visible

    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 480
    implicitHeight: 420

    HyprlandFocusGrab {
        id: grab
        windows: [notesWindow]
        active: Notes.visible
        onCleared: Notes.close()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.tooltipRadius
        color: Theme.tooltipBg
        border.color: Theme.tooltipBorder
        border.width: Theme.tooltipBorderWidth

        // fallback focus holder: in checklist mode with zero items (or
        // before the first click into one), no TextInput has activeFocus,
        // so there'd be nothing to catch Escape - this catches it (and the
        // rest of Notes.handleKey) whenever a more specific child hasn't
        // already grabbed focus
        focus: true

        Keys.onPressed: event => {
            if (Notes.handleKey(event.key, event.modifiers))
                event.accepted = true;
        }

        ColumnLayout {
            id: mainColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // --- slot tab strip: scrollable pills + a fixed "+" button ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                ListView {
                    id: tabList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.barHeight
                    orientation: ListView.Horizontal
                    spacing: 4
                    clip: true
                    model: Notes.currentNotes.length

                    delegate: NoteTab {
                        required property int index
                        slotIndex: index
                    }

                    function ensureActiveVisible() {
                        Qt.callLater(() => tabList.positionViewAtIndex(Notes.activeIndex, ListView.Contain));
                    }

                    onCountChanged: tabList.ensureActiveVisible()

                    Connections {
                        target: Notes
                        function onActiveTextIndexChanged() {
                            tabList.ensureActiveVisible();
                        }
                        function onActiveChecklistIndexChanged() {
                            tabList.ensureActiveVisible();
                        }
                        function onModeChanged() {
                            tabList.ensureActiveVisible();
                        }
                    }
                }

                Rectangle {
                    id: addTab
                    Layout.preferredWidth: Theme.barHeight
                    Layout.preferredHeight: Theme.barHeight
                    radius: Theme.barRadius
                    color: addHover.hovered ? Theme.wsHoverBg : Theme.wsDefaultBg

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Theme.textColor
                        style: Theme.style
                        styleColor: Theme.styleColor
                        font {
                            family: Theme.fontFamily
                            pointSize: Theme.pointSize
                            bold: Theme.fontBold
                        }
                    }

                    HoverHandler {
                        id: addHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notes.newNote()
                    }
                }
            }

            // --- text mode: plain multi-line editor, normal controls ---
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Notes.mode === "text"
                clip: true
                contentWidth: width
                contentHeight: Math.max(height, textEdit.implicitHeight)

                TextEdit {
                    id: textEdit
                    width: parent.width
                    wrapMode: TextEdit.Wrap
                    text: Notes.textNotes[Notes.activeTextIndex] ?? ""
                    color: Theme.textColor
                    selectByMouse: true
                    persistentSelection: true
                    focus: Notes.visible && Notes.mode === "text"
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }

                    onTextChanged: {
                        if (text !== Notes.textNotes[Notes.activeTextIndex])
                            Notes.setTextContent(text);
                    }

                    // re-sync when the active slot's content changes from
                    // outside this widget's own typing (switching slots,
                    // creating/closing a note, initial load from disk) -
                    // typing severs the declarative "text:" binding above,
                    // same as Launcher's searchInput
                    function syncFromModel() {
                        const content = Notes.textNotes[Notes.activeTextIndex] ?? "";
                        if (textEdit.text !== content)
                            textEdit.text = content;
                    }

                    Connections {
                        target: Notes
                        function onActiveTextIndexChanged() {
                            textEdit.syncFromModel();
                        }
                        function onTextNotesChanged() {
                            textEdit.syncFromModel();
                        }
                    }

                    Keys.onPressed: event => {
                        if (Notes.handleKey(event.key, event.modifiers))
                            event.accepted = true;
                    }
                }
            }

            // --- checklist mode: todo-style items, Enter adds, Backspace on
            // an empty item removes it, click toggles the checkmark ---
            ListView {
                id: checklistView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Notes.mode === "checklist"
                clip: true
                spacing: 2
                model: Notes.activeItemsModel

                delegate: RowLayout {
                    id: itemRow
                    required property int index
                    required property string text
                    required property bool checked

                    width: ListView.view.width
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        radius: 3
                        color: itemRow.checked ? Theme.wsActiveBg : "transparent"
                        border.color: Theme.tooltipBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            visible: itemRow.checked
                            text: "✓"
                            color: Theme.textColor
                            font {
                                family: Theme.fontFamily
                                pixelSize: 12
                                bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notes.toggleCheckItem(itemRow.index)
                        }
                    }

                    TextInput {
                        id: itemInput
                        Layout.fillWidth: true
                        text: itemRow.text
                        color: Theme.textColor
                        opacity: itemRow.checked ? 0.5 : 1
                        selectByMouse: true
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            strikeout: itemRow.checked
                        }

                        onTextChanged: {
                            if (text !== itemRow.text)
                                Notes.setCheckItemText(itemRow.index, text);
                        }

                        Connections {
                            target: Notes
                            function onPendingFocusIndexChanged() {
                                if (Notes.pendingFocusIndex === itemRow.index) {
                                    itemInput.forceActiveFocus();
                                    Notes.pendingFocusIndex = -1;
                                }
                            }
                        }

                        Keys.onPressed: event => {
                            if (Notes.handleKey(event.key, event.modifiers)) {
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                Notes.insertCheckItemAfter(itemRow.index);
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Backspace && itemInput.text.length === 0) {
                                Notes.removeCheckItem(itemRow.index);
                                event.accepted = true;
                                return;
                            }
                        }
                    }
                }

                footer: Rectangle {
                    width: checklistView.width
                    implicitHeight: 32
                    radius: 4
                    color: addItemHover.hovered ? Theme.menuItemHoverBg : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 26
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+ Add item"
                        opacity: 0.5
                        color: Theme.textColor
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }
                    }

                    HoverHandler {
                        id: addItemHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notes.addCheckItem()
                    }
                }
            }
        }
    }
}
