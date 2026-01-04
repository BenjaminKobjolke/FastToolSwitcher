; ==================== TargetPicker.ahk ====================
; Window picker - click a window to capture its info and auto-fill the tool dialog

global PickerActive := false

StartTargetPicker:
	PickerActive := true
	Gui, ToolDialog:Hide

	; Wait for the button click to be released first (prevents immediate capture)
	KeyWait, LButton

	; Change cursor to crosshair
	hCross := DllCall("LoadCursor", "Ptr", 0, "Ptr", 32515)  ; IDC_CROSS
	DllCall("SetSystemCursor", "Ptr", hCross, "UInt", 32512)  ; OCR_NORMAL

	; Show instruction tooltip
	ToolTip, Click on any window to capture it...`nPress Escape to cancel

	; Set up Escape hotkey
	Hotkey, Escape, CancelTargetPicker, On

	; Start update timer (also checks for mouse click)
	SetTimer, TargetPickerUpdate, 50
return

TargetPickerUpdate:
	if (!PickerActive)
		return

	; Check if left mouse button was clicked
	if (GetKeyState("LButton", "P"))
	{
		; Wait for release
		KeyWait, LButton
		; Capture the window
		Gosub, EndTargetPicker
		return
	}

	MouseGetPos, , , WinUnderCursor
	WinGet, procName, ProcessName, ahk_id %WinUnderCursor%
	WinGetTitle, winTitle, ahk_id %WinUnderCursor%

	; Truncate long titles for tooltip
	if (StrLen(winTitle) > 50)
		winTitle := SubStr(winTitle, 1, 47) . "..."

	ToolTip, % "Exe: " . procName . "`nTitle: " . winTitle . "`n`nClick to select, Escape to cancel"
return

EndTargetPicker:
	if (!PickerActive)
		return
	PickerActive := false

	; Clean up
	SetTimer, TargetPickerUpdate, Off
	Hotkey, Escape, CancelTargetPicker, Off
	ToolTip

	; Restore system cursor
	DllCall("SystemParametersInfo", "UInt", 0x57, "UInt", 0, "Ptr", 0, "UInt", 0)

	; Get window info under cursor
	MouseGetPos, , , WinUnderCursor
	WinGet, procName, ProcessName, ahk_id %WinUnderCursor%
	WinGet, procPath, ProcessPath, ahk_id %WinUnderCursor%
	WinGetTitle, winTitle, ahk_id %WinUnderCursor%

	; Derive name from exe (remove .exe, capitalize first letter)
	derivedName := RegExReplace(procName, "i)\.exe$", "")
	StringUpper, derivedName, derivedName, T  ; Title case

	; Fill form fields
	GuiControl, ToolDialog:, TdName, %derivedName%
	GuiControl, ToolDialog:, TdExeName, %procName%
	GuiControl, ToolDialog:, TdExePath, %procPath%
	GuiControl, ToolDialog:, TdWindowTitle, %winTitle%

	; Show dialog again
	Gui, ToolDialog:Show
return

CancelTargetPicker:
	PickerActive := false

	; Clean up
	SetTimer, TargetPickerUpdate, Off
	Hotkey, Escape, CancelTargetPicker, Off
	ToolTip

	; Restore system cursor
	DllCall("SystemParametersInfo", "UInt", 0x57, "UInt", 0, "Ptr", 0, "UInt", 0)

	; Show dialog again
	Gui, ToolDialog:Show
return
