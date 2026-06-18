# Plan: Add reverse window-cycling hotkey (previous window of same type)

## Context

`Ctrl+Shift+Space` (`MainHotkey=^+Space`) cycles **forward** through windows of the
same process. User wants a second hotkey, default `Ctrl+Shift+Alt+Space` (`^+!Space`),
that cycles **backward** to the previous window of the same type.

Approach chosen: full **new INI setting + GUI control** so the reverse hotkey is
independently configurable and toggleable, matching how `MainHotkey` and
`OverviewHotkey` already work.

The forward-cycle logic in `MainWindowCycleHotkey:` (WindowManager.ahk:146-204) is
reused — only the step direction changes (`+1` → `-1`, wrap to last). Refactor the
shared body into one function to avoid duplicating ~50 lines.

## Changes

### 1. `lib/Config.ahk` — globals + load
- Add globals (near line 7-10):
  ```ahk
  global MainHotkeyReversedEnabled := 0
  global MainHotkeyReversed := ""
  ```
- In `InitConfig()` (after line 31, alongside `MainHotkey` read):
  ```ahk
  IniRead, tmp, %IniFile%, Settings, MainHotkeyReversedEnabled, 0
  MainHotkeyReversedEnabled := tmp
  IniRead, tmp, %IniFile%, Settings, MainHotkeyReversed, %A_Space%
  MainHotkeyReversed := tmp
  ```

### 2. `lib/Config.ahk` — `RegisterHotkeys()`
- Extend the `global` line (201) to include the two new vars.
- Add reverse hotkey to the startup duplicate-detection block (after line 228,
  mirror the `MainHotkey` check, label `"Window Cycling (Reverse)"`).
- Register after the main hotkey (after line 255):
  ```ahk
  if (MainHotkeyReversedEnabled = 1 && MainHotkeyReversed != "")
  {
      Hotkey, %MainHotkeyReversed%, MainWindowCycleHotkeyReversed
  }
  ```

### 3. `lib/WindowManager.ahk` — refactor cycle + add reverse handler
Replace the `MainWindowCycleHotkey:` label body (146-204) with thin wrappers that
delegate to a shared direction-aware function (DRY — current body is copy-pasteable):
```ahk
MainWindowCycleHotkey:
    CycleProcessWindows(1)
return

MainWindowCycleHotkeyReversed:
    CycleProcessWindows(-1)
return

CycleProcessWindows(direction) {
    global MoveMouse, MouseMoveSpeed
    ; ...existing enumerate + sort body (lines 147-178)...
    ; cycling:
    targetIndex := 1
    for idx, winID in validWindows
    {
        if (winID = activeID)
        {
            targetIndex := idx + direction
            if (targetIndex > validWindows.Length())
                targetIndex := 1
            else if (targetIndex < 1)
                targetIndex := validWindows.Length()
            break
        }
    }
    ; ...existing WinActivate + mouse-move body (lines 194-203)...
}
```

### 4. `lib/SettingsGUI.ahk` — GUI controls
Add a reverse-cycling block on the Settings tab. To avoid shifting every existing
control, place it below `StartWithWindows` (current last control at y360), e.g.
y400-435 (tab height h510 has room):
- `Checkbox vChkMainHotkeyReversedEnabled Checked%MainHotkeyReversedEnabled%` —
  "Enable reverse window cycling hotkey"
- Parse with `ParseHotkey(MainHotkeyReversed)`, then Ctrl/Shift/Alt/Win checkboxes
  `vChkRevCtrl/vChkRevShift/vChkRevAlt/vChkRevWin`, `Edit vHkRevKey ReadOnly`,
  `Button gSetRevKey, Set` — mirror the main-hotkey block (lines 40-47).
- Add label:
  ```ahk
  SetRevKey:
      CaptureKeyToControl("Settings", "HkRevKey")
  return
  ```

### 5. `lib/SettingsGUI.ahk` — `SaveSettings:`
- Build: `builtReverseHotkey := BuildHotkey(ChkRevCtrl, ChkRevShift, ChkRevAlt, ChkRevWin, HkRevKey)`
- Conflict checks (mirror lines 285-313): reverse vs tools, reverse vs main hotkey,
  reverse vs overview hotkey — reject duplicates with a MsgBox + `return`.
- Write (after line 317):
  ```ahk
  IniWrite, %ChkMainHotkeyReversedEnabled%, %IniFile%, Settings, MainHotkeyReversedEnabled
  IniWrite, %builtReverseHotkey%, %IniFile%, Settings, MainHotkeyReversed
  ```

### 6. `FastToolSwitcher.ini` — defaults
Add under `[Settings]`:
```ini
MainHotkeyReversedEnabled=1
MainHotkeyReversed=^+!Space
```

## Reused functions
- `ParseHotkey()` / `BuildHotkey()` — `lib/HotkeyCapture.ahk` (parse INI string ↔ checkboxes)
- `CaptureKeyToControl()` — `lib/HotkeyCapture.ahk` (Set-button key capture)
- Window enumerate/sort/activate body — `lib/WindowManager.ahk` (now shared via `CycleProcessWindows`)

## Verification
1. Run `FastToolSwitcher.ahk --gui` (AHK v1.1).
2. Open ≥3 windows of one app (e.g. Brave). `Ctrl+Shift+Space` advances forward,
   `Ctrl+Shift+Alt+Space` goes backward; both wrap at the ends.
3. Settings tab: toggle "Enable reverse window cycling hotkey", change its key via
   Set, Save → confirm `[Settings] MainHotkeyReversed` / `MainHotkeyReversedEnabled`
   written to INI and new binding works after reload.
4. Assign the reverse hotkey equal to the main/overview/a tool hotkey → Save shows
   conflict MsgBox and blocks.
5. Disable the checkbox + Save → reverse hotkey no longer fires.
