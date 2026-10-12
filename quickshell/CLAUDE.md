# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## What this is

A [Quickshell](https://quickshell.outfoxxed.me/) desktop shell for Hyprland, written entirely in QML: top bar, notifications, launcher, alt-tab switcher, notes window, alarms/calendar center, network panel, volume OSD and a polkit agent. Quickshell 0.3.0 (Arch package). No build system, no tests, no CI. It is a git repo (`master`, dotfiles-style commits) and auto-reloads on file save.

## Commands

- Run: `qs` (or `quickshell`) auto-loads `shell.qml` from this directory.
- Full restart: `qs kill && qs & disown`. Run `qs` in the foreground to see real QML errors when a restart fails.
- Lint: `qmllint <File>.qml`. Format: `qmlformat <File>.qml`. No project lint config.
- Logs: `qs log` (or `/run/user/1000/quickshell/by-id/<id>/log.qslog`). Check after a reload; silently dropped delegates and `qt.svg.draw` warnings show up there, not as errors.
- IPC (used by Hyprland binds in `~/.config/hypr/modules/`): `qs ipc call launcher|notes|notifications|switcher toggle`, plus `switcher next|prev|confirm|cancel` for the hold-to-cycle alt-tab submap.
- `.qmlls.ini` is a symlink into a Quickshell runtime dir. Don't hand-edit it.

## Hot reload vs restart (important)

- Editing existing files hot-reloads.
- A **brand-new singleton**, or an **existing singleton gaining a new `import`**, needs a full `qs kill && qs &` restart. Hot reload does not register it.
- Singletons are `pragma Singleton` + `QtObject` roots. `QtObject` has no default property, so children (`Instantiator`, `FileView`, `Process`) must be assigned to named properties, e.g. `property Instantiator x: Instantiator {...}`. A bare child fails with "Cannot assign to non-existent default property".
- Every module directory has a `qmldir` listing its types (`singleton Foo 1.0 Foo.qml` / `Foo 1.0 Foo.qml`). A new file must be added there. `shell.qml` imports each module dir (`import "./launcher"` etc.), and `shared/` is imported as `"../shared"` from inside modules.

## Layout

Modules, one directory each. `shell.qml` is the entry point (`//@ pragma UseQApplication`).

- `shell.qml`: `IpcHandler`s, one `PanelWindow` bar per monitor (via `Variants` over `Quickshell.screens`), and the global windows (`Center`, `HotCorner`, `VolumeOsd`, `PolkitDialog`, `LauncherWindow`, `NotesWindow`, per-screen `SwitcherWindow`, `Popups`).
- `shared/Theme.qml`: singleton with all colors, fonts, radii and bar sizing. Use it instead of literals.
- `bar/`: bar widgets, composed left to right in `shell.qml`: `Workspaces`, `Tray`, `Mpris`, `ActiveWindow`, `Network`, `Pipewire`, `Clock`, `Power`.
- `notifications/`: `Notifications` singleton (DBus server, history, local `notifyLocal`), `Popups` (toast window), `Center` (history panel), `HotCorner`.
- `launcher/`: `Launcher` singleton + `LauncherWindow`. Modes (`search`, `power`, `pinned`, `stash`) and prefix commands in the search box: `g ` (web search), `b ` (bookmarks), `kill `, `s ` (Steam/Epic games), `m ` (Prism/Minecraft instances), `>` (shell), plus calculator/unit/currency conversion (`calculator.js`, `converter.js`). `Bookmarks` (Floorp sqlite), `Games` (see below), tile components per grid (`AppTile`, `PinnedTile`, `BookmarkTile`, `GameTile`, `KillTile`, `StashTile`, `PowerTile`).
- `switcher/`: Win7-style alt-tab, `displayMode` picks focused monitor vs all.
- `notes/`: floating notes window (text notes + checklists, Ctrl+1-9 slots).
- `alarms/`: alarms, timers, appointments, Bavarian holiday/school-holiday ICS data, settings; surfaced via `bar/Clock.qml`.
- `network/`: `Connectivity` singleton + `NetworkCenter` popup (Wi-Fi and Bluetooth tabs) opened from `bar/Network.qml`.
- `osd/`: volume/network OSD. `polkit/`: polkit agent dialog.

## Conventions and gotchas

- Style: font `"JetBrainsMono Nerd Font Propo"`, bold, text `#B0E0E6`; translucent dark fills; tooltips/popups use `Theme.tooltipBg`/`tooltipBorder`/`tooltipRadius`. Nerd Font glyphs are written as `String.fromCodePoint(0xF....)`. Verify a codepoint exists in the font before using it.
- Popup + tab-chip pattern: copy from `bar/Clock.qml` / `alarms/AlarmsCenter.qml` (`PopupWindow` + `HyprlandFocusGrab { windows; active; onCleared }`). Use **one** shared focus grab for multi-window surfaces (see the switcher in `shell.qml`); several simultaneous grabs fight each other.
- Perf pattern: timers/polling run only while visible/hovered (see `Mpris.qml`).
- Fullscreen handling: a top-layer surface can render *under* a fullscreen window while still capturing pointer input. The bar unmaps on fullscreen monitors (`shell.qml`), and `notifications/Popups.qml` picks the first monitor in `monitorOrder` with no fullscreen client **and** no window matching `mouseGrabAppPatterns` (windowed games that capture the pointer, currently Minecraft). Add regexes there for other games.
- Machine-specific: `shell.qml`'s `wsRanges` (`DP-1` 1-5, `DP-2` 6-10, `HDMI-A-1` 11-13) and `Popups.qml`'s `monitorOrder` hardcode this machine's three monitors (all scale 1). Prism roots in `Games.prismRoots` include a second-disk path (`/run/media/christopher/Volume/PrismLauncher`).
- Hyprland's `HyprlandToplevel` has no `class` property. Use `(t.lastIpcObject && t.lastIpcObject.class) ? t.lastIpcObject.class : ""`.
- Qt Quick `clip: true` clips to the bounding box only, never to a rounded `radius`. Per-item `MultiEffect` masking does not scale (GPU buffer exhaustion at ~47 tiles); rounded tile corners use a pre-rendered PNG overlay (`launcher/assets/corner-cover.png`, see `GameTile.qml`).
- `Quickshell.iconPath` resolves once per binding. A newly installed app's icon may not appear until `qs` restarts (a tick-based re-resolve was tried and did not help).

## Games integration (`launcher/Games.qml`)

- Steam: `libraryfolders.vdf` and `appmanifest_*.acf` parsed with the hand-written `vdf.js` (`.pragma library`). Art comes from `appcache/librarycache`, found with a single `find -maxdepth 3` sweep (covers both flat and hash-subdir layouts). Launch via `xdg-open steam://rungameid/<id>`.
- Epic (Heroic/legendary): installed list from `~/.config/heroic/legendaryConfig/legendary/installed.json`. Cover URLs come from legendary's `metadata/<app>.json` `keyImages` (`DieselGameBoxTall` preferred) and are cached once into `~/.cache/quickshell/epic-covers`. Heroic's own icon cache is unreliable (truncated `.jpg.$$N` files). Launch via `heroic://launch/legendary/<id>`.
- Prism: instances scanned from `prismRoots`. Built-in icons (grass etc.) are compiled into the binary, so equivalent SVGs are fetched once from the PrismLauncher repo into `~/.cache/quickshell/prismlauncher-icons`. `iconKey == "default"` aliases to `grass`. Launch with `prismlauncher --launch <id>` and **no `-d` flag** (it overrides Prism's configured data dir and opens a fresh setup).
- Blacklists (`blacklistedNamePatterns`, `blacklistedIds`) hide Proton/SLR/redistributables and Civ6 DLC entries. Hardcoded on purpose, no config file yet.
- Tile/icon preference toggle persists to `~/.cache/quickshell/launcher-games-icon-pref.json`.

## Persistence

`FileView` + `JsonAdapter` (`writeAdapter()`) is the standard pattern. Files:

- `~/.local/share/quickshell/`: `pinned.json`, `notes.json`, `ics/` (holiday data).
- `~/.cache/quickshell/`: `launcher-usage.json`, `currency-rates.json`, `launcher-bookmarks.sqlite`, games caches (above).

## Testing UI by hand

- The user runs in non-auto-approval mode: every Bash call needs a manual approval click, which steals Wayland focus and makes `HyprlandFocusGrab` close the launcher. So an open, type, screenshot test must be **one atomic Bash call**:
  ```bash
  qs ipc call launcher toggle; sleep 0.4; wtype "m "; sleep 1.5; grim <scratchpad>/shot.png; echo done
  ```
- `wtype` (keyboard) and `grim` (screenshot, all monitors in one image; crop with PIL) are installed. No mouse-click tool exists, so anything needing a click must be verified another way (e.g. edit the persisted JSON).
- When editing files, use the Edit/Write tools, not Python or sed scripts, so the user can see the changes.
