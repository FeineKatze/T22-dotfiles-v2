pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Floating notes window state/logic - two independent, open-ended lists of
// "files": plain-text notes and checklists. Each list has its own active
// slot index, switched via Ctrl+1-9 / Ctrl+Left/Right / click; Tab flips
// between the two modes (matches Launcher.cycleMode's Tab convention).
QtObject {
    id: root

    property bool visible: false

    readonly property var modes: ["text", "checklist"]
    property string mode: "text"

    // each mode's own open-ended array of "files" - text notes are plain
    // strings, checklists are arrays of {text, checked}
    property var textNotes: [""]
    property var checklistNotes: [[]]

    property int activeTextIndex: 0
    property int activeChecklistIndex: 0

    // captured at open() time so the window doesn't jump screens mid-session
    property string targetScreenName: "DP-1"

    readonly property var currentNotes: root.mode === "text" ? root.textNotes : root.checklistNotes
    readonly property int activeIndex: root.mode === "text" ? root.activeTextIndex : root.activeChecklistIndex

    // live editable mirror of the active checklist's items - kept as a
    // ListModel (not a plain JS array) so per-item edits mutate in place via
    // setProperty()/insert()/remove() instead of reassigning the whole
    // array, which would make the Repeater tear down and rebuild every
    // delegate (including whichever TextInput the user is mid-keystroke in)
    // on every character typed
    property ListModel activeItemsModel: ListModel {}

    // -1 when nothing is pending - set to an item index right after
    // inserting/appending/removing a checklist item so that item's delegate
    // can grab keyboard focus, then immediately reset back to -1
    property int pendingFocusIndex: -1

    function toggle() {
        if (root.visible)
            root.close();
        else
            root.open();
    }

    function open() {
        root.targetScreenName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "DP-1";
        root.visible = true;
        root.focusLatestCheckItem();
    }

    function close() {
        root.visible = false;
    }

    function cycleMode() {
        const i = root.modes.indexOf(root.mode);
        root.mode = root.modes[(i + 1) % root.modes.length];
        root.loadActiveChecklist();
        root.persist();
    }

    function setActiveIndex(i) {
        if (i < 0 || i >= root.currentNotes.length)
            return;
        if (root.mode === "text")
            root.activeTextIndex = i;
        else
            root.activeChecklistIndex = i;
        root.loadActiveChecklist();
        root.persist();
    }

    function prevSlot() {
        root.setActiveIndex(Math.max(0, root.activeIndex - 1));
    }

    function nextSlot() {
        root.setActiveIndex(Math.min(root.currentNotes.length - 1, root.activeIndex + 1));
    }

    // Ctrl+<n> - 1-based, no-op if that slot doesn't exist
    function jumpToSlot(n) {
        root.setActiveIndex(n - 1);
    }

    function newNote() {
        if (root.mode === "text") {
            root.textNotes = root.textNotes.concat([""]);
            root.activeTextIndex = root.textNotes.length - 1;
        } else {
            root.checklistNotes = root.checklistNotes.concat([[]]);
            root.activeChecklistIndex = root.checklistNotes.length - 1;
        }
        root.loadActiveChecklist();
        root.persist();
    }

    // closes/deletes the current slot; a mode is never left with zero slots -
    // closing the last remaining one just clears it instead of removing it
    function closeNote() {
        if (root.mode === "text") {
            if (root.textNotes.length <= 1) {
                root.textNotes = [""];
                root.activeTextIndex = 0;
            } else {
                const arr = root.textNotes.slice();
                arr.splice(root.activeTextIndex, 1);
                root.textNotes = arr;
                root.activeTextIndex = Math.min(root.activeTextIndex, arr.length - 1);
            }
        } else {
            if (root.checklistNotes.length <= 1) {
                root.checklistNotes = [[]];
                root.activeChecklistIndex = 0;
            } else {
                const arr = root.checklistNotes.slice();
                arr.splice(root.activeChecklistIndex, 1);
                root.checklistNotes = arr;
                root.activeChecklistIndex = Math.min(root.activeChecklistIndex, arr.length - 1);
            }
        }
        root.loadActiveChecklist();
        root.persist();
    }

    function setTextContent(text) {
        const arr = root.textNotes.slice();
        arr[root.activeTextIndex] = text;
        root.textNotes = arr;
        root.persist();
    }

    // JS array (persisted storage) -> ListModel (live UI) for the active
    // checklist slot. Called on slot/mode switches and on load - never
    // during in-place item edits (see commitActiveChecklist below)
    function loadActiveChecklist() {
        if (root.mode !== "checklist")
            return;
        root.activeItemsModel.clear();
        const items = root.checklistNotes[root.activeChecklistIndex] ?? [];
        for (const it of items)
            root.activeItemsModel.append({
                text: it.text,
                checked: it.checked
            });
        root.focusLatestCheckItem();
    }

    // focuses the last item in the active checklist, so Tab/Ctrl-shortcuts
    // work immediately after opening the window or switching into/within
    // checklist mode, without first having to click a line - deferred a
    // tick since the delegates for a freshly (re)loaded model aren't
    // guaranteed to exist yet in the same synchronous pass
    function focusLatestCheckItem() {
        if (root.mode !== "checklist")
            return;
        const idx = root.activeItemsModel.count - 1;
        if (idx < 0)
            return;
        Qt.callLater(() => {
            root.pendingFocusIndex = idx;
        });
    }

    // ListModel (live UI) -> JS array (persisted storage) for the active
    // checklist slot - the inverse of loadActiveChecklist, called after
    // every in-place item edit. Never calls loadActiveChecklist itself.
    function commitActiveChecklist() {
        const items = [];
        for (let i = 0; i < root.activeItemsModel.count; i++) {
            const e = root.activeItemsModel.get(i);
            items.push({
                text: e.text,
                checked: e.checked
            });
        }
        const lists = root.checklistNotes.slice();
        lists[root.activeChecklistIndex] = items;
        root.checklistNotes = lists;
        root.persist();
    }

    function toggleCheckItem(i) {
        if (i < 0 || i >= root.activeItemsModel.count)
            return;
        root.activeItemsModel.setProperty(i, "checked", !root.activeItemsModel.get(i).checked);
        root.commitActiveChecklist();
    }

    function setCheckItemText(i, text) {
        if (i < 0 || i >= root.activeItemsModel.count)
            return;
        root.activeItemsModel.setProperty(i, "text", text);
        root.commitActiveChecklist();
    }

    function addCheckItem() {
        root.activeItemsModel.append({
            text: "",
            checked: false
        });
        root.pendingFocusIndex = root.activeItemsModel.count - 1;
        root.commitActiveChecklist();
    }

    function insertCheckItemAfter(i) {
        root.activeItemsModel.insert(i + 1, {
            text: "",
            checked: false
        });
        root.pendingFocusIndex = i + 1;
        root.commitActiveChecklist();
    }

    function removeCheckItem(i) {
        if (i < 0 || i >= root.activeItemsModel.count)
            return;
        root.activeItemsModel.remove(i);
        root.pendingFocusIndex = Math.max(0, i - 1);
        root.commitActiveChecklist();
    }

    // shared keybind dispatch - used identically by the text editor and by
    // every checklist item's TextInput, so the shortcuts work no matter
    // which widget currently has focus. Returns true if handled.
    function handleKey(key, modifiers) {
        const ctrl = (modifiers & Qt.ControlModifier) !== 0;

        if (key === Qt.Key_Escape) {
            root.close();
            return true;
        }
        if (key === Qt.Key_Tab && !ctrl) {
            root.cycleMode();
            return true;
        }
        if (ctrl && key === Qt.Key_N) {
            root.newNote();
            return true;
        }
        if (ctrl && key === Qt.Key_W) {
            root.closeNote();
            return true;
        }
        if (ctrl && key === Qt.Key_Left) {
            root.prevSlot();
            return true;
        }
        if (ctrl && key === Qt.Key_Right) {
            root.nextSlot();
            return true;
        }
        if (ctrl && key >= Qt.Key_1 && key <= Qt.Key_9) {
            root.jumpToSlot(key - Qt.Key_0);
            return true;
        }
        return false;
    }

    property Process notesDirProcess: Process {
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/share/quickshell"]
        running: true
        onExited: running = false
    }

    property FileView notesFileView: FileView {
        path: Quickshell.env("HOME") + "/.local/share/quickshell/notes.json"
        watchChanges: true
        blockWrites: false
        printErrors: true

        adapter: JsonAdapter {
            id: notesAdapter
            property var textNotes: [""]
            property var checklistNotes: [[]]
            property string mode: "text"
            property int activeTextIndex: 0
            property int activeChecklistIndex: 0
        }

        onLoaded: {
            root.textNotes = (notesAdapter.textNotes && notesAdapter.textNotes.length > 0) ? notesAdapter.textNotes : [""];
            root.checklistNotes = (notesAdapter.checklistNotes && notesAdapter.checklistNotes.length > 0) ? notesAdapter.checklistNotes : [[]];
            root.mode = notesAdapter.mode === "checklist" ? "checklist" : "text";
            root.activeTextIndex = Math.min(Math.max(0, notesAdapter.activeTextIndex), root.textNotes.length - 1);
            root.activeChecklistIndex = Math.min(Math.max(0, notesAdapter.activeChecklistIndex), root.checklistNotes.length - 1);
            root.loadActiveChecklist();
        }
        onLoadFailed: error => {}
        onFileChanged: root.notesFileView.reload()
    }

    function persist() {
        notesAdapter.textNotes = root.textNotes;
        notesAdapter.checklistNotes = root.checklistNotes;
        notesAdapter.mode = root.mode;
        notesAdapter.activeTextIndex = root.activeTextIndex;
        notesAdapter.activeChecklistIndex = root.activeChecklistIndex;
        root.notesFileView.writeAdapter();
    }
}
