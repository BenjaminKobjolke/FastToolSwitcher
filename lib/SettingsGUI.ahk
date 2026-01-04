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
	if (DarkMode = 1)
	{
		Gui, Settings:Color, 0x1E1E1E, 0x2D2D2D
		Gui, Settings:Font, cSilver
	}
	else
	{
		Gui, Settings:Font, cBlack
	}

	Gui, Settings:Add, Tab3, x10 y10 w460 h350 vSettingsTab, Settings|Tools|Design

	; === Settings Tab ===
	Gui, Settings:Tab, Settings
	Gui, Settings:Add, Checkbox, x20 y50 vChkMainHotkeyEnabled Checked%MainHotkeyEnabled%, Enable window cycling hotkey

	; Parse current hotkey into components
	parsedHk := ParseHotkey(MainHotkey)
	hkCtrl := parsedHk.ctrl
	hkShift := parsedHk.shift
	hkAlt := parsedHk.alt
	hkWin := parsedHk.win
	hkKey := parsedHk.key

	Gui, Settings:Add, Text, x20 y80, Hotkey:
	Gui, Settings:Add, Checkbox, x70 y80 vChkHkCtrl Checked%hkCtrl%, Ctrl
	Gui, Settings:Add, Checkbox, x120 y80 vChkHkShift Checked%hkShift%, Shift
	Gui, Settings:Add, Checkbox, x175 y80 vChkHkAlt Checked%hkAlt%, Alt
	Gui, Settings:Add, Checkbox, x220 y80 vChkHkWin Checked%hkWin%, Win
	Gui, Settings:Add, Text, x265 y80, Key:
	Gui, Settings:Add, Edit, x295 y77 w60 vHkMainKey ReadOnly, %hkKey%
	Gui, Settings:Add, Button, x360 y76 w35 gSetMainKey, Set

	if (DarkMode = 1)
		Gui, Settings:Add, Text, x20 y105 cGray, (Cycles windows of same process)
	else
		Gui, Settings:Add, Text, x20 y105 cGray, (Cycles windows of same process)
	Gui, Settings:Add, Checkbox, x20 y130 vChkMoveMouse Checked%MoveMouse% gToggleSpeedVisibility, Move mouse to center of window when switching
	hideSpeed := (MoveMouse = 1) ? 0 : 1
	Gui, Settings:Add, Text, x40 y160 vTxtMouseSpeed Hidden%hideSpeed%, Mouse move speed (0 = instant):
	Gui, Settings:Add, Slider, x200 y157 w150 h25 Range0-10 ToolTip vSliderMouseMoveSpeed Hidden%hideSpeed%, %MouseMoveSpeed%
	Gui, Settings:Add, Checkbox, x20 y195 vChkStartWithWindows Checked%StartWithWindows%, Start with Windows

	; === Tools Tab ===
	Gui, Settings:Tab, Tools
	Gui, Settings:Add, ListView, x20 y50 w430 h240 vToolListView gToolListViewAction AltSubmit +LV0x10000, Name|Hotkey|Exe Name|Path

	; Populate ListView with tools
	for index, tool in Tools
	{
		LV_Add("", tool.Name, tool.Hotkey, tool.ExeName, tool.ExePath)
	}

	; Auto-size columns
	LV_ModifyCol(1, 100)
	LV_ModifyCol(2, 60)
	LV_ModifyCol(3, 100)
	LV_ModifyCol(4, 150)

	Gui, Settings:Add, Button, x20 y300 w70 gToolAdd, Add
	Gui, Settings:Add, Button, x100 y300 w70 gToolEdit, Edit
	Gui, Settings:Add, Button, x180 y300 w70 gToolDelete, Delete

	; === Design Tab ===
	Gui, Settings:Tab, Design
	Gui, Settings:Add, Text, x20 y50, Theme:
	darkModeChecked := (DarkMode = 1) ? 1 : 0
	lightModeChecked := (DarkMode = 1) ? 0 : 1
	Gui, Settings:Add, Radio, x20 y75 vRadioDarkMode Checked%darkModeChecked% gThemePreview, Dark Mode
	Gui, Settings:Add, Radio, x20 y100 Checked%lightModeChecked% gThemePreview, Light Mode

	; === Bottom buttons (outside tabs) ===
	Gui, Settings:Tab
	Gui, Settings:Add, Button, x300 y370 w80 gSaveSettings Default, Save
	Gui, Settings:Add, Button, x390 y370 w80 gSettingsGuiClose, Cancel

	; Add link at bottom
	if (DarkMode = 1)
		Gui, Settings:Font, cAqua
	else
		Gui, Settings:Font, cBlue
	Gui, Settings:Add, Text, x20 y378 gOpenMoreTools, More tools to improve your workflow
	if (DarkMode = 1)
		Gui, Settings:Font, cSilver
	else
		Gui, Settings:Font, cBlack

	Gui, Settings:Show, w480 h410

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

SetMainKey:
	; Capture single key when Set button is clicked
	CaptureKeyToControl("Settings", "HkMainKey")
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

	; Build main hotkey from checkboxes and key field
	builtMainHotkey := BuildHotkey(ChkHkCtrl, ChkHkShift, ChkHkAlt, ChkHkWin, HkMainKey)

	; Save main settings
	IniWrite, %ChkMainHotkeyEnabled%, %IniFile%, Settings, MainHotkeyEnabled
	IniWrite, %builtMainHotkey%, %IniFile%, Settings, MainHotkey
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
		tArguments := ""
		tExcludeTitle := ""
		if (A_Index <= Tools.Length())
		{
			tWindowTitle := Tools[A_Index].WindowTitle
			tArguments := Tools[A_Index].Arguments
			tExcludeTitle := Tools[A_Index].ExcludeTitle
		}

		section := "Tool" . A_Index
		IniWrite, %tName%, %IniFile%, %section%, Name
		IniWrite, %tHotkey%, %IniFile%, %section%, Hotkey
		IniWrite, %tExeName%, %IniFile%, %section%, ExeName
		IniWrite, %tExePath%, %IniFile%, %section%, ExePath
		IniWrite, %tWindowTitle%, %IniFile%, %section%, WindowTitle
		IniWrite, %tArguments%, %IniFile%, %section%, Arguments
		IniWrite, %tExcludeTitle%, %IniFile%, %section%, ExcludeTitle
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
		MsgBox, 48, Tool Switcher, Please select a tool to edit.
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
		MsgBox, 48, Tool Switcher, Please select a tool to delete.
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
