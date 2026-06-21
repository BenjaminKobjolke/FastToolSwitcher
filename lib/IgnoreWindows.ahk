; ==================== IgnoreWindows.ahk ====================
; "Ignore window" feature: mark windows so the main cycle skips them, persist the
; marks across a Reload or relaunch, and reconcile the title suffix that flags them.
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
	global IgnoredWindows
	if (ExitReason = "Reload")
	{
		SaveIgnoredWindows()
		return
	}
	; Genuine exit: remember the handles for the next launch, but clean the
	; visible title suffixes so no marked titles linger while the app is closed.
	SetTimer, MarkerWatch, Off
	SaveIgnoredWindows()
	for id in IgnoredWindows
	{
		if (!WinExist("ahk_id " . id))
			continue
		RemoveIgnoreSuffix(id)
	}
}

; Persist the ignored window handles (with their exe) so a Reload or a later
; relaunch can restore them. Only live windows are written.
SaveIgnoredWindows() {
	global IgnoredWindows, IGNORED_STATE_FILE
	obj := {}
	for id, exe in IgnoredWindows
	{
		if (WinExist("ahk_id " . id))
			obj[id] := exe
	}
	WriteStateFile(IGNORED_STATE_FILE, obj)
}

; Restore the ignored window handles after a Reload or relaunch, consuming the
; handoff file. Each handle must still be live AND belong to the same exe it had
; when ignored (guards a recycled handle after a reboot). If the ignore feature
; was turned off in the save that caused the reload, the saved windows are
; un-ignored (suffix stripped) instead of restored.
RestoreIgnoredWindows() {
	global IgnoredWindows, IGNORED_STATE_FILE, IgnoreHotkeyEnabled
	saved := ReadStateFile(IGNORED_STATE_FILE)
	for id, exe in saved
	{
		if (!WinExist("ahk_id " . id))
			continue
		WinGet, curExe, ProcessName, ahk_id %id%
		if (curExe != exe)
			continue
		if (IgnoreHotkeyEnabled = 1)
		{
			IgnoredWindows[id] := exe
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
		WinGet, ignoreExe, ProcessName, A
		IgnoredWindows[ignoreID] := ignoreExe
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
