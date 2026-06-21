; ==================== SettingsGUI.ahk ====================
; Main settings window with tabs

ShowSettings:
	; Suspend hotkeys while GUI is open
	Suspend, On
	Menu, Tray, Icon, %IconPath%  ; Re-apply icon after suspend

	; Destroy existing GUI if any
	Gui, Settings:Destroy

	; Create main settings window with tabs
	Gui, Settings:New, +Resize, Tool Switcher Settings

	; Apply theme colors and font BEFORE adding controls
	ApplyThemeWindowColors("Settings")
	ApplyThemeFont("Settings", "s12")

	Gui, Settings:Add, Tab3, x10 y10 w520 h585 vSettingsTab, Settings|Tools|Design|Release Notes

	; === Settings Tab ===
	; Each function uses the shared hotkey-list row (lib/HotkeyList.ahk): an enable
	; checkbox, a ListBox of bound hotkeys, and Add/Edit/Remove (the popup editor
	; composes each hotkey). Multiple hotkeys may be bound to one function.
	Gui, Settings:Tab, Settings

	AddHotkeyListRow("Settings", {prefix: "Main", yBase: 50, listValue: MainHotkey, withEnable: 1, enableLabel: "Enable window cycling hotkey", enableChecked: MainHotkeyEnabled})
	AddHotkeyListRow("Settings", {prefix: "Ov", yBase: 160, listValue: OverviewHotkey, withEnable: 1, enableLabel: "Enable shortcuts overview hotkey", enableChecked: OverviewHotkeyEnabled})
	AddHotkeyListRow("Settings", {prefix: "Rev", yBase: 270, listValue: MainHotkeyReversed, withEnable: 1, enableLabel: "Enable reverse window cycling hotkey", enableChecked: MainHotkeyReversedEnabled})
	AddHotkeyListRow("Settings", {prefix: "Ign", yBase: 380, listValue: IgnoreHotkey, withEnable: 1, enableLabel: "Enable ignore window hotkey", enableChecked: IgnoreHotkeyEnabled})

	; Mouse + startup options
	Gui, Settings:Add, Checkbox, x20 y495 vChkMoveMouse Checked%MoveMouse% gToggleSpeedVisibility, Move mouse to center of window when switching
	hideSpeed := (MoveMouse = 1) ? 0 : 1
	Gui, Settings:Add, Text, x40 y530 vTxtMouseSpeed Hidden%hideSpeed%, Mouse move speed (0 = instant):
	Gui, Settings:Add, Slider, x280 y527 w150 h25 Range0-10 ToolTip vSliderMouseMoveSpeed Hidden%hideSpeed%, %MouseMoveSpeed%
	Gui, Settings:Add, Checkbox, x20 y562 vChkStartWithWindows Checked%StartWithWindows%, Start with Windows

	; === Tools Tab ===
	Gui, Settings:Tab, Tools
	Gui, Settings:Add, ListView, x20 y50 w490 h300 vToolListView gToolListViewAction AltSubmit +LV0x10000, Name|Hotkey|Exe Name|Path

	; Populate ListView with tools
	for index, tool in Tools
	{
		LV_Add("", tool.Name, tool.Hotkey, tool.ExeName, tool.ExePath)
	}

	; Auto-size columns
	LV_ModifyCol(1, 120)
	LV_ModifyCol(2, 80)
	LV_ModifyCol(3, 120)
	LV_ModifyCol(4, 150)

	Gui, Settings:Add, Button, x20 y360 w80 gToolAdd, Add
	Gui, Settings:Add, Button, x110 y360 w80 gToolEdit, Edit
	Gui, Settings:Add, Button, x200 y360 w80 gToolDelete, Delete

	; === Design Tab ===
	Gui, Settings:Tab, Design
	Gui, Settings:Add, Text, x20 y50, Theme:
	darkModeChecked := (DarkMode = 1) ? 1 : 0
	lightModeChecked := (DarkMode = 1) ? 0 : 1
	Gui, Settings:Add, Radio, x20 y85 vRadioDarkMode Checked%darkModeChecked% gThemePreview, Dark Mode
	Gui, Settings:Add, Radio, x20 y120 Checked%lightModeChecked% gThemePreview, Light Mode

	; === Release Notes Tab ===
	BuildReleaseNotesTab()

	; === Bottom buttons (outside tabs) ===
	Gui, Settings:Tab
	Gui, Settings:Add, Button, x350 y605 w90 gSaveSettings Default, Save
	Gui, Settings:Add, Button, x450 y605 w90 gSettingsGuiClose, Cancel

	; Add link at bottom
	ApplyThemeFont("Settings", "", "cAqua", "cBlue")
	Gui, Settings:Add, Text, x20 y613 gOpenMoreTools, More tools to improve your workflow
	ApplyThemeFont("Settings", "s12")

	Gui, Settings:Show, w550 h645

	; Apply dark mode to window after showing
	if (DarkMode = 1)
	{
		Gui, Settings:+LastFound
		settingsHwnd := WinExist()
		ApplyDarkMode(settingsHwnd)

		; Apply dark theme to ListView
		GuiControlGet, lvHwnd, Settings:Hwnd, ToolListView
		ApplyDarkListView(lvHwnd)
	}
return

ThemePreview:
	Gui, Settings:Submit, NoHide
	; Store new theme preference and rebuild GUI to apply font color
	DarkMode := RadioDarkMode
	Gui, Settings:Destroy
	Gosub, ShowSettings
	; Switch back to Design tab
	GuiControl, Settings:Choose, SettingsTab, 3
return

ToggleSpeedVisibility:
	Gui, Settings:Submit, NoHide
	if (ChkMoveMouse)
	{
		GuiControl, Settings:Show, TxtMouseSpeed
		GuiControl, Settings:Show, SliderMouseMoveSpeed
	}
	else
	{
		GuiControl, Settings:Hide, TxtMouseSpeed
		GuiControl, Settings:Hide, SliderMouseMoveSpeed
	}
return

SettingsGuiClose:
SettingsGuiEscape:
	Suspend, Off
	Gui, Settings:Destroy
return

ToolListViewAction:
	if (A_GuiEvent = "DoubleClick")
		Gosub, ToolEdit
return

SaveSettings:
	Gui, Settings:Submit, NoHide

	; Hotkey lists come straight from each row's list field (already "|"-joined)
	builtMainHotkey := MainList
	builtOverviewHotkey := OvList
	builtReverseHotkey := RevList
	builtIgnoreHotkey := IgnList

	; Check for duplicate hotkey assignments across enabled functions + tools.
	; Each value may contain multiple hotkeys; the shared scan expands them.
	dupPairs := []
	if (MainEnabled = 1)
		dupPairs.Push({list: builtMainHotkey, owner: "Window Cycling"})
	if (OvEnabled = 1)
		dupPairs.Push({list: builtOverviewHotkey, owner: "Shortcuts Overview"})
	if (RevEnabled = 1)
		dupPairs.Push({list: builtReverseHotkey, owner: "Reverse Window Cycling"})
	if (IgnEnabled = 1)
		dupPairs.Push({list: builtIgnoreHotkey, owner: "Ignore Window"})
	Gui, Settings:Default
	Gui, ListView, ToolListView
	dupToolCount := LV_GetCount()
	Loop, %dupToolCount%
	{
		LV_GetText(dupName, A_Index, 1)
		LV_GetText(dupHotkey, A_Index, 2)
		if (dupHotkey != "")
			dupPairs.Push({list: dupHotkey, owner: (dupName != "" ? dupName : "Tool " . A_Index)})
	}
	dupMsg := CollectHotkeyDuplicates(dupPairs)
	if (dupMsg != "")
	{
		MsgBox, 48, %APP_TITLE% - Duplicate Hotkeys, The following hotkey conflicts were detected:`n`n%dupMsg%`nPlease choose different hotkeys.
		return
	}

	; Save main settings
	IniWrite, %MainEnabled%, %IniFile%, Settings, MainHotkeyEnabled
	IniWrite, %builtMainHotkey%, %IniFile%, Settings, MainHotkey
	IniWrite, %RevEnabled%, %IniFile%, Settings, MainHotkeyReversedEnabled
	IniWrite, %builtReverseHotkey%, %IniFile%, Settings, MainHotkeyReversed
	IniWrite, %OvEnabled%, %IniFile%, Settings, OverviewHotkeyEnabled
	IniWrite, %builtOverviewHotkey%, %IniFile%, Settings, OverviewHotkey
	IniWrite, %IgnEnabled%, %IniFile%, Settings, IgnoreHotkeyEnabled
	IniWrite, %builtIgnoreHotkey%, %IniFile%, Settings, IgnoreHotkey
	IniWrite, %ChkMoveMouse%, %IniFile%, Settings, MoveMouse
	IniWrite, %SliderMouseMoveSpeed%, %IniFile%, Settings, MouseMoveSpeed
	IniWrite, %RadioDarkMode%, %IniFile%, Settings, DarkMode
	IniWrite, %ChkStartWithWindows%, %IniFile%, Settings, StartWithWindows

	; Handle Windows startup registry
	RegKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
	if (ChkStartWithWindows = 1)
	{
		; Get the path to use (compiled exe or script)
		if (A_IsCompiled)
			StartupPath := """" . A_ScriptFullPath . """"
		else
			StartupPath := """" . A_AhkPath . """ """ . A_ScriptFullPath . """"
		RegWrite, REG_SZ, %RegKey%, FastToolSwitcher, %StartupPath%
	}
	else
	{
		RegDelete, %RegKey%, FastToolSwitcher
	}

	; Save tools - rebuild from ListView
	Gui, Settings:Default
	Gui, ListView, ToolListView
	newToolCount := LV_GetCount()
	IniWrite, %newToolCount%, %IniFile%, Tools, ToolCount

	Loop, %newToolCount%
	{
		LV_GetText(tName, A_Index, 1)
		LV_GetText(tHotkey, A_Index, 2)
		LV_GetText(tExeName, A_Index, 3)
		LV_GetText(tExePath, A_Index, 4)

		; Get additional fields from Tools array if exists
		tWindowTitle := ""
		tWindowClass := ""
		tArguments := ""
		tExcludeTitle := ""
		tSendToBackground := 0
		if (A_Index <= Tools.Length())
		{
			tWindowTitle := Tools[A_Index].WindowTitle
			tWindowClass := Tools[A_Index].WindowClass
			tArguments := Tools[A_Index].Arguments
			tExcludeTitle := Tools[A_Index].ExcludeTitle
			tSendToBackground := Tools[A_Index].SendToBackground
		}

		section := "Tool" . A_Index
		IniWrite, %tName%, %IniFile%, %section%, Name
		IniWrite, %tHotkey%, %IniFile%, %section%, Hotkey
		IniWrite, %tExeName%, %IniFile%, %section%, ExeName
		IniWrite, %tExePath%, %IniFile%, %section%, ExePath
		IniWrite, %tWindowTitle%, %IniFile%, %section%, WindowTitle
		IniWrite, %tWindowClass%, %IniFile%, %section%, WindowClass
		IniWrite, %tArguments%, %IniFile%, %section%, Arguments
		IniWrite, %tExcludeTitle%, %IniFile%, %section%, ExcludeTitle
		IniWrite, %tSendToBackground%, %IniFile%, %section%, SendToBackground
	}

	Suspend, Off
	Gui, Settings:Destroy
	Reload
return

ToolAdd:
	EditingToolIndex := 0
	Gosub, ShowToolDialog
return

ToolEdit:
	Gui, Settings:Default
	Gui, ListView, ToolListView
	EditingToolIndex := LV_GetNext()
	if (EditingToolIndex = 0)
	{
		MsgBox, 48, %APP_TITLE%, Please select a tool to edit.
		return
	}
	Gosub, ShowToolDialog
return

ToolDelete:
	Gui, Settings:Default
	Gui, ListView, ToolListView
	selectedRow := LV_GetNext()
	if (selectedRow = 0)
	{
		MsgBox, 48, %APP_TITLE%, Please select a tool to delete.
		return
	}

	LV_GetText(toolName, selectedRow, 1)
	MsgBox, 36, Confirm Delete, Are you sure you want to delete "%toolName%"?
	IfMsgBox, Yes
	{
		LV_Delete(selectedRow)
		if (selectedRow <= Tools.Length())
			Tools.RemoveAt(selectedRow)
	}
return

OpenMoreTools:
	Run, http://workflow-tools.com/fast-tool-switcher/app-link
return
