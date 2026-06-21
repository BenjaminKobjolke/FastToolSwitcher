; ==================== IgnoreWindows.ahk ====================
; "Ignore window" feature: mark windows so the main cycle skips them, persist the
; marks across a Reload, and reconcile the title suffix that flags them.
; Contains labels (ToggleIgnoreActiveWindow, MarkerWatch), so it must be
; #Included AFTER the auto-execute section.

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
