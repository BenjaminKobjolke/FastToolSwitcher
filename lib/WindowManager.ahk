; ==================== WindowManager.ahk ====================
; Window cycling and hotkey handlers

; Sort an array of window IDs by handle for consistent ordering.
; (WinGet returns windows in Z-order, which changes after each activation.)
SortByHandle(ByRef windows) {
	Loop % windows.Length() - 1
	{
		for i, val in windows
		{
			if (i < windows.Length() && windows[i] > windows[i+1])
			{
				temp := windows[i]
				windows[i] := windows[i+1]
				windows[i+1] := temp
			}
		}
	}
}

; Whether a window is currently marked as ignored for the main cycle.
IsWindowIgnored(windowID) {
	global IgnoredWindows
	return IgnoredWindows.HasKey(windowID)
}

; Append the ignore marker to a window's title (no-op if already present).
ApplyIgnoreSuffix(windowID) {
	global IGNORED_SUFFIX
	WinGetTitle, currentTitle, ahk_id %windowID%
	if (!InStr(currentTitle, IGNORED_SUFFIX))
		WinSetTitle, ahk_id %windowID%, , % currentTitle . IGNORED_SUFFIX
}

; Remove the ignore marker from a window's title (no-op if absent).
RemoveIgnoreSuffix(windowID) {
	global IGNORED_SUFFIX
	WinGetTitle, currentTitle, ahk_id %windowID%
	if (InStr(currentTitle, IGNORED_SUFFIX))
	{
		StringReplace, currentTitle, currentTitle, %IGNORED_SUFFIX%,
		WinSetTitle, ahk_id %windowID%, , %currentTitle%
	}
}

; OnExit handler. On a Reload (Settings save / tray Reload / debug reload) the ignore
; state is handed to the next instance via a temp file and the suffixes are left in
; place. On a genuine exit the markers are stripped and the handoff file removed.
StripIgnoreMarkers(ExitReason := "", ExitCode := "") {
	global IgnoredWindows, IGNORED_STATE_FILE
	if (ExitReason = "Reload")
	{
		SaveIgnoredWindows()
		return
	}
	SetTimer, MarkerWatch, Off
	for id in IgnoredWindows
	{
		if (!WinExist("ahk_id " . id))
			continue
		RemoveIgnoreSuffix(id)
	}
	IgnoredWindows := {}
	FileDelete, %IGNORED_STATE_FILE%
}

; Persist the ignored window handles so a Reload can restore them.
SaveIgnoredWindows() {
	global IgnoredWindows, IGNORED_STATE_FILE
	ids := ""
	for id in IgnoredWindows
		ids .= (ids = "" ? "" : ",") . id
	FileDelete, %IGNORED_STATE_FILE%
	if (ids != "")
		FileAppend, %ids%, %IGNORED_STATE_FILE%
}

; Restore the ignored window handles after a Reload, then consume the handoff file.
; If the ignore feature was turned off in the save that caused the reload, the saved
; windows are un-ignored (suffix stripped) instead of restored.
RestoreIgnoredWindows() {
	global IgnoredWindows, IGNORED_STATE_FILE, IgnoreHotkeyEnabled
	if (!FileExist(IGNORED_STATE_FILE))
		return
	FileRead, ids, %IGNORED_STATE_FILE%
	FileDelete, %IGNORED_STATE_FILE%
	for index, id in StrSplit(ids, ",")
	{
		if (id = "" || !WinExist("ahk_id " . id))
			continue
		if (IgnoreHotkeyEnabled = 1)
		{
			IgnoredWindows[id] := 1
			ApplyIgnoreSuffix(id)
		}
		else
			RemoveIgnoreSuffix(id)
	}
	if (IgnoredWindows.Count() > 0)
		SetTimer, MarkerWatch, 500
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

			; Sort validWindows by window handle for consistent ordering
			SortByHandle(validWindows)

			; Handle based on valid window count
			if (validWindows.Length() = 0)
			{
				; No valid windows exist, launch new instance
				if (tool.Arguments != "")
				{
					Run, % tool.ExePath . " " . tool.Arguments
				}
				else
				{
					Run, % tool.ExePath
				}
			}
			else
			{
				; Find if any valid window is currently active
				WinGet, activeID, ID, A
				activeFound := false
				activeIndex := 0

				for validIndex, windowID in validWindows
				{
					if (windowID = activeID)
					{
						activeFound := true
						activeIndex := validIndex
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
						nextIndex := activeIndex + 1
						if (nextIndex > validWindows.Length())
							nextIndex := 1
						WinActivate, % "ahk_id " . validWindows[nextIndex]
						MoveMouseToActiveCenter()
					}
				}
				else
				{
					; No valid window is active, activate first non-ignored one
					targetID := validWindows[1]
					for vi, wid in validWindows
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

; Toggle the active window's ignored state for the main cycle.
ToggleIgnoreActiveWindow:
	global IgnoredWindows
	WinGet, ignoreID, ID, A
	if (ignoreID = "")
		return
	if (IgnoredWindows.HasKey(ignoreID))
	{
		IgnoredWindows.Delete(ignoreID)
		RemoveIgnoreSuffix(ignoreID)
		ShowMouseTooltip("Window un-ignored")
	}
	else
	{
		IgnoredWindows[ignoreID] := 1
		ApplyIgnoreSuffix(ignoreID)
		ShowMouseTooltip("Window ignored")
	}
	; Run the marker reconcile timer only while something is ignored
	if (IgnoredWindows.Count() > 0)
		SetTimer, MarkerWatch, 500
	else
		SetTimer, MarkerWatch, Off
return

; Re-apply the suffix if an app rewrote its own title; prune dead windows.
MarkerWatch:
	global IgnoredWindows
	deadIDs := []
	for id in IgnoredWindows
	{
		if (!WinExist("ahk_id " . id))
		{
			deadIDs.Push(id)
			continue
		}
		ApplyIgnoreSuffix(id)
	}
	for index, id in deadIDs
		IgnoredWindows.Delete(id)
	if (IgnoredWindows.Count() = 0)
		SetTimer, MarkerWatch, Off
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

	; Sort by handle for consistent ordering
	SortByHandle(validWindows)

	; Find current window and cycle in the requested direction
	WinGet, activeID, ID, A
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

	WinActivate, % "ahk_id " . validWindows[targetIndex]
	MoveMouseToActiveCenter()
}
