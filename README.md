# FastToolSwitcher

A lightweight AutoHotkey tool for quickly switching between applications using customizable hotkeys.

## Features

### Application Switching
- **Hotkey-based switching** - Assign custom hotkeys to your frequently used applications
- **Multiple hotkeys per action** - Bind several hotkeys to the same tool or function; any of them triggers it (see [docs/MULTIPLE_HOTKEYS.md](docs/MULTIPLE_HOTKEYS.md))
- **Smart window detection** - Finds windows by executable name or window title
- **Return to last-used window** - When you are on another application and press a tool's hotkey, it activates the window of that tool you used most recently (not the oldest one)
- **Window cycling** - Press the same hotkey multiple times to cycle through multiple windows of the same application
- **Auto-launch** - If the application isn't running, it will be launched automatically
- **Background send** - If the application is already focused, pressing the hotkey sends it to the background
- **No-switch feedback** - If only one window is available (nothing to switch to), a tooltip near the mouse shows *"Only one window - nothing to switch to"* so the hotkey never feels broken

### Window Cycling
- **Main cycling hotkey** (default: `Ctrl+Shift+Space`) - Cycles **forward** through all windows of the currently active application
- **Reverse cycling hotkey** (default: `Ctrl+Shift+Alt+Space`) - Cycles **backward** to the previous window of the same application
- Both wrap around at the ends and are independently configurable in Settings
- Useful when you have multiple instances of the same program open
- If the active app has only one window, a mouse tooltip indicates there is nothing to cycle to

### Mouse Positioning
- **Move mouse to center** - Optionally moves the mouse cursor to the center of the activated window
- Helps with quick interaction after switching

### Exclude Windows
- **Exclude by title** - Exclude specific windows from switching (e.g., exclude DevTools windows from browser switching)

### Ignore Windows
- **Ignore hotkey** (default: `Ctrl+Alt+I`) - Temporarily exclude the active window from the main cycling hotkey; press again to un-ignore
- Ignored windows are marked with a ` - FastToolSwitcher - ignored` title suffix and skipped while cycling
- Session-only and **preserved across a reload** (saving Settings / tray *Reload*); cleared on a full exit/restart; can be disabled in Settings
- See [docs/IGNORE_WINDOWS.md](docs/IGNORE_WINDOWS.md) for details

### GUI Settings
- **Tabbed interface** - Settings, Tools, and Design tabs
- **Dark/Light mode** - Switch between dark and light themes with live preview
- **Tool management** - Add, edit, and delete tool configurations through the GUI

### Auto-Discovery
- Automatically searches for executable paths on first run
- Checks common installation locations first for faster discovery

## Installation

1. Install [AutoHotkey v1.1](https://www.autohotkey.com/)
2. Download or clone this repository
3. Run `FastToolSwitcher.ahk`

## Usage

### Command Line Options

```bash
# Start with GUI open
FastToolSwitcher.ahk --gui
FastToolSwitcher.ahk -g
```

### System Tray

Right-click the tray icon to access:
- **Settings** - Open the configuration GUI
- **Reload** - Reload the script
- **Exit** - Close the application

### Configuring Tools

1. Right-click tray icon → Settings
2. Go to the **Tools** tab
3. Click **Add** to create a new tool entry
4. Configure:
   - **Name** - Display name for the tool
   - **Hotkey(s)** - One or more keyboard shortcuts. Use **Add** to compose a hotkey
     (modifier checkboxes + **Set** key), **Edit**/**Remove** for an existing one. See
     [docs/MULTIPLE_HOTKEYS.md](docs/MULTIPLE_HOTKEYS.md)
   - **Exe Name** - Process name (e.g., `brave.exe`)
   - **Exe Path** - Full path to the executable
   - **Window Title** - (Optional) Match by window title instead of exe name
   - **Arguments** - (Optional) Command line arguments
   - **Exclude Title** - (Optional) Exclude windows containing this text

The global function hotkeys (window cycling, reverse, overview, ignore) on the
**Settings** tab use the same Add/Edit/Remove list, so they can have multiple
hotkeys too.

### Hotkey Format

Use AutoHotkey modifier symbols:
- `^` = Ctrl
- `+` = Shift
- `!` = Alt
- `#` = Win

Examples:
- `^+b` = Ctrl+Shift+B
- `!F1` = Alt+F1
- `#e` = Win+E

Multiple hotkeys for one action are stored in the same key, joined with `|`
(e.g. `Hotkey=^+b|^!b`). A value with no `|` is a single hotkey, so older config
files keep working.

## Configuration File

Personal settings are stored in `FastToolSwitcher.ini`. This file is ignored by Git.
On first run, FastToolSwitcher creates it from the tracked `FastToolSwitcher.example.ini`
when no local config exists.

```ini
[Settings]
MainHotkeyEnabled=1
MainHotkey=^+Space
MainHotkeyReversedEnabled=1
MainHotkeyReversed=^+!Space
IgnoreHotkeyEnabled=1
IgnoreHotkey=^!i
MoveMouse=1
DarkMode=1

[Tools]
ToolCount=2

[Tool1]
Name=Brave
Hotkey=^+b|^!b
ExeName=brave.exe
ExePath=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe
WindowTitle=
Arguments=
ExcludeTitle=DevTools
```

## Requirements

- Windows 10/11
- AutoHotkey v1.1+

## License

MIT License
