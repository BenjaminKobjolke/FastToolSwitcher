; ==================== HotkeyCapture.ahk ====================
; Hotkey parsing, building, and key capture functions

; Parse a hotkey string like "^+Space" into components
; Returns object: {ctrl: 0/1, shift: 0/1, alt: 0/1, win: 0/1, key: "Space"}
ParseHotkey(hotkeyStr) {
    result := {}
    result.ctrl := 0
    result.shift := 0
    result.alt := 0
    result.win := 0
    result.key := ""

    if (hotkeyStr = "")
        return result

    ; Check for modifiers at the start
    pos := 1
    Loop
    {
        char := SubStr(hotkeyStr, pos, 1)
        if (char = "^")
        {
            result.ctrl := 1
            pos++
        }
        else if (char = "+")
        {
            result.shift := 1
            pos++
        }
        else if (char = "!")
        {
            result.alt := 1
            pos++
        }
        else if (char = "#")
        {
            result.win := 1
            pos++
        }
        else
            break
    }

    ; Rest is the key
    result.key := SubStr(hotkeyStr, pos)

    return result
}

; Build a hotkey string from a components object (same shape ParseHotkey returns:
; {ctrl, shift, alt, win, key}). Returns string like "^+Space".
BuildHotkey(parts) {
    hotkeyStr := ""

    if (parts.ctrl)
        hotkeyStr .= "^"
    if (parts.shift)
        hotkeyStr .= "+"
    if (parts.alt)
        hotkeyStr .= "!"
    if (parts.win)
        hotkeyStr .= "#"

    hotkeyStr .= parts.key

    return hotkeyStr
}

; Check if a hotkey conflicts with any existing tool or global hotkey
; Returns "" if no conflict, or a description like "tool 'Brave' (Ctrl + B)"
; excludeToolIndex: skip this tool index (used when editing an existing tool)
FindHotkeyConflict(hotkeyToCheck, excludeToolIndex := 0) {
	global Tools, MainHotkeyEnabled, MainHotkey, OverviewHotkeyEnabled, OverviewHotkey

	if (hotkeyToCheck = "")
		return ""

	; Check against all tool hotkeys (each may hold multiple hotkeys)
	for index, tool in Tools
	{
		if (index = excludeToolIndex)
			continue
		if (HotkeyListContains(tool.Hotkey, hotkeyToCheck))
		{
			displayName := tool.Name != "" ? tool.Name : tool.ExeName
			return "tool '" . displayName . "' (" . FormatHotkeyList(tool.Hotkey) . ")"
		}
	}

	; Check against MainHotkey
	if (MainHotkeyEnabled = 1 && HotkeyListContains(MainHotkey, hotkeyToCheck))
		return "Window Cycling hotkey (" . FormatHotkeyList(MainHotkey) . ")"

	; Check against OverviewHotkey
	if (OverviewHotkeyEnabled = 1 && HotkeyListContains(OverviewHotkey, hotkeyToCheck))
		return "Shortcuts Overview hotkey (" . FormatHotkeyList(OverviewHotkey) . ")"

	return ""
}

; Capture a single key (no modifiers) and update the control
CaptureKeyToControl(guiName, controlVar) {
    global KEY_PLACEHOLDER_PROMPT, KEY_PLACEHOLDER_TIMEOUT, KEY_PLACEHOLDER_CANCELLED
    ; Show placeholder
    GuiControl, %guiName%:, %controlVar%, %KEY_PLACEHOLDER_PROMPT%

    ; Define end keys for special keys
    endKeys := "{Space}{Tab}{Escape}{Backspace}{Delete}{Insert}{Home}{End}{PgUp}{PgDn}"
    endKeys .= "{Up}{Down}{Left}{Right}{Enter}"
    endKeys .= "{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}"
    endKeys .= "{Numpad0}{Numpad1}{Numpad2}{Numpad3}{Numpad4}{Numpad5}"
    endKeys .= "{Numpad6}{Numpad7}{Numpad8}{Numpad9}{NumpadDot}{NumpadDiv}"
    endKeys .= "{NumpadMult}{NumpadAdd}{NumpadSub}{NumpadEnter}"

    ; Wait for input - L1 = 1 char, T5 = 5 sec timeout
    Input, capturedKey, L1 T5, %endKeys%

    ; Handle timeout
    if (ErrorLevel = "Timeout")
    {
        GuiControl, %guiName%:, %controlVar%, %KEY_PLACEHOLDER_TIMEOUT%
        return
    }

    ; Get end key if pressed
    if (InStr(ErrorLevel, "EndKey:"))
    {
        capturedKey := SubStr(ErrorLevel, 8)
    }

    ; If nothing captured
    if (capturedKey = "")
    {
        GuiControl, %guiName%:, %controlVar%, %KEY_PLACEHOLDER_CANCELLED%
        return
    }

    ; Update the control with just the key
    GuiControl, %guiName%:, %controlVar%, %capturedKey%
}

; Whether a key field holds a real captured key rather than empty or one of the
; placeholders CaptureKeyToControl writes above. Single source for those texts.
IsCapturedKeyValid(key) {
    global KEY_PLACEHOLDER_PROMPT, KEY_PLACEHOLDER_TIMEOUT, KEY_PLACEHOLDER_CANCELLED
    return (key != "" && key != KEY_PLACEHOLDER_PROMPT && key != KEY_PLACEHOLDER_TIMEOUT && key != KEY_PLACEHOLDER_CANCELLED)
}
