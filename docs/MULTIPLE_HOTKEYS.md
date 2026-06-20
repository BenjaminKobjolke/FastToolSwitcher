# Multiple Hotkeys

Every action — each tool **and** each global function (window cycling, reverse
cycling, shortcuts overview, ignore window) — can be bound to **more than one**
hotkey. Any of the bound hotkeys triggers that action.

Example use: cycle windows with both `Ctrl+.` and a mouse-side combo, or launch a
browser from two different shortcuts.

## Editing hotkeys in Settings

Each hotkey row shows a **list** of the currently bound hotkeys plus three buttons:

| Button | Action |
|--------|--------|
| **Add** | Opens the hotkey editor popup to compose a new hotkey and append it. |
| **Edit** | Opens the popup pre-filled with the **selected** hotkey so you can change it. |
| **Remove** | Deletes the **selected** hotkey from the list. |

The popup is the familiar composer: tick the modifier checkboxes (**Ctrl / Shift /
Alt / Win**), click **Set** and press the key, then **OK**.

The same row + popup is used for the global functions on the **Settings** tab and
for each tool in the **Add/Edit Tool** dialog.

Duplicate hotkeys are rejected: a hotkey already bound to another tool or function
is blocked when you save.

## Storage format

Multiple hotkeys are stored in the **same** ini key, joined with a pipe (`|`):

```ini
[Settings]
MainHotkey=^+.|#^.

[Tool1]
Hotkey=^+b|^!b
```

A value with no `|` is just a single hotkey, so existing configuration files keep
working unchanged — this is fully backward compatible.

See the [Hotkey Format](../README.md#hotkey-format) section for the modifier
symbols (`^ + ! #`).
