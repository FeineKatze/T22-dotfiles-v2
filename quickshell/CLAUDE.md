# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Quickshell](https://quickshell.outfoxxed.me/) configuration: a single top panel/bar (Waybar-style) for Hyprland, written entirely in QML. Flat file layout, no build system, no tests, no CI, not a git repo.

## Commands

- Run the shell: `quickshell` (or `qs`) — auto-discovers and loads `shell.qml` from this directory. No args needed.
- Lint a file: `qmllint <File>.qml` (system Qt6 tool, no project-specific lint config).
- Format: `qmlformat <File>.qml`.
- Installed version: Quickshell 0.3.0 (Arch package). Check with `quickshell --version`.
- `.qmlls.ini` is a symlink into a Quickshell-managed runtime VFS dir — it's generated tooling config for the QML language server, not something to hand-edit or treat as project structure.

## Architecture

Every top-level `.qml` file in this directory is a standalone component, used by name as an implicit QML type (standard "directory as module" behavior — no explicit relative imports between sibling files).

- `shell.qml` — entry point. `ShellRoot` → `Variants` over `Quickshell.screens` → one `PanelWindow` per monitor, anchored top, `implicitHeight: 35`. Composes widgets left-to-right in a `RowLayout`: `Workspaces`, `Tray`, `Mpris`, `Window`, a filler `Item`, `Clock`.
- `Workspaces.qml` / `WorkspaceButton.qml` — workspace pills. Reactive state comes from `Quickshell.Hyprland` (`Hyprland.focusedWorkspace`, `Hyprland.toplevels`). `WorkspaceButton` uses a QML `states:`/`PropertyChanges` machine (`urgent`/`hover`/`active`/`default`) with `Behavior on color { ColorAnimation }`.
- `Window.qml` — shows the focused window title via `Hyprland.activeToplevel.title`.
- `Tray.qml` — system tray via `Quickshell.Services.SystemTray`, `IconImage` (`Quickshell.Widgets`), custom tooltip via `PopupWindow`, right-click menu via `QsMenuAnchor`. **Gotcha**: the anchor requires the parent `PanelWindow` to be passed in explicitly as the `trayWindow` property (see `shell.qml`'s `Tray { trayWindow: panelWindow }`) — without it, `QsMenuAnchor.anchor.window` can't resolve.
- `Mpris.qml` — play/pause + now-playing tooltip via `Quickshell.Services.Mpris` (`Mpris.players.values[0]`). The update `Timer` only runs while hovered *and* playing — keep this perf pattern when adding similar polling.
- `Clock.qml` — `SystemClock` (`precision: SystemClock.Seconds`) + `Qt.formatDateTime`.

### Machine-specific config to know about

`shell.qml`'s `wsRanges` maps monitor output names (`DP-1`, `DP-2`, `HDMI-A-1`) to hardcoded workspace-number arrays. This is hardware-specific — expect to edit it when the monitor setup changes, and don't assume the same names apply on a different machine.

### Visual conventions (no shared theme file yet)

There's no singleton/theme module — colors and fonts are literal values duplicated per file. When adding widgets, match existing style rather than introducing a new one:
- `implicitHeight: 35`, `radius: 10` on bar backgrounds; `Qt.rgba(...)` translucent dark fills (e.g. `Qt.rgba(0.1686, 0.1882, 0.2314, 0.75)` bar bg, `Qt.rgba(0.0353, 0.0431, 0.0627, 0.75)` for tray/clock).
- Tooltips: `PopupWindow` anchored `Edges.Bottom`, `margins.top: 6`, inner `Rectangle` `radius: 6`–`10`, `border.color: "#e94b4b4b"`, `border.width: 1`, bg `"#c0090b10"`/`"#e9090b10"`.
- Font: `"JetBrainsMono Nerd Font Propo"`, `pixelSize: 15`, `bold: true`, text color `"#B0E0E6"`.
