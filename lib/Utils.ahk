; ==================== Utils.ahk ====================
; Dark Mode Helper Functions

; Show a tooltip near the mouse cursor that auto-dismisses after duration ms.
ShowMouseTooltip(message, duration := 1500) {
	ToolTip, %message%
	SetTimer, RemoveToolTip, % -1 * duration
}

; Apply theme window background colors (dark only; light uses GUI defaults).
ApplyThemeWindowColors(guiName) {
	global DarkMode
	if (DarkMode = 1)
		Gui, %guiName%:Color, 0x1E1E1E, 0x2D2D2D
}

; Set a GUI font with the theme's text color appended. `opts` is the font
; options without color (e.g. "s12", "s14 Bold"); the dark/light color is
; chosen here so call sites stop branching on DarkMode.
ApplyThemeFont(guiName, opts, darkColor := "cWhite", lightColor := "cBlack") {
	global DarkMode
	color := (DarkMode = 1) ? darkColor : lightColor
	Gui, %guiName%:Font, % opts . " " . color
}

; Generic in-place bubble sort. `comparator` is the name of a function taking
; (a, b) and returning >0 when a must come after b. One algorithm for every
; sort in the project (window handles, release-note versions).
BubbleSort(ByRef arr, comparator) {
	n := arr.Length()
	Loop
	{
		swapped := false
		Loop % n - 1
		{
			if (%comparator%(arr[A_Index], arr[A_Index + 1]) > 0)
			{
				tmp := arr[A_Index]
				arr[A_Index] := arr[A_Index + 1]
				arr[A_Index + 1] := tmp
				swapped := true
			}
		}
		if (!swapped)
			break
	}
}

; Ascending numeric comparator (e.g. window handles).
CompareNumericAsc(a, b) {
	return a - b
}

; Descending string comparator (e.g. release-note versions, newest first).
CompareVersionDesc(a, b) {
	if (a < b)
		return 1
	if (a > b)
		return -1
	return 0
}

; Serialize a {key:value} object as key=value lines; delete the file when empty.
; Shared temp-file handoff used by the ignore-window and instance-tracking state.
WriteStateFile(path, obj) {
	data := ""
	for key, val in obj
		data .= key . "=" . val . "`n"
	FileDelete, %path%
	if (data != "")
		FileAppend, %data%, %path%
}

; Read key=value lines into a {key:value} object, consuming (deleting) the file.
ReadStateFile(path) {
	result := {}
	if (!FileExist(path))
		return result
	FileRead, content, %path%
	FileDelete, %path%
	for index, line in StrSplit(content, "`n", "`r")
	{
		if (line = "")
			continue
		pair := StrSplit(line, "=")
		result[pair[1]] := pair[2]
	}
	return result
}

ApplyDarkMode(hwnd) {
	; Dark title bar (Windows 10 1809+)
	DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", 20, "Int*", 1, "Int", 4)
}

ApplyDarkListView(hwndLV) {
	; Apply dark theme to ListView
	DllCall("uxtheme\SetWindowTheme", "Ptr", hwndLV, "Str", "DarkMode_Explorer", "Ptr", 0)
}

ReadVersionFile() {
	FileRead, ver, %A_ScriptDir%\version.txt
	ver := Trim(ver, " `t`r`n")
	return ver
}

ParseReleaseNotesJson(jsonStr) {
	result := {}
	result.notes := []

	; Extract version
	if (RegExMatch(jsonStr, """version""\s*:\s*""([^""]+)""", m))
		result.version := m1

	; Extract date
	if (RegExMatch(jsonStr, """date""\s*:\s*""([^""]+)""", m))
		result.date := m1

	; Extract notes array content, then strings within it
	if (RegExMatch(jsonStr, "s)""notes""\s*:\s*\[(.*?)\]", notesMatch))
	{
		notesContent := notesMatch1
		nPos := 1
		while (nPos := RegExMatch(notesContent, """((?:[^""\\]|\\.)*)""", nm, nPos))
		{
			result.notes.Push(nm1)
			nPos += StrLen(nm)
		}
	}

	return result
}

; Load one release note version into a display-ready object:
; {version: "Version x.y", date: "...", notesText: "• ...`n• ..."}.
; Single source for the load+format used by both the tab init and navigation.
LoadReleaseNote(version) {
	result := {}
	result.version := "Version " . version
	result.date := ""
	result.notesText := ""

	rnFile := A_ScriptDir . "\release_notes\" . version . "\en.json"
	if (!FileExist(rnFile))
	{
		result.notesText := "No release notes file found for version " . version
		return result
	}

	FileRead, jsonStr, %rnFile%
	rn := ParseReleaseNotesJson(jsonStr)
	result.version := "Version " . rn.version
	result.date := rn.date
	for idx, note in rn.notes
	{
		if (idx > 1)
			result.notesText .= "`n"
		result.notesText .= chr(0x2022) . "  " . note
	}
	return result
}

CollectReleaseNoteVersions() {
	versions := []
	rnDir := A_ScriptDir . "\release_notes"
	Loop, Files, %rnDir%\*, D
	{
		versions.Push(A_LoopFileName)
	}
	; Sort reverse-alphabetically (newest first)
	BubbleSort(versions, "CompareVersionDesc")
	return versions
}
