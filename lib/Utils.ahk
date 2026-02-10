; ==================== Utils.ahk ====================
; Dark Mode Helper Functions

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

CollectReleaseNoteVersions() {
	versions := []
	rnDir := A_ScriptDir . "\release_notes"
	Loop, Files, %rnDir%\*, D
	{
		versions.Push(A_LoopFileName)
	}
	; Sort reverse-alphabetically (newest first)
	n := versions.Length()
	Loop
	{
		swapped := false
		Loop, % n - 1
		{
			if (versions[A_Index] < versions[A_Index + 1])
			{
				tmp := versions[A_Index]
				versions[A_Index] := versions[A_Index + 1]
				versions[A_Index + 1] := tmp
				swapped := true
			}
		}
		if (!swapped)
			break
	}
	return versions
}
