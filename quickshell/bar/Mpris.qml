import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../shared"

// Waybar-style mpris box: icon only, custom tooltip below, click = play/pause
Rectangle {
    id: root

    // prefer an actively playing player, then paused, then stopped - so a
    // leftover player (eg. a YouTube hover-preview) doesn't stick once
    // something else starts. Position isn't a usable liveness signal here:
    // MPRIS senders aren't required to (and often don't) push Position
    // updates while playing, only playbackState changes are spec-guaranteed
    // to notify - an earlier version of this tried polling position for
    // staleness and it misfired, treating genuinely-playing background
    // players (eg. YT Music) as stale ghosts.
    function playerRank(p) {
        if (p.playbackState === MprisPlaybackState.Playing)
            return 0;
        if (p.playbackState === MprisPlaybackState.Paused)
            return 1;
        return 2;
    }

    readonly property MprisPlayer player: {
        const list = Mpris.players.values;
        if (list.length === 0)
            return null;
        let best = list[0];
        for (const p of list) {
            if (root.playerRank(p) < root.playerRank(best))
                best = p;
        }
        return best;
    }
    readonly property bool playing: player && player.playbackState === MprisPlaybackState.Playing

    // Property to hold the actively updating position
    property real currentPos: player ? player.position : 0

    // player.length can misreport partway into playback on some backends
    // (eg. browser tabs mid-buffering), briefly dropping to match the
    // current position - which would make the tooltip show currentPos on
    // both sides. Cache the largest length seen per-track so a bogus lower
    // reading doesn't stick; reset the cache when the track actually changes.
    property real cachedLength: 0
    property string trackKey: ""

    function refreshLength() {
        if (!root.player) {
            root.cachedLength = 0;
            root.trackKey = "";
            return;
        }
        const key = root.player.trackTitle + "|" + root.player.trackArtist;
        if (key !== root.trackKey) {
            root.trackKey = key;
            root.cachedLength = root.player.length;
        } else if (root.player.length > root.cachedLength) {
            root.cachedLength = root.player.length;
        }
    }

    onPlayerChanged: root.refreshLength()

    Connections {
        target: root.player
        function onLengthChanged() {
            root.refreshLength();
        }
        function onTrackTitleChanged() {
            root.refreshLength();
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds <= 0) {
            return "00:00:00";
        }

        let totalSeconds = Math.floor(seconds);
        let hours = Math.floor(totalSeconds / 3600);
        let minutes = Math.floor((totalSeconds % 3600) / 60);
        let secs = Math.floor(totalSeconds % 60);

        let pad = n => n.toString().padStart(2, '0');

        return pad(hours) + ":" + pad(minutes) + ":" + pad(secs);
    }

    // Timer that ticks every 1 second ONLY when hovering and playing
    Timer {
        interval: 1000
        running: mouseArea.containsMouse && root.playing
        repeat: true
        onTriggered: {
            if (root.player) {
                root.currentPos = root.player.position;
                root.refreshLength();
            }
        }
    }

    // always visible - shows a "no player" glyph instead of disappearing,
    // so the bar's widget layout doesn't jump around as players come/go
    implicitWidth: label.implicitWidth + 19
    implicitHeight: Theme.barHeight
    radius: Theme.barRadius
    color: Theme.pillBg

    Text {
        id: label
        anchors.centerIn: parent
        text: root.player ? (root.playing ? "⏸" : "▶") : String.fromCodePoint(0xf075b)
        color: Theme.textColor
        style: Theme.style
        styleColor: Theme.styleColor
        font {
            family: Theme.fontFamily
            pointSize: Theme.pointSize
            bold: Theme.fontBold
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.player && root.player.togglePlaying()
        cursorShape: Qt.PointingHandCursor

        // Instantly update the position the moment the mouse enters
        onContainsMouseChanged: {
            if (containsMouse && root.player) {
                root.currentPos = root.player.position;
                root.refreshLength();
            }
        }
    }

    // --- custom tooltip ---
    PopupWindow {
        id: tooltipPopup

        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6 // gap between button and tooltip

        implicitWidth: tooltipLabel.implicitWidth + 16
        implicitHeight: tooltipLabel.implicitHeight + 10
        color: "transparent" // let the inner Rectangle draw bg/border/radius

        visible: mouseArea.containsMouse && root.player !== null

        Rectangle {
            anchors.fill: parent
            radius: Theme.tooltipRadius
            color: Theme.tooltipBg
            border.color: Theme.tooltipBorder
            border.width: Theme.tooltipBorderWidth

            Text {
                id: tooltipLabel
                anchors.centerIn: parent
                color: Theme.textColor
                style: Theme.style
                styleColor: Theme.styleColor
                font.pixelSize: Theme.fontSize
                font.bold: Theme.fontBold
                font.family: Theme.fontFamily
                textFormat: Text.RichText
                text: root.player ? (root.player.trackTitle || "Unknown") + " – " + (root.player.trackArtist || "Unknown Artist") + "<br>" + "[" + (root.formatTime(root.currentPos) + "/" + (root.formatTime(root.cachedLength)) + "]" || "Unknown length") : ""
            }
        }
    }
}
