; ==================== HotkeyEditor.ahk ====================
; Popup hotkey composer (modifier checkboxes + captured key) plus the Add / Edit
; / Remove handlers for the hotkey-list rows built by AddHotkeyListRow
; (lib/HotkeyList.ahk). Contains labels, so it must be #Included AFTER the
; auto-execute section.

; Open the popup to add a new hotkey (editIndex = 0) or edit an existing one
; (editIndex = the 1-based row of the owner's hotkey list). On OK the result is
; written back to the owner row via SetHotkeyListValue.
OpenHotkeyEditor(guiName, prefix, editIndex) {
	global
	local seedCtrl, seedShift, seedAlt, seedWin, seedKey, joined, arr, p, ownerHwnd

	HkEdOwnerGui := guiName
	HkEdPrefix := prefix
	HkEdIndex := editIndex

	seedCtrl := 0, seedShift := 0, seedAlt := 0, seedWin := 0, seedKey := ""
	if (editIndex > 0)
	{
		GuiControlGet, joined, %guiName%:, %prefix%List
		arr := SplitHotkeyList(joined)
		if (editIndex <= arr.Length())
		{
			p := ParseHotkey(arr[editIndex])
			seedCtrl := p.ctrl, seedShift := p.shift, seedAlt := p.alt, seedWin := p.win, seedKey := p.key
		}
	}

	; Disable the owner window for a modal feel (remembered for re-activation)
	Gui, %guiName%:+LastFound
	ownerHwnd := WinExist()
	HkEdOwnerHwnd := ownerHwnd
	Gui, %guiName%:+Disabled

	Gui, HotkeyEditor:Destroy
	Gui, HotkeyEditor:New, % "+Owner" . ownerHwnd, % (editIndex > 0 ? "Edit Hotkey" : "Add Hotkey")
	if (DarkMode = 1)
	{
		Gui, HotkeyEditor:Color, 0x1E1E1E, 0x2D2D2D
		Gui, HotkeyEditor:Font, s12 cWhite
	}
	else
		Gui, HotkeyEditor:Font, s12 cBlack

	Gui, HotkeyEditor:Add, Text, x15 y15, Modifiers:
	Gui, HotkeyEditor:Add, Checkbox, x15 y45 vHkEdCtrl Checked%seedCtrl%, Ctrl
	Gui, HotkeyEditor:Add, Checkbox, x75 y45 vHkEdShift Checked%seedShift%, Shift
	Gui, HotkeyEditor:Add, Checkbox, x150 y45 vHkEdAlt Checked%seedAlt%, Alt
	Gui, HotkeyEditor:Add, Checkbox, x205 y45 vHkEdWin Checked%seedWin%, Win
	Gui, HotkeyEditor:Add, Text, x15 y85, Key:
	Gui, HotkeyEditor:Add, Edit, x60 y82 w100 ReadOnly vHkEdKey, %seedKey%
	Gui, HotkeyEditor:Add, Button, x170 y81 w70 vHkEdSetBtn gSetKey, Set
	Gui, HotkeyEditor:Add, Button, x60 y130 w80 gHotkeyEditorOK Default, OK
	Gui, HotkeyEditor:Add, Button, x150 y130 w80 gHotkeyEditorClose, Cancel
	Gui, HotkeyEditor:Show, w260 h180

	if (DarkMode = 1)
	{
		Gui, HotkeyEditor:+LastFound
		ApplyDarkMode(WinExist())
	}
}

; ---------- Labels ----------

; Shared key-capture for any composer row (Settings/ToolDialog rows + popup).
; The control's variable name carries the prefix (e.g. "HkEdSetBtn" -> "HkEd").
SetKey:
	hkPrefix := RowPrefixFromControl()
	CaptureKeyToControl(A_Gui, hkPrefix . "Key")
return

AddHotkeyEntry:
	OpenHotkeyEditor(A_Gui, RowPrefixFromControl(), 0)
return

EditHotkeyEntry:
	hkEditGui := A_Gui
	hkPrefix := RowPrefixFromControl()
	hkSelIdx := GetListBoxSelectedIndex(hkEditGui, hkPrefix . "ListBox")
	if (hkSelIdx = 0)
	{
		MsgBox, 48, Tool Switcher, Please select a hotkey to edit.
		return
	}
	OpenHotkeyEditor(hkEditGui, hkPrefix, hkSelIdx)
return

RemoveHotkeyEntry:
	hkRemGui := A_Gui
	hkPrefix := RowPrefixFromControl()
	hkSelIdx := GetListBoxSelectedIndex(hkRemGui, hkPrefix . "ListBox")
	if (hkSelIdx = 0)
	{
		MsgBox, 48, Tool Switcher, Please select a hotkey to remove.
		return
	}
	GuiControlGet, hkRemJoined, %hkRemGui%:, %hkPrefix%List
	hkRemArr := SplitHotkeyList(hkRemJoined)
	if (hkSelIdx <= hkRemArr.Length())
		hkRemArr.RemoveAt(hkSelIdx)
	SetHotkeyListValue(hkRemGui, hkPrefix, JoinHotkeyList(hkRemArr))
return

HotkeyEditorOK:
	Gui, HotkeyEditor:Submit, NoHide
	hkBuilt := BuildHotkey(HkEdCtrl, HkEdShift, HkEdAlt, HkEdWin, HkEdKey)
	if (!IsCapturedKeyValid(HkEdKey) || hkBuilt = "")
	{
		MsgBox, 48, Tool Switcher, Please set a key for the hotkey.
		return
	}
	GuiControlGet, hkOkJoined, %HkEdOwnerGui%:, %HkEdPrefix%List
	hkOkArr := SplitHotkeyList(hkOkJoined)
	if (HkEdIndex > 0 && HkEdIndex <= hkOkArr.Length())
		hkOkArr[HkEdIndex] := hkBuilt
	else
		hkOkArr.Push(hkBuilt)
	; De-duplicate (case-insensitive) while preserving order
	hkSeen := {}
	hkDeduped := []
	for hkI, hkVal in hkOkArr
	{
		StringLower, hkKeyLower, hkVal
		if (!hkSeen.HasKey(hkKeyLower))
		{
			hkSeen[hkKeyLower] := 1
			hkDeduped.Push(hkVal)
		}
	}
	SetHotkeyListValue(HkEdOwnerGui, HkEdPrefix, JoinHotkeyList(hkDeduped))
	Gui, %HkEdOwnerGui%:-Disabled
	Gui, HotkeyEditor:Destroy
	WinActivate, ahk_id %HkEdOwnerHwnd%
return

HotkeyEditorClose:
HotkeyEditorEscape:
	Gui, %HkEdOwnerGui%:-Disabled
	Gui, HotkeyEditor:Destroy
	WinActivate, ahk_id %HkEdOwnerHwnd%
return
