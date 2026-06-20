# Ignore Windows

Exclude individual windows from the main "switch between windows of the same
type" cycle. Useful when you have many windows of one application open (e.g. 10
browser windows) but only want to cycle through a few of them.

## How it works

- Focus a window and press the **ignore hotkey** (default `Ctrl+Alt+I`).
- The window is marked as *ignored*: its title gets the suffix
  ` - FastToolSwitcher - ignored`, and the main cycling hotkeys
  (`Ctrl+Shift+Space` / `Ctrl+Shift+Alt+Space`) now skip it.
- Press the ignore hotkey again on the same window to **un-ignore** it: the
  suffix is removed and it rejoins the cycle.

Ignoring is a temporary, "right now" convenience — it is **session only** and
is kept in memory keyed by window handle. It survives a **reload** (saving
Settings, tray *Reload*) but is **not** persisted long-term: all windows are
un-ignored when the application is exited and restarted.

## Scope: what skips ignored windows

| Action | Behavior with ignored windows |
|--------|-------------------------------|
| Main cycle (`Ctrl+Shift+Space` / reverse) | **Skips** ignored windows. |
| Tool hotkey — jumping to the app from elsewhere | Activates the first **non-ignored** window (falls back to any window if all are ignored). |
| Tool hotkey — repeated presses while a tool window is active | Still cycles through **all** windows, including ignored ones. |

## The title marker

The suffix is purely cosmetic — the actual skip logic uses the in-memory list,
not the title. If an application rewrites its own title (e.g. a browser changing
it on tab switch), the suffix is automatically re-applied within ~0.5 seconds by
a background reconcile timer. That timer only runs while at least one window is
ignored.

Ignored windows **persist across a reload** — saving Settings or using the tray
*Reload* keeps them ignored (the handles are handed to the restarted script via a
short-lived temp file). They are cleared only on a real application **exit/restart**,
where all suffixes are stripped automatically so no window keeps a stale
` - FastToolSwitcher - ignored` title.

Turning the feature off in Settings (unticking **Enable ignore window hotkey**)
and saving un-ignores every window — the suffixes are stripped and nothing is
restored.

## Configuration

Change the hotkey or turn the feature off in **Settings** (tray icon → Settings
→ *Settings* tab → **Enable ignore window hotkey** row), or edit
`FastToolSwitcher.ini` directly:

```ini
[Settings]
IgnoreHotkeyEnabled=1
IgnoreHotkey=^!i
```

- `IgnoreHotkeyEnabled` — `1` to enable (default), `0` to disable the whole
  feature. When disabled the hotkey is not registered, nothing can be ignored,
  and the reconcile timer never runs.
- `IgnoreHotkey` — the hotkey, in AutoHotkey modifier notation
  (`^`=Ctrl, `+`=Shift, `!`=Alt, `#`=Win). Default `^!i` = `Ctrl+Alt+I`.
