; ==================== WindowManager.ahk ====================
; Window cycling and hotkey handlers. The "ignore window" feature lives in
; lib/IgnoreWindows.ahk; the marker/suffix helpers used here come from there.

; Sort an array of window IDs ascending by handle for consistent ordering.
; (WinGet returns windows in Z-order, which changes after each activation.)
SortByHandle(ByRef windows) {
	BubbleSort(windows, "CompareNumericAsc")
}

; Move the mouse to the center of the active window when enabled.
MoveMouseToActiveCenter() {
	global MoveMouse, MouseMoveSpeed
	if (MoveMouse != 1)
		return
	CoordMode, Mouse, Screen
	WinGetPos, winX, winY, winW, winH, A
	scaledSpeed := MouseMoveSpeed * 10
	SendMode, Event
	MouseMove, winX + winW // 2, winY + winH // 2, %scaledSpeed%
	SendMode, Input
}

; Activate the window adjacent to the active one in `windows` (already sorted).
; direction = 1 forward, -1 backward; wraps at both ends. Falls back to the
; first window when the active window is not in the list. Shared by the per-tool
; and per-process cycles so the step lives in one place.
ActivateNextWindow(windows, direction) {
	WinGet, activeID, ID, A
	targetIndex := 1
	for idx, winID in windows
	{
		if (winID = activeID)
		{
			targetIndex := idx + direction
			if (targetIndex > windows.Length())
				targetIndex := 1
			else if (targetIndex < 1)
				targetIndex := windows.Length()
			break
		}
	}
	WinActivate, % "ahk_id " . windows[targetIndex]
	MoveMouseToActiveCenter()
}

; Launch a tool's executable, appending Arguments when present.
LaunchTool(tool) {
	if (tool.Arguments != "")
		Run, % tool.ExePath . " " . tool.Arguments
	else
		Run, % tool.ExePath
}

; Launch a tool and record the handle of the window it spawned. Snapshots the
; exe's current windows, launches, then polls for the first new (non-excluded)
; window and stores it on tool.TrackedHwnd so future presses return to it.
; ponytail: 5s poll, first new window wins — may catch a transient window in
; rare cases; bump the timeout / add a title filter if it misbehaves.
LaunchAndTrack(ByRef tool) {
	spec := "ahk_exe " . tool.ExeName
	WinGet, beforeList, List, %spec%
	existing := {}
	Loop, %beforeList%
		existing[beforeList%A_Index%] := 1

	LaunchTool(tool)

	newHwnd := ""
	Loop, 50
	{
		Sleep, 100
		WinGet, afterList, List, %spec%
		Loop, %afterList%
		{
			hwnd := afterList%A_Index%
			if (existing.HasKey(hwnd))
				continue
			if (tool.ExcludeTitle != "")
			{
				WinGetTitle, candidateTitle, ahk_id %hwnd%
				if (InStr(candidateTitle, tool.ExcludeTitle))
					continue
			}
			newHwnd := hwnd
			break
		}
		if (newHwnd != "")
			break
	}

	if (newHwnd != "")
	{
		tool.TrackedHwnd := newHwnd
		WinActivate, % "ahk_id " . newHwnd
		MoveMouseToActiveCenter()
	}
}

; OnExit handler: persist live tracked handles so the next instance (after a
; Reload, which keeps target windows open) can return to the same windows.
SaveTrackedWindows(ExitReason := "", ExitCode := "") {
	global Tools, TRACKED_STATE_FILE
	obj := {}
	for index, tool in Tools
	{
		if (tool.TrackInstance = 1 && tool.TrackedHwnd != "" && WinExist("ahk_id " . tool.TrackedHwnd))
			obj[tool.Section] := tool.TrackedHwnd
	}
	WriteStateFile(TRACKED_STATE_FILE, obj)
}

; Startup: restore tracked handles by tool section, keeping only handles that are
; still live AND still belong to the tool's exe (guards a recycled handle).
RestoreTrackedWindows() {
	global Tools, TRACKED_STATE_FILE
	saved := ReadStateFile(TRACKED_STATE_FILE)
	for index, tool in Tools
	{
		hwnd := saved[tool.Section]
		if (hwnd != "" && WindowMatchesExe(hwnd, tool.ExeName))
			tool.TrackedHwnd := hwnd
	}
}

HandleToolHotkey:
	; Find which tool triggered this hotkey
	triggeredHotkey := A_ThisHotkey

	for index, tool in Tools
	{
		if (HotkeyListContains(tool.Hotkey, triggeredHotkey))
		{
			; Determine window detection method
			if (tool.WindowClass != "" && tool.WindowTitle != "")
			{
				; Use both class and title (e.g., specific Explorer folder)
				windowSpec := tool.WindowTitle . " ahk_class " . tool.WindowClass
			}
			else if (tool.WindowClass != "")
			{
				; Use window class only (for special cases like File Explorer)
				windowSpec := "ahk_class " . tool.WindowClass
			}
			else if (tool.WindowTitle != "")
			{
				; Use window title
				windowSpec := tool.WindowTitle
			}
			else
			{
				; Use exe name
				windowSpec := "ahk_exe " . tool.ExeName
			}

			; Get all matching windows
			WinGet, windowList, List, %windowSpec%

			; Build list of non-excluded windows
			validWindows := []
			Loop, %windowList%
			{
				windowID := windowList%A_Index%
				WinGetTitle, currentTitle, ahk_id %windowID%

				; Check if this window should be excluded
				if (tool.ExcludeTitle != "" && InStr(currentTitle, tool.ExcludeTitle))
					continue

				validWindows.Push(windowID)
			}

			; Capture Z-order (most-recently-used first) before sorting.
			; validWindows is in Z-order from WinGet; SortByHandle sorts in place.
			zOrderWindows := validWindows.Clone()

			; Sort validWindows by window handle for consistent cycling order
			SortByHandle(validWindows)

			; Instance tracking: narrow to the single window this tool launched,
			; or (re)launch and record it when none is tracked/alive yet.
			if (tool.TrackInstance = 1)
			{
				if (tool.TrackedHwnd != "" && WinExist("ahk_id " . tool.TrackedHwnd))
				{
					validWindows := [tool.TrackedHwnd]
					zOrderWindows := [tool.TrackedHwnd]
				}
				else
				{
					LaunchAndTrack(tool)
					break
				}
			}

			; Handle based on valid window count
			if (validWindows.Length() = 0)
			{
				; No valid windows exist, launch new instance
				LaunchTool(tool)
			}
			else
			{
				; Find if any valid window is currently active
				WinGet, activeID, ID, A
				activeFound := false

				for validIndex, windowID in validWindows
				{
					if (windowID = activeID)
					{
						activeFound := true
						break
					}
				}

				if (activeFound)
				{
					; A valid window is active
					if (validWindows.Length() = 1)
					{
						; Only one valid window - send to background if enabled,
						; otherwise nothing to switch to: tell the user via tooltip
						if (tool.SendToBackground = 1)
							Send !{Esc}
						else
							ShowMouseTooltip(NO_OTHER_WINDOW_MESSAGE)
					}
					else
					{
						; Multiple valid windows, cycle to next
						ActivateNextWindow(validWindows, 1)
					}
				}
				else
				{
					; No valid window is active, activate the most-recently-used
					; (first in Z-order) non-ignored window
					targetID := zOrderWindows[1]
					for vi, wid in zOrderWindows
					{
						if (!IsWindowIgnored(wid))
						{
							targetID := wid
							break
						}
					}
					WinActivate, % "ahk_id " . targetID
					MoveMouseToActiveCenter()
				}
			}

			break
		}
	}
return

MainWindowCycleHotkey:
	CycleProcessWindows(1)
return

MainWindowCycleHotkeyReversed:
	CycleProcessWindows(-1)
return

; Cycle through windows of the active process. direction = 1 forward, -1 backward.
CycleProcessWindows(direction) {
	global NO_OTHER_WINDOW_MESSAGE
	; Get active window's process name
	WinGet, activeExe, ProcessName, A
	if (activeExe = "")
		return

	; Get all windows of this process
	WinGet, windowList, List, ahk_exe %activeExe%

	; Build list of valid windows
	validWindows := []
	Loop, %windowList%
	{
		windowID := windowList%A_Index%
		if (IsWindowIgnored(windowID))
			continue
		validWindows.Push(windowID)
	}

	if (validWindows.Length() <= 1)
	{
		ShowMouseTooltip(NO_OTHER_WINDOW_MESSAGE)
		return
	}

	; Sort by handle for consistent ordering, then cycle
	SortByHandle(validWindows)
	ActivateNextWindow(validWindows, direction)
}
