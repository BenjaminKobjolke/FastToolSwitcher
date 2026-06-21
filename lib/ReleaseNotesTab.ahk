; ==================== ReleaseNotesTab.ahk ====================
; Release Notes tab of the Settings GUI: initial build plus the prev/next
; navigation. Loading + formatting a single version lives in LoadReleaseNote
; (lib/Utils.ahk) so the build and the navigation share one source.
; Contains labels, so it must be #Included AFTER the auto-execute section.

; Build the Release Notes tab into the Settings GUI. Caller has already created
; the GUI and selected the tab via the Tab3 control.
BuildReleaseNotesTab() {
	global                       ; control vars (vRNVersionText, ...) must be global
	local rnHasVersions, note, rnInitVersion, rnInitDate, rnInitNotes
	local olderDisabled, newerDisabled, rnBg

	Gui, Settings:Tab, Release Notes

	RNVersions := CollectReleaseNoteVersions()
	if (!CurrentRNIndex || CurrentRNIndex < 1 || CurrentRNIndex > RNVersions.Length())
		CurrentRNIndex := 1

	rnHasVersions := (RNVersions.Length() > 0)
	if (rnHasVersions)
	{
		note := LoadReleaseNote(RNVersions[CurrentRNIndex])
		rnInitVersion := note.version
		rnInitDate := note.date
		rnInitNotes := note.notesText
	}
	else
	{
		rnInitVersion := ""
		rnInitDate := ""
		rnInitNotes := "No release notes available."
	}

	; Version header
	ApplyThemeFont("Settings", "s14 Bold")
	Gui, Settings:Add, Text, x20 y50 w300 vRNVersionText, %rnInitVersion%

	; Navigation buttons
	ApplyThemeFont("Settings", "s10 Normal")
	olderDisabled := (!rnHasVersions || CurrentRNIndex >= RNVersions.Length()) ? " Disabled" : ""
	newerDisabled := (!rnHasVersions || CurrentRNIndex <= 1) ? " Disabled" : ""
	Gui, Settings:Add, Button, x350 y47 w70 gRNOlder vBtnRNOlder%olderDisabled%, < Older
	Gui, Settings:Add, Button, x425 y47 w70 gRNNewer vBtnRNNewer%newerDisabled%, Newer >

	; Date
	ApplyThemeFont("Settings", "s10 Normal", "cSilver", "cGray")
	Gui, Settings:Add, Text, x20 y78 w480 vRNDateText, %rnInitDate%

	; Notes as read-only multi-line Edit
	ApplyThemeFont("Settings", "s11 Normal")
	rnBg := (DarkMode = 1) ? " Background0x1E1E1E" : ""
	Gui, Settings:Add, Edit, % "x20 y115 w480 h350 vRNNotesEdit +ReadOnly +Multi -WantReturn -E0x200 -TabStop" . rnBg, %rnInitNotes%

	; Reset font for the controls the caller adds after this tab
	ApplyThemeFont("Settings", "s12")
}

; ---------- Labels ----------

RNOlder:
	global CurrentRNIndex, RNVersions
	if (CurrentRNIndex < RNVersions.Length())
		CurrentRNIndex++
	Gosub, UpdateReleaseNotes
return

RNNewer:
	global CurrentRNIndex
	if (CurrentRNIndex > 1)
		CurrentRNIndex--
	Gosub, UpdateReleaseNotes
return

UpdateReleaseNotes:
	global CurrentRNIndex, RNVersions
	if (RNVersions.Length() = 0)
		return

	rnNote := LoadReleaseNote(RNVersions[CurrentRNIndex])
	GuiControl, Settings:, RNVersionText, % rnNote.version
	GuiControl, Settings:, RNDateText, % rnNote.date
	GuiControl, Settings:, RNNotesEdit, % rnNote.notesText

	; Enable/disable navigation buttons at boundaries
	if (CurrentRNIndex >= RNVersions.Length())
		GuiControl, Settings:Disable, BtnRNOlder
	else
		GuiControl, Settings:Enable, BtnRNOlder

	if (CurrentRNIndex <= 1)
		GuiControl, Settings:Disable, BtnRNNewer
	else
		GuiControl, Settings:Enable, BtnRNNewer
return
