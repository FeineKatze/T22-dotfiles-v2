pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Win7-style alt-tab window switcher: a centered row of icon tiles over all
// open windows (every monitor/workspace). Tab walks the highlight across up
// to `columns` tiles; only once the highlight reaches an edge does the
// strip scroll, and it wraps around infinitely in both directions.
QtObject {
    id: root

    property bool visible: false

    // captured at open() time so the window doesn't jump screens mid-session -
    // only consulted when displayMode is "focused" (see below)
    property string targetScreenName: "DP-1"

    // "focused" = only on the monitor that had focus (or the mouse) when
    // opened, using targetScreenName above (the original/default behavior);
    // "all" = mirrored on every monitor at once; "primary" = always on
    // primaryScreenName below, regardless of focus. One SwitcherWindow is
    // instantiated per screen either way (see shell.qml) - this just
    // controls which of them end up visible.
    property string displayMode: "primary"
    property string primaryScreenName: "DP-1"

    // the one knob for how many tiles are visible at once
    readonly property int columns: 5

    // "open" = window-open order (ToplevelManager's natural order); "mru" =
    // most-recently-used, using the list maintained below. mru is
    // tracked continuously regardless of which mode is active. Default is
    // "mru" for Windows-style Alt+Tab (open() selects the active window,
    // ie. index 0, and the first next() steps to the 2nd-most-recent) - kept
    // switchable rather than deleting the "open" path.
    property string order: "mru"

    // Toplevel object references, most-recent-first - identity-based rather
    // than keyed by an "address" string, since the generic Toplevel objects
    // ToplevelManager hands out (unlike Hyprland.toplevels' HyprlandToplevel)
    // have no such property
    property var mruList: []

    readonly property var windows: {
        const all = ToplevelManager.toplevels.values;
        if (root.order !== "mru")
            return all;
        const remaining = new Set(all);
        const sorted = [];
        for (const t of root.mruList)
            if (remaining.has(t)) {
                sorted.push(t);
                remaining.delete(t);
            }
        for (const t of all)
            if (remaining.has(t))
                sorted.push(t);
        return sorted;
    }

    property int selectedIndex: 0
    property int scrollOffset: 0 // index of the leftmost visible tile

    readonly property var visibleWindows: root.windows.slice(root.scrollOffset, root.scrollOffset + root.columns)

    property Connections mruTracker: Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            const active = ToplevelManager.activeToplevel;
            if (!active)
                return;
            const list = root.mruList.filter(t => t !== active);
            list.unshift(active);
            root.mruList = list;
        }
    }

    function toggle() {
        if (root.visible)
            root.close();
        else
            root.open();
    }

    function open() {
        root.targetScreenName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "DP-1";
        root.scrollOffset = 0;
        const active = ToplevelManager.activeToplevel;
        const idx = active ? root.windows.findIndex(w => w === active) : -1;
        root.selectedIndex = Math.max(0, idx);
        root.clampScroll();
        root.visible = true;
    }

    function close() {
        root.visible = false;
        // belt-and-suspenders: every close path (click-outside via the
        // focus grab, Escape, activating a window, or the Hyprland-side
        // confirm/cancel binds below) resets the compositor's "alttab"
        // submap here too, so the two never desync regardless of which
        // side triggered the close
        Hyprland.dispatch("hl.dsp.submap('reset')");
    }

    function clampScroll() {
        const n = root.windows.length;
        if (n === 0) {
            root.scrollOffset = 0;
            return;
        }
        let off = root.scrollOffset;
        if (root.selectedIndex < off)
            off = root.selectedIndex;
        if (root.selectedIndex >= off + root.columns)
            off = root.selectedIndex - root.columns + 1;
        off = Math.max(0, Math.min(off, Math.max(0, n - root.columns)));
        root.scrollOffset = off;
    }

    function advance(delta) {
        const n = root.windows.length;
        if (n === 0)
            return;
        root.selectedIndex = (root.selectedIndex + delta + n) % n;
        root.clampScroll();
    }

    // both auto-open if not already visible, then step - this is what makes
    // a single "next" IPC call do double duty as the Hyprland entry bind's
    // action (open() lands on the active window at index 0, then this same
    // call advances to index 1, the 2nd-most-recent - matching real Windows
    // Alt+Tab's "tap once to swap between your last two windows") and as
    // every subsequent Tab-while-held call
    function next() {
        if (!root.visible)
            root.open();
        root.advance(1);
    }

    function prev() {
        if (!root.visible)
            root.open();
        root.advance(-1);
    }

    function activate(toplevel) {
        if (toplevel)
            toplevel.activate();
        root.close();
    }

    function activateSelected() {
        root.activate(root.windows[root.selectedIndex]);
    }

    // icon lookup by appId, via DesktopEntries' heuristic matcher (same
    // resolver used elsewhere in this repo) with a generic fallback icon
    function iconFor(toplevel) {
        if (!toplevel)
            return "";
        const entry = DesktopEntries.heuristicLookup(toplevel.appId);
        return Quickshell.iconPath(entry ? entry.icon : toplevel.appId, "application-x-executable");
    }

    // shared keybind dispatch, used by the window's fallback focus holder
    function handleKey(key, modifiers) {
        if (key === Qt.Key_Escape) {
            root.close();
            return true;
        }
        // Shift+Tab commonly arrives as its own Key_Backtab rather than
        // Key_Tab with the shift modifier set, so check both
        if (key === Qt.Key_Backtab) {
            root.prev();
            return true;
        }
        if (key === Qt.Key_Tab || key === Qt.Key_Right) {
            if (modifiers & Qt.ShiftModifier)
                root.prev();
            else
                root.next();
            return true;
        }
        if (key === Qt.Key_Left) {
            root.prev();
            return true;
        }
        if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) {
            root.activateSelected();
            return true;
        }
        return false;
    }
}
