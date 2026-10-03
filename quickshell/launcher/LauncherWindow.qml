import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../shared"

PanelWindow {
    id: launcherWindow
    screen: Quickshell.screens.find(s => s.name === Launcher.targetScreenName) ?? Quickshell.screens[0] ?? null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"

    visible: Launcher.visible

    exclusiveZone: 0
    color: "transparent"

    implicitWidth: outerRow.implicitWidth + 32
    implicitHeight: Math.max(leftTabsColumn.implicitHeight, background.implicitHeight, rightTabsColumn.implicitHeight) + 32

    // sized so 2 tabs + the gap between them exactly spans the launcher
    // body's shortest possible height (empty stash - just the search box
    // and the "Nothing stashed" line, no grid) - searchBox/nothingStashedText
    // keep their own implicitHeight regardless of which mode is actually
    // showing, since Layouts still size invisible children, just exclude
    // them from the parent's total
    readonly property real tabSize: (searchBox.implicitHeight + mainColumn.spacing + nothingStashedText.implicitHeight - leftTabsColumn.spacing) / 2

    HyprlandFocusGrab {
        id: grab
        windows: [launcherWindow]
        active: Launcher.visible
        onCleared: Launcher.close()
    }

    RowLayout {
        id: outerRow
        anchors.centerIn: parent
        spacing: 6

        // first two modes (search, power) - top-left, bottom-left
        ColumnLayout {
            id: leftTabsColumn
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Repeater {
                model: Launcher.modes.slice(0, 2)

                ModeTab {
                    side: "left"
                    size: launcherWindow.tabSize
                }
            }
        }

        Rectangle {
            id: background
            radius: Theme.tooltipRadius
            color: Theme.tooltipBg
            border.color: Theme.tooltipBorder
            border.width: Theme.tooltipBorderWidth
            implicitWidth: mainColumn.implicitWidth + 32
            implicitHeight: mainColumn.implicitHeight + 32

            ColumnLayout {
                id: mainColumn
                anchors.centerIn: parent
                spacing: 12

                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    Layout.preferredWidth: 480 // floor so the box doesn't shrink to fit a couple of narrow search results
                    implicitHeight: searchInput.implicitHeight + 16
                    radius: 4
                    color: Qt.rgba(1, 1, 1, 0.08)
                    // shell/command mode gets its own border color so it's
                    // obvious at a glance whether ">" has actually engaged it
                    // (no space needed after ">" - this lights up immediately)
                    border.color: Launcher.prefixCommand === "shell" ? "#34C0EF" : Theme.tooltipBorder
                    border.width: Launcher.prefixCommand === "shell" ? 2 : 1
                    // TextInput doesn't clip its own overflow - without this, a
                    // query/result wider than the box renders straight past its
                    // left edge (TextInput scrolls its content left internally
                    // to keep the cursor in view once it's longer than the box)
                    clip: true

                    TextInput {
                        id: searchInput
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 8
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        anchors.rightMargin: resultLabel.visible ? resultLabel.implicitWidth + 20 : (iconStyleToggle.visible ? iconStyleToggle.implicitWidth + 20 : 8)
                        verticalAlignment: TextInput.AlignVCenter
                        focus: Launcher.visible
                        readOnly: Launcher.mode !== "search"
                        // Pinned/Power/Stash replace this box's role entirely
                        // with their own header text (below) - keep the typed
                        // query intact (so Tab-ing back to search restores it)
                        // but hide its rendering, rather than clearing it, so it
                        // doesn't show through behind those headers
                        opacity: Launcher.mode === "search" ? 1 : 0
                        text: Launcher.query
                        color: Theme.textColor
                        onTextChanged: Launcher.query = text
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Tab) {
                                Launcher.cycleMode();
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Escape) {
                                Launcher.close();
                                event.accepted = true;
                                return;
                            }
                            // when there's no grid to navigate (calc/google result,
                            // or a search with no matches), left/right fall through
                            // to the TextInput's normal cursor movement
                            if (event.key === Qt.Key_Left) {
                                if (Launcher.gridNavigable) {
                                    Launcher.moveSelection(-1, 0);
                                    event.accepted = true;
                                }
                                return;
                            }
                            if (event.key === Qt.Key_Right) {
                                if (Launcher.gridNavigable) {
                                    Launcher.moveSelection(1, 0);
                                    event.accepted = true;
                                }
                                return;
                            }
                            if (event.key === Qt.Key_Up) {
                                // collapse back to the compact preview when Up is
                                // pressed on the top row of the expanded app grid
                                if (Launcher.mode === "search" && Launcher.prefixCommand === "" && Launcher.appsExpanded && Math.floor(Launcher.selectedIndex / Launcher.columns) === 0) {
                                    Launcher.collapseApps();
                                    event.accepted = true;
                                    return;
                                }
                                Launcher.moveSelection(0, -1);
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Down) {
                                // Down from the compact app preview expands into
                                // the full scrollable grid before moving
                                if (Launcher.mode === "search" && Launcher.prefixCommand === "" && !Launcher.appsExpanded)
                                    Launcher.expandApps();

                                Launcher.moveSelection(0, 1);
                                event.accepted = true;
                                return;
                            }
                            if (Launcher.mode === "pinned") {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (event.modifiers & Qt.ShiftModifier)
                                        Launcher.revealSelectedInYazi();
                                    else
                                        Launcher.openSelectedPinned();
                                    event.accepted = true;
                                    return;
                                }
                                if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
                                    Launcher.unpinSelected();
                                    event.accepted = true;
                                    return;
                                }
                                return;
                            }
                            if (Launcher.prefixCommand === "kill") {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    Launcher.killSelected((event.modifiers & Qt.ShiftModifier) ? "-KILL" : "-TERM");
                                    event.accepted = true;
                                }
                                return;
                            }
                            if (Launcher.prefixCommand === "shell") {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    Launcher.runShellCommand();
                                    event.accepted = true;
                                }
                                return;
                            }
                            // search mode
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                // debug: Ctrl+Enter on a plain app tile reveals
                                // its .desktop file in yazi instead of launching it
                                if ((event.modifiers & Qt.ControlModifier) && Launcher.mode === "search" && Launcher.prefixCommand === "") {
                                    Launcher.debugOpenSelectedDesktopFile();
                                    event.accepted = true;
                                    return;
                                }
                                Launcher.activateSelected();
                                event.accepted = true;
                            }
                        }
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }
                        // keep the field in sync when the query gets reset elsewhere (eg. on open)
                        Connections {
                            target: Launcher

                            function onQueryChanged() {
                                if (searchInput.text !== Launcher.query)
                                    searchInput.text = Launcher.query;
                            }
                        }
                    }
                    Text {
                        anchors.fill: searchInput
                        verticalAlignment: Text.AlignVCenter
                        visible: Launcher.mode === "search" && searchInput.text.length === 0
                        text: "Search apps..."
                        opacity: 0.4
                        color: Theme.textColor

                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }
                    }
                    // inline calculator result, eg. "=8" - a bit grayer than the input text
                    Text {
                        id: resultLabel
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Launcher.mode === "search" && Launcher.calcResult.length > 0
                        text: "=" + Launcher.calcResult
                        color: Theme.textColor
                        opacity: 0.5

                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }
                    }
                    // icon-style toggle for the "s " (Steam/Epic) grid -
                    // switches whether tiles lead with the big cover/header/
                    // logo art (default) or the small 32x32 sidebar icon
                    // upscaled - persisted, see Games.preferHashIcon
                    Text {
                        id: iconStyleToggle
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Launcher.prefixCommand === "games"
                        text: Games.preferHashIcon ? String.fromCodePoint(0xf0c8f) : String.fromCodePoint(0xf0c8e)
                        color: Theme.textColor
                        opacity: 0.6

                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Games.toggleIconPreference()
                        }
                    }
                    // "Pinned" header, shown in place of the search text while in pinned mode
                    Text {
                        anchors.fill: searchInput
                        verticalAlignment: Text.AlignVCenter
                        visible: Launcher.mode === "pinned"
                        text: "Pinned"
                        opacity: 0.6
                        color: Theme.textColor

                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: true
                        }
                    }
                    // "Power" header, shown in place of the search text while in power mode
                    Text {
                        anchors.fill: searchInput
                        verticalAlignment: Text.AlignVCenter
                        visible: Launcher.mode === "power"
                        text: "Power"
                        opacity: 0.6
                        color: Theme.textColor

                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: true
                        }
                    }
                    // "Stash" header, shown in place of the search text while in stash mode
                    Text {
                        anchors.fill: searchInput
                        verticalAlignment: Text.AlignVCenter
                        visible: Launcher.mode === "stash"
                        text: "Stash"
                        opacity: 0.6
                        color: Theme.textColor

                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                            bold: true
                        }
                    }
                }
                // "g <query>" hint - no grid to show, just confirmation of what Enter will do
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.mode === "search" && Launcher.prefixCommand === "google"
                    text: "Press Enter to search Google for “" + Launcher.prefixArg + "”"
                    opacity: 0.6
                    color: Theme.textColor

                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }
                }
                // "><command>" status line - silent on success, only reports
                // the last run's failure (fish-prompt-exit-code style), and
                // persists until the next command replaces it
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 480
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    visible: Launcher.prefixCommand === "shell" && Launcher.shellStatus.length > 0
                    text: Launcher.shellStatus
                    color: "#e94b4b"
                    style: Theme.style
                    styleColor: Theme.styleColor

                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }
                }
                // 5 columns x up to 3 rows visible - the compact preview (1 row
                // empty / 3 rows capped searching) always fits within this, so
                // this only actually scrolls once Down has expanded the grid to
                // show every match
                Flickable {
                    id: appsFlick
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.mode === "search" && Launcher.prefixCommand === ""
                    implicitWidth: appsGrid.implicitWidth
                    implicitHeight: Math.min(appsGrid.implicitHeight, 3 * 96 + 2 * 4)
                    contentWidth: appsGrid.implicitWidth
                    contentHeight: appsGrid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    function ensureSelectedVisible() {
                        if (Launcher.mode !== "search" || Launcher.prefixCommand !== "")
                            return;

                        const row = Math.floor(Launcher.selectedIndex / Launcher.columns);
                        const rowTop = row * 100;
                        const rowBottom = rowTop + 96;
                        if (rowTop < appsFlick.contentY)
                            appsFlick.contentY = rowTop;
                        else if (rowBottom > appsFlick.contentY + appsFlick.height)
                            appsFlick.contentY = rowBottom - appsFlick.height;
                    }

                    Connections {
                        target: Launcher

                        function onSelectedIndexChanged() {
                            appsFlick.ensureSelectedVisible();
                        }
                        function onAppsExpandedChanged() {
                            if (!Launcher.appsExpanded)
                                appsFlick.contentY = 0;
                        }
                    }
                    GridLayout {
                        id: appsGrid
                        columns: Launcher.columns
                        rowSpacing: 4
                        columnSpacing: 4

                        Repeater {
                            model: Launcher.mode === "search" && Launcher.prefixCommand === "" ? Launcher.activeApps : []

                            AppTile {
                                required property var modelData

                                entry: modelData
                            }
                        }

                        // pinned files/folders matching the search - hidden
                        // on an empty query (see Launcher.matchingPinned),
                        // appended after the app tiles and sharing the same
                        // selectedIndex space via indexOffset
                        Repeater {
                            model: Launcher.mode === "search" && Launcher.prefixCommand === "" ? Launcher.matchingPinned : []

                            PinnedTile {
                                required property var modelData

                                path: modelData
                                indexOffset: Launcher.activeApps.length
                            }
                        }
                    }
                }
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.mode === "search" && Launcher.prefixCommand === "bookmarks"
                    columns: Launcher.columns
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: Launcher.mode === "search" && Launcher.prefixCommand === "bookmarks" ? Launcher.visibleBookmarks : []

                        BookmarkTile {
                            required property var modelData

                            entry: modelData
                        }
                    }
                }
                // "s <query>" - installed Steam/Epic games - scrolls, same
                // 5-wide/up-to-3-rows-then-scroll shape as stash/kill below
                Flickable {
                    id: gamesFlick
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.mode === "search" && Launcher.prefixCommand === "games"
                    implicitWidth: gamesGrid.implicitWidth
                    implicitHeight: Math.min(gamesGrid.implicitHeight, 3 * 96 + 2 * 4)
                    contentWidth: gamesGrid.implicitWidth
                    contentHeight: gamesGrid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    function ensureSelectedVisible() {
                        if (Launcher.prefixCommand !== "games")
                            return;

                        const row = Math.floor(Launcher.selectedIndex / Launcher.columns);
                        const rowTop = row * 100;
                        const rowBottom = rowTop + 96;
                        if (rowTop < gamesFlick.contentY)
                            gamesFlick.contentY = rowTop;
                        else if (rowBottom > gamesFlick.contentY + gamesFlick.height)
                            gamesFlick.contentY = rowBottom - gamesFlick.height;
                    }

                    Connections {
                        target: Launcher

                        function onSelectedIndexChanged() {
                            gamesFlick.ensureSelectedVisible();
                        }
                        function onPrefixCommandChanged() {
                            if (Launcher.prefixCommand === "games")
                                gamesFlick.contentY = 0;
                        }
                    }
                    GridLayout {
                        id: gamesGrid
                        columns: Launcher.columns
                        rowSpacing: 4
                        columnSpacing: 4

                        Repeater {
                            model: Launcher.mode === "search" && Launcher.prefixCommand === "games" ? Launcher.visibleGames : []

                            GameTile {
                                required property var modelData

                                entry: modelData
                                glyph: modelData.source === "steam" ? String.fromCodePoint(0xf04d3) : String.fromCodePoint(0xf0297)
                                iconCandidates: modelData.iconCandidates
                                activateFn: Launcher.launchGame
                            }
                        }
                    }
                }
                // "m <query>" - Prism Launcher (Minecraft) instances - scrolls too
                Flickable {
                    id: minecraftFlick
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.mode === "search" && Launcher.prefixCommand === "minecraft"
                    implicitWidth: minecraftGrid.implicitWidth
                    implicitHeight: Math.min(minecraftGrid.implicitHeight, 3 * 96 + 2 * 4)
                    contentWidth: minecraftGrid.implicitWidth
                    contentHeight: minecraftGrid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    function ensureSelectedVisible() {
                        if (Launcher.prefixCommand !== "minecraft")
                            return;

                        const row = Math.floor(Launcher.selectedIndex / Launcher.columns);
                        const rowTop = row * 100;
                        const rowBottom = rowTop + 96;
                        if (rowTop < minecraftFlick.contentY)
                            minecraftFlick.contentY = rowTop;
                        else if (rowBottom > minecraftFlick.contentY + minecraftFlick.height)
                            minecraftFlick.contentY = rowBottom - minecraftFlick.height;
                    }

                    Connections {
                        target: Launcher

                        function onSelectedIndexChanged() {
                            minecraftFlick.ensureSelectedVisible();
                        }
                        function onPrefixCommandChanged() {
                            if (Launcher.prefixCommand === "minecraft")
                                minecraftFlick.contentY = 0;
                        }
                    }
                    GridLayout {
                        id: minecraftGrid
                        columns: Launcher.columns
                        rowSpacing: 4
                        columnSpacing: 4

                        Repeater {
                            model: Launcher.mode === "search" && Launcher.prefixCommand === "minecraft" ? Launcher.visibleMinecraftInstances : []

                            GameTile {
                                required property var modelData

                                entry: modelData
                                glyph: String.fromCodePoint(0xf0373)
                                iconCandidates: modelData.icon.length > 0 ? ["file://" + modelData.icon] : []
                                activateFn: Launcher.launchMinecraftInstance
                            }
                        }
                    }
                }
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.mode === "pinned"
                    columns: Launcher.columns
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: Launcher.mode === "pinned" ? Launcher.pinnedPaths : []

                        PinnedTile {
                            required property var modelData

                            path: modelData
                        }
                    }
                }
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.mode === "power"
                    columns: Launcher.columns
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: Launcher.mode === "power" ? Launcher.powerOptions : []

                        PowerTile {
                            required property var modelData

                            entry: modelData
                        }
                    }
                }
                Text {
                    id: nothingStashedText
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.mode === "stash" && Launcher.stashSlots.length === 0
                    text: "Nothing stashed"
                    opacity: 0.6
                    color: Theme.textColor

                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }
                }
                // 5 columns x up to 3 rows visible at once - unlike the other
                // modes (which just cap how many items show), the stash can grow
                // past 15 with no natural limit, so this one actually scrolls
                // instead of truncating
                Flickable {
                    id: stashFlick
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.mode === "stash" && Launcher.stashSlots.length > 0
                    implicitWidth: stashGrid.implicitWidth
                    implicitHeight: Math.min(stashGrid.implicitHeight, 3 * 96 + 2 * 4)
                    contentWidth: stashGrid.implicitWidth
                    contentHeight: stashGrid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    function ensureSelectedVisible() {
                        if (Launcher.mode !== "stash")
                            return;

                        const row = Math.floor(Launcher.selectedIndex / Launcher.columns);
                        const rowTop = row * 100;
                        const rowBottom = rowTop + 96;
                        if (rowTop < stashFlick.contentY)
                            stashFlick.contentY = rowTop;
                        else if (rowBottom > stashFlick.contentY + stashFlick.height)
                            stashFlick.contentY = rowBottom - stashFlick.height;
                    }

                    Connections {
                        target: Launcher

                        function onSelectedIndexChanged() {
                            stashFlick.ensureSelectedVisible();
                        }
                        function onModeChanged() {
                            if (Launcher.mode === "stash")
                                stashFlick.contentY = 0;
                        }
                    }
                    GridLayout {
                        id: stashGrid
                        columns: Launcher.columns
                        rowSpacing: 4
                        columnSpacing: 4

                        Repeater {
                            model: Launcher.mode === "stash" ? Launcher.stashSlots : []

                            StashTile {
                                required property var modelData

                                entry: modelData
                            }
                        }
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.prefixCommand === "kill" && Launcher.killWindows.length === 0
                    text: "No open windows"
                    opacity: 0.6
                    color: Theme.textColor

                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize
                    }
                }
                // "kill <filter>" - same 5-wide, up-to-3-rows-then-scroll shape
                // as the stash grid above; Enter sends SIGTERM, Shift+Enter
                // SIGKILL, to the selected window's pid (see LauncherWindow's
                // Keys.onPressed and Launcher.killSelected)
                Flickable {
                    id: killFlick
                    Layout.alignment: Qt.AlignHCenter
                    visible: Launcher.prefixCommand === "kill" && Launcher.killWindows.length > 0
                    implicitWidth: killGrid.implicitWidth
                    implicitHeight: Math.min(killGrid.implicitHeight, 3 * 96 + 2 * 4)
                    contentWidth: killGrid.implicitWidth
                    contentHeight: killGrid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    function ensureSelectedVisible() {
                        if (Launcher.prefixCommand !== "kill")
                            return;

                        const row = Math.floor(Launcher.selectedIndex / Launcher.columns);
                        const rowTop = row * 100;
                        const rowBottom = rowTop + 96;
                        if (rowTop < killFlick.contentY)
                            killFlick.contentY = rowTop;
                        else if (rowBottom > killFlick.contentY + killFlick.height)
                            killFlick.contentY = rowBottom - killFlick.height;
                    }

                    Connections {
                        target: Launcher

                        function onSelectedIndexChanged() {
                            killFlick.ensureSelectedVisible();
                        }
                        function onQueryChanged() {
                            if (Launcher.prefixCommand === "kill")
                                killFlick.contentY = 0;
                        }
                    }
                    GridLayout {
                        id: killGrid
                        columns: Launcher.columns
                        rowSpacing: 4
                        columnSpacing: 4

                        Repeater {
                            model: Launcher.prefixCommand === "kill" ? Launcher.killWindows : []

                            KillTile {
                                required property var modelData

                                entry: modelData
                            }
                        }
                    }
                }
            }
        }

        // last two modes (pinned, stash) - top-right, bottom-right
        ColumnLayout {
            id: rightTabsColumn
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Repeater {
                model: Launcher.modes.slice(2)

                ModeTab {
                    side: "right"
                    size: launcherWindow.tabSize
                }
            }
        }
    }
}
