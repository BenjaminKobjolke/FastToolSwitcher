# Shortcuts Overview Hotkey

## What it does

Displays a borderless overlay window centered on the screen that lists all configured tools and their hotkey combinations. Only tools with assigned hotkeys are shown.

## How to enable

1. Open Settings (right-click tray icon > Settings)
2. In the Settings tab, check "Enable shortcuts overview hotkey"
3. Set your preferred modifier keys (Ctrl, Shift, Alt, Win) and press "Set" to choose a key
4. Click Save

## Keyboard behavior

- Press the configured hotkey to open the overlay
- Press the same hotkey again to close it
- Press Escape to close it
- The overlay opens with `NoActivate` so it does not steal focus

## Visual layout

- Title: "Shortcuts Overview" at the top
- Two columns: tool name (left) and hotkey display (right)
- Hotkeys are displayed in human-readable format (e.g. "Ctrl + Shift + B")
- Footer hint: "Press hotkey again or Escape to close"
- Respects dark/light mode theme setting

## INI configuration keys

```ini
[Settings]
OverviewHotkeyEnabled=1
OverviewHotkey=^+o
```

- `OverviewHotkeyEnabled`: 0 (disabled) or 1 (enabled)
- `OverviewHotkey`: AHK hotkey string (e.g. `^+o` for Ctrl+Shift+O)
