; ==================== HotkeyList.ahk ====================
; Multiple-hotkeys-per-action support. A single stored value holds a list of
; hotkeys joined with "|"; these helpers derive the list on demand so the rest
; of the code base keeps passing the raw string around. Functions only (no
; labels) - safe to #Include anywhere.

; Split a "|"-joined hotkey string into an array of non-empty hotkey strings.
SplitHotkeyList(str) {
	result := []
	for index, part in StrSplit(str, "|")
	{
		trimmed := Trim(part)
		if (trimmed != "")
			result.Push(trimmed)
	}
	return result
}

; Join an array of hotkey strings back into a "|"-joined string.
JoinHotkeyList(arr) {
	out := ""
	for index, hk in arr
		out .= (out = "" ? "" : "|") . hk
	return out
}

; Whether a "|"-joined list contains the given hotkey (case-insensitive).
HotkeyListContains(str, hk) {
	for index, item in SplitHotkeyList(str)
	{
		if (item = hk)
			return true
	}
	return false
}

; Human-readable display of a hotkey list, e.g. "Ctrl + .  ,  Ctrl + Alt + P".
FormatHotkeyList(str) {
	out := ""
	for index, hk in SplitHotkeyList(str)
		out .= (out = "" ? "" : "  ,  ") . FormatHotkeyDisplay(hk)
	return out
}

; Register every hotkey in a list to the same label.
RegisterHotkeyList(str, label) {
	for index, hk in SplitHotkeyList(str)
		Hotkey, %hk%, %label%
}

; Scan {list, owner} pairs for any hotkey assigned to two owners.
; Returns aggregated warning lines ("" when none) in the same format the
; startup and save-time duplicate checks expect.
CollectHotkeyDuplicates(pairs) {
	seen := {}
	warnings := ""
	for i, p in pairs
	{
		if (p.list = "")
			continue
		for j, hk in SplitHotkeyList(p.list)
		{
			StringLower, key, hk
			if (seen.HasKey(key))
				warnings .= "- '" . p.owner . "' conflicts with '" . seen[key] . "' (hotkey: " . hk . ")`n"
			else
				seen[key] := p.owner
		}
	}
	return warnings
}

; ---------- GUI: shared hotkey list row ----------
; Builds one hotkey-list row into the named GUI: an optional enable checkbox, a
; ListBox showing the bound hotkeys, Add/Edit/Remove buttons, and a hidden
; ReadOnly Edit that holds the canonical "|"-joined value (the source of truth
; read by Gui Submit / save). Control names are derived from `prefix` so a single
; set of handlers serves every instance. The actual compose/edit happens in the
; popup hotkey editor (lib/HotkeyEditor.ahk).
; cfg fields (one object instead of a long parameter list):
;   prefix       - unique per row (e.g. "Main", "Ov", "Rev", "Ign", "Td")
;   yBase        - top y of the group
;   listValue    - initial "|"-joined hotkey list
;   withEnable   - 1 to emit the leading enable checkbox (global functions),
;                  0 for the tool dialog (no enable)
;   enableLabel  - text for the enable checkbox (when withEnable = 1)
;   enableChecked- initial checked state for the enable checkbox
AddHotkeyListRow(guiName, cfg) {
	; Assume-global: control variables created here (vMainList, vMainListBox, ...)
	; must be global so Gui Submit can populate them and the save handlers read them.
	global
	local yRow, prefix, yBase, listValue
	prefix := cfg.prefix
	yBase := cfg.yBase
	listValue := cfg.listValue
	if (cfg.withEnable)
	{
		Gui, %guiName%:Add, Checkbox, % "x20 y" . yBase . " v" . prefix . "Enabled Checked" . cfg.enableChecked, % cfg.enableLabel
		yRow := yBase + 28
	}
	else
		yRow := yBase

	; Visible list of bound hotkeys (selectable; rendered from the hidden value)
	Gui, %guiName%:Add, ListBox, % "x20 y" . yRow . " w300 h74 v" . prefix . "ListBox"
	; Add / Edit / Remove
	Gui, %guiName%:Add, Button, % "x330 y" . yRow . " w90 h24 v" . prefix . "AddBtn gAddHotkeyEntry", Add
	Gui, %guiName%:Add, Button, % "x330 y" . (yRow + 25) . " w90 h24 v" . prefix . "EditBtn gEditHotkeyEntry", Edit
	Gui, %guiName%:Add, Button, % "x330 y" . (yRow + 50) . " w90 h24 v" . prefix . "RemoveBtn gRemoveHotkeyEntry", Remove
	; Hidden canonical "|"-joined value (read on save)
	Gui, %guiName%:Add, Edit, % "x20 y" . yRow . " w1 h1 Hidden ReadOnly v" . prefix . "List", %listValue%

	RenderHotkeyListBox(guiName, prefix)
}

; Write a row's canonical hidden value and re-render its ListBox. Single place
; that mutates a row, so the visible list never drifts from the stored string.
SetHotkeyListValue(guiName, prefix, joined) {
	GuiControl, %guiName%:, %prefix%List, %joined%
	RenderHotkeyListBox(guiName, prefix)
}

; Rebuild the ListBox rows (human-readable) from the hidden "|"-joined value.
; Row order matches SplitHotkeyList order, so a selected row index maps directly
; to the same index in the split array.
RenderHotkeyListBox(guiName, prefix) {
	GuiControlGet, joined, %guiName%:, %prefix%List
	content := ""
	for index, hk in SplitHotkeyList(joined)
		content .= "|" . FormatHotkeyDisplay(hk)
	if (content = "")
		content := "|"   ; leading pipe replaces (clears) the list
	GuiControl, %guiName%:, %prefix%ListBox, %content%
}

; Row prefix for the control that fired the current GUI thread, e.g. button
; "MainAddBtn"/"TdSetBtn"/"HkEdSetBtn" -> "Main"/"Td"/"HkEd".
RowPrefixFromControl() {
	return RegExReplace(A_GuiControl, "(SetBtn|AddBtn|EditBtn|RemoveBtn)$", "")
}

; 1-based index of the selected ListBox row, or 0 if none.
GetListBoxSelectedIndex(guiName, ctrl) {
	GuiControlGet, h, %guiName%:Hwnd, %ctrl%
	SendMessage, 0x188, 0, 0, , ahk_id %h%   ; LB_GETCURSEL
	if (ErrorLevel = 0xFFFFFFFF)
		return 0
	return ErrorLevel + 1
}
