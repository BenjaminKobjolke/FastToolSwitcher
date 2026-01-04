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

; Build a hotkey string from components
; Returns string like "^+Space"
BuildHotkey(ctrl, shift, alt, win, key) {
    hotkeyStr := ""

    if (ctrl)
        hotkeyStr .= "^"
    if (shift)
        hotkeyStr .= "+"
    if (alt)
        hotkeyStr .= "!"
    if (win)
        hotkeyStr .= "#"

    hotkeyStr .= key

    return hotkeyStr
}

; Capture a single key (no modifiers) and update the control
CaptureKeyToControl(guiName, controlVar) {
    ; Show placeholder
    GuiControl, %guiName%:, %controlVar%, Press key...

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
        GuiControl, %guiName%:, %controlVar%, (timeout)
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
        GuiControl, %guiName%:, %controlVar%, (cancelled)
        return
    }

    ; Update the control with just the key
    GuiControl, %guiName%:, %controlVar%, %capturedKey%
}
