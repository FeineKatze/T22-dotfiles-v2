pragma Singleton
import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io
import "vdf.js" as Vdf

// Installed-game indexing for the launcher's "s <query>" (Steam/Epic) and
// "m <query>" (Prism Launcher/Minecraft instances) prefixes.
//
// Steam and Epic are both read straight off local metadata files (no
// network calls): Steam's libraryfolders.vdf + one appmanifest_<id>.acf per
// installed game, Epic via Heroic's bundled legendary installed.json (Epic
// has no native Linux client - Heroic/legendary is this machine's
// equivalent). Prism has no single manifest file, so its instances are
// listed by shelling out (same idiom as Bookmarks.qml's sqlite read).
QtObject {
    id: root

    readonly property string steamRoot: Quickshell.env("HOME") + "/.local/share/Steam"
    readonly property string epicInstalledPath: Quickshell.env("HOME") + "/.config/heroic/legendaryConfig/legendary/installed.json"

    // Prism has no single per-machine manifest the way Steam/Epic do (its
    // "installed games" are just directories), and unlike Steam's
    // libraryfolders.vdf there's nothing to auto-discover a second data dir
    // from - so the second-disk one is hardcoded here same as the default.
    // Each is a full Prism data dir (instances/, icons/, mods/, ...), scanned
    // for its own "instances" subfolder; -d picks the matching one back out
    // at launch time (see launchMinecraftInstance)
    readonly property var prismRoots: [Quickshell.env("HOME") + "/.local/share/PrismLauncher", "/run/media/christopher/Volume/PrismLauncher"]

    // Prism's *built-in* instance icons (the Minecraft-block set shown in
    // its own icon picker) are compiled straight into the prismlauncher
    // binary as a Qt resource (":/icons/multimc/...", confirmed via
    // `strings` on /usr/bin/prismlauncher) - there's no loose file on disk
    // to point an Image at. The same SVGs are checked into the
    // PrismLauncher/PrismLauncher repo under this path (verified via the
    // GitHub API), and PrismLauncher/Themes carries alternate icon packs
    // but not extra names, so this is the actual complete default set.
    // Fetched once to a local cache dir and used as a fallback tier below
    // the per-root custom icons/ lookup, so eg. a plain "grass" instance
    // finally gets a real image instead of just the glyph.
    readonly property string builtinIconCacheDir: Quickshell.env("HOME") + "/.cache/quickshell/prismlauncher-icons"
    readonly property string builtinIconBaseUrl: "https://raw.githubusercontent.com/PrismLauncher/PrismLauncher/develop/launcher/resources/multimc/scalable/instances/"
    readonly property var builtinIconNames: ["bee", "bee_legacy", "brick", "chicken", "creeper", "diamond", "dirt", "enderman", "enderpearl", "fabricmc", "flame", "fox", "fox_legacy", "ftb_logo", "gear", "gold", "grass", "herobrine", "iron", "magitech", "meat", "modrinth", "neoforged", "netherstar", "planks", "prismlauncher", "quiltmc", "skeleton", "squarecreeper", "steve", "stone", "tnt"]

    property Process builtinIconFetchProcess: Process {
        command: ["bash", "-c", `
            set -e
            dir="$1"; base="$2"; shift 2
            mkdir -p "$dir"
            for name in "$@"; do
                dest="$dir/$name.svg"
                [ -s "$dest" ] && continue
                curl -sL --max-time 5 -o "$dest" "$base$name.svg" || rm -f "$dest"
            done
        `, "_", root.builtinIconCacheDir, root.builtinIconBaseUrl].concat(root.builtinIconNames)
        onExited: {
            running = false;
            root.prismScanProcess.running = true;
        }
    }

    function refresh() {
        root.libraryFoldersFile.reload();
        root.epicInstalledFile.reload();
        root.prismScanProcess.running = true;
        root.steamIconScanProcess.running = true;
    }

    // whether Steam tiles default to the small 32x32 sidebar icon (upscaled)
    // ahead of the big cover/header/logo art, instead of behind it - a
    // toggle in the "s " grid (LauncherWindow.qml) flips this. Persisted the
    // same way Launcher.qml's pinned/usage state is. Epic has no equivalent
    // small-icon asset, so this only reorders Steam's own candidates
    property bool preferHashIcon: false

    property FileView iconPrefFileView: FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell/launcher-games-icon-pref.json"
        watchChanges: true
        blockWrites: false
        printErrors: true

        adapter: JsonAdapter {
            id: iconPrefAdapter
            property bool preferHashIcon: false
        }

        onLoaded: root.preferHashIcon = iconPrefAdapter.preferHashIcon
        onLoadFailed: error => root.preferHashIcon = false
    }

    function toggleIconPreference() {
        root.preferHashIcon = !root.preferHashIcon;
        iconPrefAdapter.preferHashIcon = root.preferHashIcon;
        root.iconPrefFileView.writeAdapter();
    }

    // Steam's per-game artwork (what its own "Customization" panel calls
    // Cover/Background/Logo/etc) isn't always at the fixed top-level path
    // (<cacheDir>/<appid>/library_600x900.jpg) - some games have it nested
    // one level deeper under an extra hash-named directory instead
    // (<appid>/<hash>/library_capsule.jpg - same 300x450 image, just an
    // alternate filename Steam also uses for "Cover"), for reasons that
    // seem to depend on when/how it was cached. A single `find` across the
    // whole cache dir (fast - a few ms) catches both layouts, and also
    // picks up the small 32x32 sidebar icon (also hash-named, no fixed
    // path) as a last-resort candidate for the handful of games with
    // nothing else cached.
    readonly property string steamCacheDir: root.steamRoot + "/appcache/librarycache"

    property var steamIconIndex: ({}) // appid -> {cover, header, logo, hashicon}, each a "file://" URL or undefined

    property Process steamIconScanProcess: Process {
        command: ["bash", "-c", `
            cacheDir="$1"
            find "$cacheDir" -maxdepth 3 -type f \\( -name "library_600x900.jpg" -o -name "library_capsule.jpg" -o -name "header.jpg" -o -name "library_header.jpg" -o -name "logo.png" -o -regextype posix-extended -regex '.*/[0-9a-f]{40}\\.jpg' \\) 2>/dev/null | while read -r f; do
                rel="${"$"}{f#$cacheDir/}"
                appid="${"$"}{rel%%/*}"
                base="$(basename "$f")"
                case "$base" in
                    library_600x900.jpg|library_capsule.jpg) kind="cover" ;;
                    header.jpg|library_header.jpg) kind="header" ;;
                    logo.png) kind="logo" ;;
                    *) kind="hashicon" ;;
                esac
                printf "%s\\t%s\\t%s\\n" "$appid" "$kind" "$f"
            done
        `, "_", root.steamCacheDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const index = {};
                for (const line of text.split("\n").filter(l => l.length > 0)) {
                    const [appid, kind, path] = line.split("\t");
                    if (!index[appid])
                        index[appid] = {};
                    // first match wins per kind (only relevant if a game
                    // somehow has the same filename cached in two places)
                    if (!index[appid][kind])
                        index[appid][kind] = "file://" + path;
                }
                root.steamIconIndex = index;
            }
        }
        onExited: running = false
    }

    // --- Steam ---
    // phase 1: libraryfolders.vdf gives every library path plus the
    // installed appids in each (Steam already tracks that mapping itself -
    // no need to glob for appmanifest files by hand)
    property FileView libraryFoldersFile: FileView {
        id: libraryFoldersFile
        path: root.steamRoot + "/steamapps/libraryfolders.vdf"
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                const parsed = Vdf.parse(libraryFoldersFile.text());
                const folders = parsed.libraryfolders ?? {};
                const libs = [];
                for (const key of Object.keys(folders)) {
                    const lib = folders[key];
                    if (!lib.path)
                        continue;
                    libs.push({
                        path: lib.path,
                        appIds: lib.apps ? Object.keys(lib.apps) : []
                    });
                }
                root.steamLibraries = libs;
            } catch (e) {
                root.steamLibraries = [];
            }
        }
        onLoadFailed: error => root.steamLibraries = []
        onFileChanged: libraryFoldersFile.reload()
    }

    property var steamLibraries: []

    // flat list of every appmanifest path across every library - drives the
    // Instantiator below, which does the actual per-file reading (phase 2)
    readonly property var steamManifestPaths: {
        const paths = [];
        for (const lib of root.steamLibraries)
            for (const id of lib.appIds)
                paths.push(lib.path + "/steamapps/appmanifest_" + id + ".acf");
        return paths;
    }

    // keyed by path (not appid) so re-deriving steamManifestPaths - eg. a
    // library reloading - doesn't lose already-parsed entries while the
    // rest are still loading
    property var _steamGamesByPath: ({})

    // iconCandidates built here (not baked in at manifest-read time) so it
    // stays reactive to both steamIconIndex (which usually finishes loading
    // separately/later than any given manifest) and preferHashIcon
    readonly property var steamGames: {
        const list = Object.values(root._steamGamesByPath).map(g => {
            const icons = root.steamIconIndex[g.id] ?? {};
            const big = [];
            if (icons.cover)
                big.push(icons.cover);
            if (icons.header)
                big.push(icons.header);
            if (icons.logo)
                big.push(icons.logo);
            const small = icons.hashicon ? [icons.hashicon] : [];
            return Object.assign({}, g, {
                iconCandidates: root.preferHashIcon ? small.concat(big) : big.concat(small)
            });
        });
        list.sort((a, b) => a.name.localeCompare(b.name));
        return list;
    }

    property Instantiator steamManifestInstantiator: Instantiator {
        model: root.steamManifestPaths

        FileView {
            id: manifestFile
            required property string modelData
            path: modelData
            printErrors: false

            onLoaded: {
                try {
                    const state = Vdf.parse(manifestFile.text()).AppState;
                    if (!state || !state.appid || !state.name)
                        return;
                    const map = Object.assign({}, root._steamGamesByPath);
                    map[manifestFile.path] = {
                        id: state.appid,
                        name: state.name,
                        source: "steam"
                    };
                    root._steamGamesByPath = map;
                } catch (e) {}
            }
        }
    }

    function launchSteamGame(id) {
        Quickshell.execDetached(["xdg-open", "steam://rungameid/" + id]);
    }

    // --- Epic (via Heroic's bundled legendary) ---
    // Heroic's own downloaded icon cache (~/.config/heroic/icons/<name>.jpg)
    // turns out to be unreliable - most of what's there is left mid-rename
    // as "<name>.jpg.$$0" (or higher $$N, one per retry), and for some
    // games every numbered variant is a genuinely truncated download (found
    // by actually decoding pixel data, not just the header - PIL's lazy
    // open() doesn't catch it, but Qt's Image does try to render the
    // truncated result instead of failing cleanly, which is worse than
    // just falling to the glyph). legendary's own per-game metadata cache
    // is the reliable source instead - it's what Heroic's own "Edit Game"
    // art picker reads from - so that's fetched (once, then cached
    // locally) as the primary source now, with the old local icon cache
    // kept only as a last-resort fallback.
    readonly property string epicMetadataDir: Quickshell.env("HOME") + "/.config/heroic/legendaryConfig/legendary/metadata"
    readonly property string epicCoverCacheDir: Quickshell.env("HOME") + "/.cache/quickshell/epic-covers"

    property var _epicRawGames: [] // [{id, name, source}], no iconCandidates - see epicGames below
    property int epicCoverFetchTick: 0 // bumped when epicCoverFetchProcess finishes, to re-derive epicGames

    property FileView epicInstalledFile: FileView {
        id: epicInstalledFile
        path: root.epicInstalledPath
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(epicInstalledFile.text());
                root._epicRawGames = Object.values(data).map(g => ({
                            id: g.app_name,
                            name: g.title,
                            source: "epic"
                        }));
                root.epicCoverFetchProcess.running = true;
            } catch (e) {
                root._epicRawGames = [];
            }
        }
        onLoadFailed: error => root._epicRawGames = []
        onFileChanged: epicInstalledFile.reload()
    }

    // fetches DieselGameBoxTall (or DieselGameBox as a wider fallback) from
    // each installed game's own legendary metadata json and caches it
    // locally by app_name - skips anything already cached, so re-running
    // (eg. every refresh()) is cheap
    property Process epicCoverFetchProcess: Process {
        command: ["python3", "-c", `
import sys, json, os, urllib.request

metaDir, cacheDir = sys.argv[1], sys.argv[2]
appNames = sys.argv[3:]
os.makedirs(cacheDir, exist_ok=True)

for name in appNames:
    dest = os.path.join(cacheDir, name + ".jpg")
    if os.path.exists(dest) and os.path.getsize(dest) > 0:
        continue
    metaPath = os.path.join(metaDir, name + ".json")
    if not os.path.exists(metaPath):
        continue
    try:
        data = json.load(open(metaPath))
        imgs = data.get("metadata", {}).get("keyImages", data.get("keyImages", []))
        url = next((im.get("url") for im in imgs if im.get("type") == "DieselGameBoxTall"), None)
        if not url:
            url = next((im.get("url") for im in imgs if im.get("type") == "DieselGameBox"), None)
        if not url:
            continue
        urllib.request.urlretrieve(url, dest)
    except Exception:
        pass
`, root.epicMetadataDir, root.epicCoverCacheDir].concat(root._epicRawGames.map(g => g.id))
        onExited: {
            running = false;
            root.epicCoverFetchTick += 1;
        }
    }

    readonly property var epicGames: {
        const iconDir = Quickshell.env("HOME") + "/.config/heroic/icons/";
        const fetchDep = root.epicCoverFetchTick; // establishes recompute-on-fetch-finish
        return root._epicRawGames.map(g => Object.assign({}, g, {
                    iconCandidates: ["file://" + root.epicCoverCacheDir + "/" + g.id + ".jpg", "file://" + iconDir + g.id + ".jpg", "file://" + iconDir + g.id + ".jpg.$$0"]
                }));
    }

    function launchEpicGame(id) {
        Quickshell.execDetached(["xdg-open", "heroic://launch/legendary/" + id]);
    }

    // not real games - Steam tracks its own Proton builds and runtime
    // containers as regular installed "apps" with their own appmanifest,
    // so they'd otherwise show up right alongside actual games. Name-based
    // since new Proton versions ship periodically and each gets a new
    // appid - this way a future one is excluded automatically without
    // needing an update here
    readonly property var blacklistedNamePatterns: [/^Proton\b/i, /^Steam Linux Runtime\b/i, /^Steamworks Common Redistributables$/i]

    // specific entries with no reasonable pattern to match on - eg. Epic's
    // Civilization VI DLC/scenario packs, which each install as their own
    // separate "game" (app_name "Kinglet*") alongside the base game
    // (app_name "Kinglet" itself, kept) and only clutter the list
    readonly property var blacklistedIds: ["KingletAustralia", "KingletAztec", "KingletGatheringStorm", "KingletKhmerIndonesia", "KingletNubia", "KingletPersiaMacedon", "KingletPoland", "KingletRiseAndFall", "KingletVikingsScenario"]

    function isBlacklisted(entry) {
        if (root.blacklistedIds.includes(entry.id))
            return true;
        return root.blacklistedNamePatterns.some(re => re.test(entry.name));
    }

    // combined list the "s " prefix searches - alphabetical, Steam/Epic
    // mixed together (each entry carries its own `source` for launching)
    readonly property var allGames: {
        const list = root.steamGames.concat(root.epicGames).filter(g => !root.isBlacklisted(g));
        list.sort((a, b) => a.name.localeCompare(b.name));
        return list;
    }

    function launchGame(entry) {
        if (entry.source === "steam")
            root.launchSteamGame(entry.id);
        else if (entry.source === "epic")
            root.launchEpicGame(entry.id);
    }

    // --- Prism Launcher (Minecraft instances) ---
    // no single manifest file to read - list each root's instance folders
    // and pull the display name + iconKey out of instance.cfg (an .ini
    // file, not VDF). iconKey usually names one of Prism's own built-in
    // Minecraft-block icons - no file on disk for those under the instance
    // root itself, but builtinIconFetchProcess mirrors that exact set
    // locally (see above), checked here as a second tier. A modpack-provided
    // icon (curseforge_*/modrinth_*, or a custom-set image) is a real file
    // under the root's own icons/ dir and takes priority, extension unknown
    // in advance
    property var minecraftInstances: [] // [{root, id, name, icon}] - id is the instance's folder name, what --launch expects; icon is "" when none found

    property Process prismScanProcess: Process {
        command: ["bash", "-c", `
            builtindir="$1"; shift
            for root in "$@"; do
                dir="$root/instances"
                [ -d "$dir" ] || continue
                icondir="$root/icons"
                shopt -s nullglob
                for d in "$dir"/*/; do
                    id="$(basename "$d")"
                    name="$(grep -m1 "^name=" "$d/instance.cfg" 2>/dev/null | cut -d= -f2-)"
                    key="$(grep -m1 "^iconKey=" "$d/instance.cfg" 2>/dev/null | cut -d= -f2-)"
                    icon=""
                    if [ -n "$key" ]; then
                        # Prism's own IconList.cpp aliases the "default" key
                        # to its grass icon (confirmed in its source) -
                        # match that here, or every un-customized instance
                        # (the single biggest group) falls back to the glyph
                        [ "$key" = "default" ] && key="grass"
                        for f in "$icondir/$key" "$icondir/$key".* "$builtindir/$key.svg" "$builtindir/${"$"}{key%_legacy}.svg"; do
                            [ -f "$f" ] && { icon="$f"; break; }
                        done
                    fi
                    printf "%s\\t%s\\t%s\\t%s\\n" "$root" "$id" "${"$"}{name:-$id}" "$icon"
                done
            done
        `, "_", root.builtinIconCacheDir].concat(root.prismRoots)
        stdout: StdioCollector {
            onStreamFinished: {
                root.minecraftInstances = text.split("\n").filter(l => l.length > 0).map(l => {
                    const [instRoot, id, name, icon] = l.split("\t");
                    return {
                        root: instRoot,
                        id: id,
                        name: name,
                        icon: icon ?? ""
                    };
                });
            }
        }
        onExited: running = false
    }

    function launchMinecraftInstance(entry) {
        // no -d: Prism's own config already points at wherever its real
        // data dir is (the second-disk one, on this machine) - passing -d
        // explicitly overrides that with whichever of prismRoots the
        // instance was scanned from, which for the (always-empty, so far)
        // default root opens Prism's first-run setup instead of launching
        // anything. entry.root is still used for icon resolution above.
        Quickshell.execDetached(["prismlauncher", "--launch", entry.id]);
    }

    Component.onCompleted: {
        root.refresh();
        root.builtinIconFetchProcess.running = true;
    }
}
