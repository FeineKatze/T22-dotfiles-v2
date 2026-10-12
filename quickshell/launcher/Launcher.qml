pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "calculator.js" as Calculator
import "converter.js" as Converter
import "fileicon.js" as FileIcon

QtObject {
    id: root

    // the one knob to change the grid width - nothing else hardcodes this
    readonly property int columns: 5

    property bool visible: false
    property string query: ""
    property int selectedIndex: 0

    // the order Tab cycles through - append "emoji" here once that mode exists
    readonly property var modes: ["search", "power", "pinned", "stash"]
    property string mode: "search"

    // icon for each mode's side-tab indicator (LauncherWindow.qml/ModeTab.qml) -
    // purely informative, no other behavior
    readonly property var modeGlyphs: ({
            search: String.fromCodePoint(0xF0349), // md-magnify
            power: String.fromCodePoint(0xF0425), // md-power
            pinned: String.fromCodePoint(0xF0931), // md-pin_outline
            stash: String.fromCodePoint(0xF120E) // md-archive_outline
        })

    // false = the compact single/capped-row app preview; true = the full
    // scrollable grid (Down from the top row expands, Up from the top row
    // collapses back) - only meaningful for plain app search/browse, not the
    // google/bookmarks prefix modes
    property bool appsExpanded: false

    function expandApps() {
        root.appsExpanded = true;
    }

    function collapseApps() {
        root.appsExpanded = false;
        root.selectedIndex = Math.min(root.selectedIndex, Math.max(0, root.visibleApps.length - 1));
    }

    // single-row power actions - a null command marks the unimplemented 5th
    // slot (candidates: lock screen via hyprlock, logout via
    // "hyprctl dispatch exit")
    readonly property var powerOptions: [
        {
            label: "Restart QS",
            glyph: "↻",
            // kill every running instance by both binary names ("qs" is
            // just the short alias of "quickshell"), not just `qs kill`'s
            // one matching instance - a leftover second shell would mean a
            // duplicate launcher/bar. Waits until they're really gone
            // (max ~5s) before starting the fresh one
            command: ["bash", "-c", "pkill -x qs; pkill -x quickshell; for i in $(seq 50); do pgrep -x qs >/dev/null || pgrep -x quickshell >/dev/null || break; sleep 0.1; done; setsid qs >/dev/null 2>&1 &"]
        },
        {
            label: "Restart",
            glyph: "⟳",
            command: ["reboot"]
        },
        {
            label: "Shutdown",
            glyph: "⏻",
            command: ["poweroff"]
        },
        {
            label: "Suspend",
            glyph: "⏾",
            command: ["systemctl", "suspend"]
        },
        {
            label: "",
            glyph: "?",
            command: null
        }
    ]

    function activatePower(option) {
        if (!option || !option.command)
            return;
        Quickshell.execDetached(option.command);
        root.close();
    }

    // live list of stashed windows (~/.config/hypr/modules/stash.lua) -
    // derived the same way the old fuzzel picker (hyprstash-pick.sh) did:
    // toplevels whose workspace is a "special:stash-<n>" scratch workspace,
    // sorted by slot number. No local state to keep in sync - this recomputes
    // from live Hyprland IPC data whenever toplevels/workspaces change.
    readonly property var stashSlots: {
        const re = /^special:stash-(\d+)$/;
        const slots = [];
        for (const t of Hyprland.toplevels.values) {
            const wsName = t.workspace ? t.workspace.name : "";
            const m = re.exec(wsName);
            if (!m)
                continue;
            slots.push({
                slot: parseInt(m[1], 10),
                title: t.title,
                appClass: (t.lastIpcObject && t.lastIpcObject.class) ? t.lastIpcObject.class : ""
            });
        }
        slots.sort((a, b) => a.slot - b.slot);
        return slots;
    }

    // same dispatch mechanism the fuzzel picker used - Stash.recall(n) is a
    // Lua global exposed by stash.lua, always returns hl.dsp.no_op()
    function recallStash(entry) {
        if (!entry)
            return;
        Hyprland.dispatch("Stash.recall(" + entry.slot + ")");
        root.close();
    }

    // "kill <filter>" - every open window (not full system process list,
    // like btop would show - just what's on screen), optionally narrowed by
    // a title/class substring match. Needs the owning pid, not just the
    // Hyprland address, since Enter/Shift+Enter send it a real signal rather
    // than asking Hyprland to close it.
    readonly property var killWindows: {
        const q = root.prefixArg.trim().toLowerCase();
        const list = [];
        for (const t of Hyprland.toplevels.values) {
            const cls = (t.lastIpcObject && t.lastIpcObject.class) ? t.lastIpcObject.class : "";
            const pid = (t.lastIpcObject && t.lastIpcObject.pid) ? t.lastIpcObject.pid : 0;
            if (!pid)
                continue;
            if (q.length > 0 && !cls.toLowerCase().includes(q) && !t.title.toLowerCase().includes(q))
                continue;
            list.push({
                title: t.title,
                appClass: cls,
                pid: pid
            });
        }
        return list;
    }

    function killSelected(sig) {
        const entry = root.killWindows[root.selectedIndex];
        if (!entry)
            return;
        Quickshell.execDetached(["kill", sig, String(entry.pid)]);
        root.close();
    }

    // "><command>" - runs a plain shell command without closing the
    // launcher; stays quiet on success and only reports a status line on
    // failure, fish-prompt-exit-code style
    property string shellStatus: ""
    property string shellLastStderr: ""

    property Process shellProcess: Process {
        stderr: StdioCollector {
            onStreamFinished: root.shellLastStderr = text.trim()
        }
        onExited: exitCode => {
            root.shellStatus = exitCode === 0 ? "" : "exit " + exitCode + (root.shellLastStderr.length > 0 ? ": " + root.shellLastStderr : "");
            running = false;
        }
    }

    function runShellCommand() {
        const cmd = root.prefixArg.trim();
        if (cmd.length === 0)
            return;
        root.shellStatus = "";
        root.shellLastStderr = "";
        root.shellProcess.command = ["bash", "-c", cmd];
        root.shellProcess.running = true;
        // stay in shell mode, ready for the next command
        root.query = ">";
    }

    function cycleMode() {
        const i = root.modes.indexOf(root.mode);
        root.mode = root.modes[(i + 1) % root.modes.length];
        root.appsExpanded = false;
        root.resetSelection();
    }

    // "g <query>" / "b <query>" / "kill <query>" / "s <query>" (Steam/Epic
    // games) / "m <query>" (Prism/Minecraft instances) / "><command>"
    // prefixes at the start of the search box - trigger automatically, no
    // Tab needed. The space requirement on the word prefixes is what keeps
    // eg. typing "gimp" from being mistaken for the google prefix, or
    // "steam" from being mistaken for the "s " games prefix.
    readonly property string prefixCommand: {
        if (root.mode !== "search")
            return "";
        if (/^g\s/i.test(root.query))
            return "google";
        if (/^b\s/i.test(root.query))
            return "bookmarks";
        if (/^kill\s/i.test(root.query))
            return "kill";
        if (/^s\s/i.test(root.query))
            return "games";
        if (/^m\s/i.test(root.query))
            return "minecraft";
        if (root.query.startsWith(">"))
            return "shell";
        return "";
    }
    readonly property string prefixArg: {
        if (root.prefixCommand === "shell")
            return root.query.replace(/^>\s*/, "");
        return root.query.replace(/^[a-zA-Z]+\s+/, "");
    }

    readonly property var allBookmarks: Bookmarks.allBookmarks

    readonly property var filteredBookmarks: {
        if (root.prefixCommand !== "bookmarks" || root.prefixArg.length === 0)
            return root.allBookmarks;

        const q = root.prefixArg.toLowerCase();
        return root.allBookmarks.filter(b => b.title.toLowerCase().includes(q) || b.url.toLowerCase().includes(q));
    }

    // always the full 5x3 grid, regardless of query length
    readonly property var visibleBookmarks: root.filteredBookmarks.slice(0, root.columns * 3)

    // "s <query>" - installed Steam/Epic games (Games.allGames); empty
    // query shows everything, same as bookmarks above. Uncapped (unlike
    // visibleBookmarks) - the grid scrolls instead, same as stash/kill
    readonly property var visibleGames: {
        if (root.prefixCommand !== "games" || root.prefixArg.length === 0)
            return Games.allGames;
        const q = root.prefixArg.toLowerCase();
        return Games.allGames.filter(g => g.name.toLowerCase().includes(q));
    }

    // "m <query>" - Prism Launcher (Minecraft) instances, also uncapped/scrolling
    readonly property var visibleMinecraftInstances: {
        if (root.prefixCommand !== "minecraft" || root.prefixArg.length === 0)
            return Games.minecraftInstances;
        const q = root.prefixArg.toLowerCase();
        return Games.minecraftInstances.filter(i => i.name.toLowerCase().includes(q));
    }

    // whichever list the current mode's grid/selection acts on
    readonly property var currentList: {
        if (root.mode === "pinned")
            return root.pinnedPaths;
        if (root.mode === "power")
            return root.powerOptions;
        if (root.mode === "stash")
            return root.stashSlots;
        if (root.prefixCommand === "bookmarks")
            return root.visibleBookmarks;
        if (root.prefixCommand === "kill")
            return root.killWindows;
        if (root.prefixCommand === "games")
            return root.visibleGames;
        if (root.prefixCommand === "minecraft")
            return root.visibleMinecraftInstances;
        return root.activeApps.concat(root.matchingPinned);
    }

    // whether left/right should navigate the currently visible grid, or fall
    // through to normal text-cursor movement (an empty grid, or a google
    // search/calc result with nothing to navigate, has nothing to move onto)
    readonly property bool gridNavigable: {
        if (root.mode === "pinned")
            return root.pinnedPaths.length > 0;
        if (root.mode === "power")
            return root.powerOptions.length > 0;
        if (root.mode === "stash")
            return root.stashSlots.length > 0;
        if (root.prefixCommand === "google")
            return false;
        if (root.prefixCommand === "shell")
            return false;
        if (root.prefixCommand === "bookmarks")
            return root.visibleBookmarks.length > 0;
        if (root.prefixCommand === "kill")
            return root.killWindows.length > 0;
        if (root.prefixCommand === "games")
            return root.visibleGames.length > 0;
        if (root.prefixCommand === "minecraft")
            return root.visibleMinecraftInstances.length > 0;
        return root.calcResult.length === 0 && (root.activeApps.length > 0 || root.matchingPinned.length > 0);
    }

    function openGoogleSearch(query) {
        Quickshell.execDetached(["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(query)]);
        root.close();
    }

    function openBookmark(bookmark) {
        Quickshell.execDetached(["xdg-open", bookmark.url]);
        root.close();
    }

    function launchGame(entry) {
        Games.launchGame(entry);
        root.close();
    }

    function launchMinecraftInstance(entry) {
        Games.launchMinecraftInstance(entry);
        root.close();
    }

    // captured at open() time so the window doesn't jump screens mid-session
    property string targetScreenName: "DP-1"

    // appId -> number of times launched, persisted so the empty-search row
    // can surface your most-used apps first (like fuzzel's launch history)
    property var usageCounts: ({})

    function recordUsage(id) {
        const counts = Object.assign({}, root.usageCounts);
        counts[id] = (counts[id] ?? 0) + 1;
        root.usageCounts = counts;
        usageAdapter.counts = counts;
        root.usageFileView.writeAdapter();
    }

    property Process usageDirProcess: Process {
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.cache/quickshell"]
        running: true
        onExited: running = false
    }

    property FileView usageFileView: FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell/launcher-usage.json"
        watchChanges: true
        blockWrites: false
        printErrors: true

        adapter: JsonAdapter {
            id: usageAdapter
            property var counts: ({})
        }

        onLoaded: root.usageCounts = usageAdapter.counts ?? ({})
        onLoadFailed: error => root.usageCounts = ({})
        onFileChanged: root.usageFileView.reload()
    }

    // most-used first (ties broken alphabetically); this ordering only
    // actually shows up in the empty-search row - the search view re-sorts
    // by match relevance instead (see filteredApps below)
    readonly property var allApps: {
        const list = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        list.sort((a, b) => {
            const countA = root.usageCounts[a.id] ?? 0;
            const countB = root.usageCounts[b.id] ?? 0;
            if (countA !== countB)
                return countB - countA;
            return a.name.localeCompare(b.name);
        });
        return list;
    }

    readonly property var filteredApps: {
        if (root.query.length === 0)
            return root.allApps;

        const q = root.query.toLowerCase();

        const matches = root.allApps.filter(e => {
            if (e.name.toLowerCase().includes(q))
                return true;
            if (e.genericName && e.genericName.toLowerCase().includes(q))
                return true;
            return e.keywords && e.keywords.some(k => k.toLowerCase().includes(q));
        });

        // name-starts-with first, then everything else, alphabetical within each group
        matches.sort((a, b) => {
            const aStarts = a.name.toLowerCase().startsWith(q);
            const bStarts = b.name.toLowerCase().startsWith(q);
            if (aStarts !== bStarts)
                return aStarts ? -1 : 1;
            return a.name.localeCompare(b.name);
        });

        return matches;
    }

    // 1 row when the search is empty, up to 3 rows while searching
    readonly property var visibleApps: root.filteredApps.slice(0, root.columns * (root.query.length === 0 ? 1 : 3))

    // the capped preview normally, or every match once expanded (Down from
    // the top row) - what the grid/selection actually acts on
    readonly property var activeApps: root.appsExpanded ? root.filteredApps : root.visibleApps

    // pinned files (mostly), set externally (eg. via a yazi keybind that
    // appends to this same JSON file) - watchChanges picks up those edits live
    property var pinnedPaths: []

    // pinned files/folders matching the current search - a search-mode
    // assist, not a replacement for browsing everything in "pinned" mode, so
    // it stays hidden on an empty query and only surfaces once you've
    // actually typed something to find. Appended after activeApps in the
    // grid (see LauncherWindow.qml); opens the same way pinned mode does
    // (openPath), not app-launch
    readonly property var matchingPinned: {
        if (root.mode !== "search" || root.prefixCommand !== "" || root.query.length === 0)
            return [];
        const q = root.query.toLowerCase();
        // basename only, not the full path - PinnedTile only ever shows
        // the basename, and matching the full path let a query hit
        // ancestor directory names (eg. "pro" matching "Projects") that
        // never appear anywhere in what's actually shown, looking like an
        // unrelated random result
        return root.pinnedPaths.filter(p => FileIcon.baseName(p).toLowerCase().includes(q));
    }

    readonly property string pinnedFilePath: Quickshell.env("HOME") + "/.local/share/quickshell/pinned.json"

    property Process pinnedDirProcess: Process {
        command: ["bash", "-c", "mkdir -p " + Quickshell.env("HOME") + "/.local/share/quickshell && [ -f " + root.pinnedFilePath + " ] || echo '{\"paths\": []}' > " + root.pinnedFilePath]
        running: true
        onExited: running = false
    }

    property FileView pinnedFileView: FileView {
        path: root.pinnedFilePath
        watchChanges: true
        blockWrites: false
        printErrors: true

        adapter: JsonAdapter {
            id: pinnedAdapter
            property var paths: []
        }

        onLoaded: root.pinnedPaths = pinnedAdapter.paths ?? []
        onLoadFailed: error => root.pinnedPaths = []

        // watchChanges only notifies that the file changed - it doesn't
        // reload the content on its own, so an external edit (eg. the yazi
        // pin script) needs an explicit reload to actually show up
        onFileChanged: root.pinnedFileView.reload()
    }

    function unpinPath(path) {
        const paths = root.pinnedPaths.filter(p => p !== path);
        root.pinnedPaths = paths;
        pinnedAdapter.paths = paths;
        root.pinnedFileView.writeAdapter();
    }

    function unpinSelected() {
        const path = root.pinnedPaths[root.selectedIndex];
        if (!path)
            return;
        root.unpinPath(path);
        root.selectedIndex = Math.min(root.selectedIndex, Math.max(0, root.pinnedPaths.length - 1));
    }

    function openPath(path) {
        Quickshell.execDetached(["xdg-open", path]);
        root.close();
    }

    function openSelectedPinned() {
        const path = root.pinnedPaths[root.selectedIndex];
        if (path)
            root.openPath(path);
    }

    function revealSelectedInYazi() {
        const path = root.pinnedPaths[root.selectedIndex];
        if (path)
            Quickshell.execDetached(["kitty", "-e", "yazi", path]);
        root.close();
    }

    // debug keybind (Ctrl+Enter on a plain app tile): reveals that app's
    // .desktop file in yazi, same "open the path" idiom as
    // revealSelectedInYazi above. DesktopEntry only exposes `id` (the
    // desktop-file-id, eg "firefox"), not the actual filesystem path, so
    // this searches the standard XDG applications dirs for "<id>.desktop"
    // via `find` (positional $1 arg, not string-interpolated, so no
    // escaping concerns) and opens whatever it finds first.
    property Process debugDesktopFileProcess: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path.length > 0)
                    Quickshell.execDetached(["kitty", "-e", "yazi", path]);
                else
                    Quickshell.execDetached(["notify-send", "launcher", "desktop file not found"]);
            }
        }
        onExited: running = false
    }

    function debugOpenSelectedDesktopFile() {
        const entry = root.activeApps[root.selectedIndex];
        if (!entry)
            return;
        root.debugDesktopFileProcess.command = ["bash", "-c", 'find "$HOME/.local/share/applications" /usr/local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications "$HOME/.local/share/flatpak/exports/share/applications" -name "$1" 2>/dev/null | head -n1', "_", entry.id + ".desktop"];
        root.debugDesktopFileProcess.running = true;
        root.close();
    }

    // exchange-rate cache for currency conversion - { base, rates, fetchedAt }
    // refreshed daily, since per-keystroke network calls aren't feasible
    property var currencyRates: null

    property FileView currencyFileView: FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell/currency-rates.json"
        watchChanges: true
        blockWrites: false
        printErrors: true

        adapter: JsonAdapter {
            id: currencyAdapter
            property string base: ""
            property var rates: ({})
            property double fetchedAt: 0
        }

        onLoaded: {
            if (currencyAdapter.base.length > 0)
                root.currencyRates = {
                    base: currencyAdapter.base,
                    rates: currencyAdapter.rates
                };
        }
        onLoadFailed: error => {}
        onFileChanged: root.currencyFileView.reload()
    }

    // refetches from frankfurter.app (free, no API key) - whatever base
    // currency it hands back is fine, evaluateCurrency() doesn't care
    property Process currencyFetchProcess: Process {
        command: ["curl", "-sL", "--max-time", "5", "https://api.frankfurter.app/latest"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (!data.base || !data.rates)
                        return;
                    root.currencyRates = {
                        base: data.base,
                        rates: data.rates
                    };
                    currencyAdapter.base = data.base;
                    currencyAdapter.rates = data.rates;
                    currencyAdapter.fetchedAt = Date.now();
                    root.currencyFileView.writeAdapter();
                } catch (e) {
                    // offline or bad response - keep using the cached rates, if any
                }
            }
        }
        onExited: running = false
    }

    property Timer currencyRefreshTimer: Timer {
        interval: 24 * 60 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currencyFetchProcess.running = true
    }

    // "" when the query isn't a valid math expression, unit conversion,
    // timezone conversion, or currency conversion (the common case - app search)
    readonly property string calcResult: Calculator.evaluate(root.query) ?? Converter.evaluateBaseTo(root.query) ?? Converter.evaluateBaseDefault(root.query) ?? Converter.evaluateUnit(root.query) ?? Converter.evaluateUnitDefault(root.query) ?? Converter.evaluateTimezone(root.query) ?? Converter.evaluateCurrency(root.query, root.currencyRates) ?? ""

    // default selection is always the first/top-left tile of whatever's currently shown
    function resetSelection() {
        root.selectedIndex = 0;
    }

    onQueryChanged: root.resetSelection()

    function moveSelection(dx, dy) {
        const count = root.currentList.length;
        if (count === 0)
            return;

        const cols = root.columns;
        const rowCount = Math.ceil(count / cols);
        let row = Math.floor(root.selectedIndex / cols);
        let col = root.selectedIndex % cols;

        col = Math.max(0, Math.min(cols - 1, col + dx));
        row = Math.max(0, Math.min(rowCount - 1, row + dy));

        // last row may be shorter than `columns` - clamp onto the last real item
        root.selectedIndex = Math.min(row * cols + col, count - 1);
    }

    // Enter copies a showing calculator result instead of launching an app
    function copyCalcResult() {
        if (root.calcResult.length === 0)
            return false;
        Quickshell.clipboardText = root.calcResult;
        root.close();
        return true;
    }

    function activateSelected() {
        if (root.prefixCommand === "google") {
            if (root.prefixArg.length > 0)
                root.openGoogleSearch(root.prefixArg);
            return;
        }
        if (root.prefixCommand === "bookmarks") {
            const bookmark = root.visibleBookmarks[root.selectedIndex];
            if (bookmark)
                root.openBookmark(bookmark);
            return;
        }
        if (root.prefixCommand === "games") {
            const game = root.visibleGames[root.selectedIndex];
            if (game)
                root.launchGame(game);
            return;
        }
        if (root.prefixCommand === "minecraft") {
            const instance = root.visibleMinecraftInstances[root.selectedIndex];
            if (instance)
                root.launchMinecraftInstance(instance);
            return;
        }
        if (root.mode === "power") {
            root.activatePower(root.powerOptions[root.selectedIndex]);
            return;
        }
        if (root.mode === "stash") {
            root.recallStash(root.stashSlots[root.selectedIndex]);
            return;
        }
        if (root.copyCalcResult())
            return;
        if (root.selectedIndex < root.activeApps.length) {
            const entry = root.activeApps[root.selectedIndex];
            if (entry)
                root.launch(entry);
            return;
        }
        const pinnedPath = root.matchingPinned[root.selectedIndex - root.activeApps.length];
        if (pinnedPath)
            root.openPath(pinnedPath);
    }

    function open() {
        root.targetScreenName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "DP-1";
        root.query = "";
        root.mode = "search";
        root.appsExpanded = false;
        root.shellStatus = "";
        root.shellLastStderr = "";
        root.resetSelection();
        root.visible = true;
        Bookmarks.refresh();
        Games.refresh();
    }

    function close() {
        root.visible = false;
    }

    function toggle() {
        if (root.visible)
            root.close();
        else
            root.open();
    }

    function launch(entry) {
        entry.execute();
        root.recordUsage(entry.id);
        root.close();
    }
}
