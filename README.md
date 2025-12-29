# FastToolSwitcher

A lightweight AutoHotkey tool for quickly switching between applications using customizable hotkeys.

## Features

### Application Switching
- **Hotkey-based switching** - Assign custom hotkeys to your frequently used applications
- **Smart window detection** - Finds windows by executable name or window title
- **Window cycling** - Press the same hotkey multiple times to cycle through multiple windows of the same application
- **Auto-launch** - If the application isn't running, it will be launched automatically
- **Background send** - If the application is already focused, pressing the hotkey sends it to the background

### Window Cycling
- **Main cycling hotkey** (default: `Ctrl+Shift+Space`) - Cycles through all windows of the currently active application
- Useful when you have multiple instances of the same program open

### Mouse Positioning
- **Move mouse to center** - Optionally moves the mouse cursor to the center of the activated window
- Helps with quick interaction after switching

### Exclude Windows
- **Exclude by title** - Exclude specific windows from switching (e.g., exclude DevTools windows from browser switching)

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
   - **Hotkey** - Keyboard shortcut (e.g., `^+b` for Ctrl+Shift+B)
   - **Exe Name** - Process name (e.g., `brave.exe`)
   - **Exe Path** - Full path to the executable
   - **Window Title** - (Optional) Match by window title instead of exe name
   - **Arguments** - (Optional) Command line arguments
   - **Exclude Title** - (Optional) Exclude windows containing this text

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

## Configuration File

Settings are stored in `FastToolSwitcher.ini`:

```ini
[Settings]
MainHotkeyEnabled=1
MainHotkey=^+Space
MoveMouse=1
DarkMode=1

[Tools]
ToolCount=2

[Tool1]
Name=Brave
Hotkey=^+b
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
