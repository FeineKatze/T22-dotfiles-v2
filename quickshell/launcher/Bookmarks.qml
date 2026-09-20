pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Reads browser bookmarks for the "b <query>" launcher prefix. Firefox/Floorp
// keep bookmarks in a locked-while-running sqlite db, so this shells out to
// copy it to our cache dir first, then queries the copy - see refreshProcess.
QtObject {
    id: root

    property var allBookmarks: [] // [{ title, url }]

    function refresh() {
        root.refreshProcess.running = true;
    }

    property Process refreshProcess: Process {
        command: ["bash", "-c", `
            set -e
            cache="${Quickshell.env("HOME")}/.cache/quickshell"
            mkdir -p "$cache"
            src=$(find "${Quickshell.env("HOME")}/.floorp" "${Quickshell.env("HOME")}/.mozilla/firefox" -maxdepth 2 -name "places.sqlite" -printf "%T@ %p\\n" 2>/dev/null | sort -rn | head -1 | cut -d" " -f2-)
            if [ -z "$src" ]; then exit 0; fi
            cp "$src" "$cache/launcher-bookmarks.sqlite"
            cp "$src-wal" "$cache/launcher-bookmarks.sqlite-wal" 2>/dev/null || true
            cp "$src-shm" "$cache/launcher-bookmarks.sqlite-shm" 2>/dev/null || true
            sqlite3 -readonly -separator $'\\t' "$cache/launcher-bookmarks.sqlite" "SELECT b.title, p.url FROM moz_bookmarks b JOIN moz_places p ON b.fk = p.id WHERE b.type = 1 AND b.title IS NOT NULL AND b.title != '' AND p.url NOT LIKE 'place:%' ORDER BY b.lastModified DESC;"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = new Set();
                root.allBookmarks = text.split("\n").filter(line => line.length > 0).map(line => {
                    const tab = line.indexOf("\t");
                    return {
                        title: line.slice(0, tab),
                        url: line.slice(tab + 1)
                    };
                }).filter(b => {
                    // same bookmark filed in multiple folders shows up as one row per
                    // folder - keep only the first (most recently modified, per ORDER BY above)
                    const key = b.title + "\t" + b.url;
                    if (seen.has(key))
                        return false;
                    seen.add(key);
                    return true;
                });
            }
        }
        onExited: running = false
    }
}
