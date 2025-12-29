#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance force
#Persistent ;Script nicht beenden nach der Auto-Execution-Section

SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2


Menu, tray, NoStandard
Menu, tray, add, Settings, ShowSettings
Menu, tray, add  ; Creates a separator line.
Menu, tray, add, Reload
Menu, tray, add, Exit

; Get script name without extension for INI file
SplitPath, A_ScriptName,, , , ScriptNameNoExt
IniFile := A_ScriptDir . "\" . ScriptNameNoExt . ".ini"

; Read main settings from INI
IniRead, MainHotkeyEnabled, %IniFile%, Settings, MainHotkeyEnabled, 1
IniRead, MainHotkey, %IniFile%, Settings, MainHotkey, ^+Space
IniRead, MoveMouse, %IniFile%, Settings, MoveMouse, 1
IniRead, DarkMode, %IniFile%, Settings, DarkMode, 1

; Check for command line arguments
ShowGuiOnStart := false
for n, arg in A_Args
{
	if (arg = "--gui" || arg = "-g")
		ShowGuiOnStart := true
}

; Read tool count from INI
IniRead, ToolCount, %IniFile%, Tools, ToolCount, 0

; If no tools configured, create default INI
if (ToolCount = 0)
{
	; Create default configuration
	IniWrite, 2, %IniFile%, Tools, ToolCount

	; Brave
	IniWrite, Brave, %IniFile%, Tool1, Name
	IniWrite, ^+b, %IniFile%, Tool1, Hotkey
	IniWrite, brave.exe, %IniFile%, Tool1, ExeName
	IniWrite, Brave, %IniFile%, Tool1, WindowTitle
	IniWrite, %A_Space%, %IniFile%, Tool1, ExePath

	; Firefox
	IniWrite, Firefox, %IniFile%, Tool2, Name
	IniWrite, ^+h, %IniFile%, Tool2, Hotkey
	IniWrite, firefox.exe, %IniFile%, Tool2, ExeName
	IniWrite, %A_Space%, %IniFile%, Tool2, WindowTitle
	IniWrite, %A_Space%, %IniFile%, Tool2, ExePath

	ToolCount := 2
}

; Initialize tool arrays
Tools := []

; Load all tools from INI
Loop, %ToolCount%
{
	ToolSection := "Tool" . A_Index

	IniRead, ToolName, %IniFile%, %ToolSection%, Name, %A_Space%
	IniRead, ToolHotkey, %IniFile%, %ToolSection%, Hotkey, %A_Space%
	IniRead, ToolExeName, %IniFile%, %ToolSection%, ExeName, %A_Space%
	IniRead, ToolWindowTitle, %IniFile%, %ToolSection%, WindowTitle, %A_Space%
	IniRead, ToolExePath, %IniFile%, %ToolSection%, ExePath, %A_Space%
	IniRead, ToolArguments, %IniFile%, %ToolSection%, Arguments, %A_Space%
	IniRead, ToolExcludeTitle, %IniFile%, %ToolSection%, ExcludeTitle, %A_Space%

	; Store tool info
	Tool := {}
	Tool.Name := ToolName
	Tool.Hotkey := ToolHotkey
	Tool.ExeName := ToolExeName
	Tool.WindowTitle := ToolWindowTitle
	Tool.ExePath := ToolExePath
	Tool.Arguments := ToolArguments
	Tool.ExcludeTitle := ToolExcludeTitle
	Tool.Section := ToolSection

	Tools.Push(Tool)
}

; Search for missing exe paths
NeedSearch := false
for index, tool in Tools
{
	if (tool.ExePath = "" || !FileExist(tool.ExePath))
		NeedSearch := true
}

if (NeedSearch)
{
	MsgBox, 64, Tool Switcher, Searching for tool executables on C drive. This may take a moment...

	for index, tool in Tools
	{
		if (tool.ExePath = "" || !FileExist(tool.ExePath))
		{
			; Try common locations first
			CommonPaths := []

			; Build common paths based on tool name patterns
			if (InStr(tool.ExeName, "brave"))
			{
				CommonPaths.Push("C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe")
				CommonPaths.Push("C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe")
				CommonPaths.Push(A_AppData . "\..\Local\BraveSoftware\Brave-Browser\Application\brave.exe")
			}
			else if (InStr(tool.ExeName, "firefox"))
			{
				CommonPaths.Push("C:\Program Files\Mozilla Firefox\firefox.exe")
				CommonPaths.Push("C:\Program Files (x86)\Mozilla Firefox\firefox.exe")
				CommonPaths.Push(A_AppData . "\..\Local\Mozilla Firefox\firefox.exe")
			}
			else if (InStr(tool.ExeName, "chrome"))
			{
				CommonPaths.Push("C:\Program Files\Google\Chrome\Application\chrome.exe")
				CommonPaths.Push("C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
				CommonPaths.Push(A_AppData . "\..\Local\Google\Chrome\Application\chrome.exe")
			}

			Found := false
			for pathIndex, path in CommonPaths
			{
				if (FileExist(path))
				{
					Tools[index].ExePath := path
					Found := true
					break
				}
			}

			; If not found in common locations, search entire C drive
			if (!Found)
			{
				searchPattern := "C:\" . tool.ExeName
				Loop, Files, %searchPattern%, R
				{
					Tools[index].ExePath := A_LoopFileFullPath
					Found := true
					break
				}
			}

			; If still not found, show error
			if (!Found)
			{
				MsgBox, 48, Tool Switcher Warning, % tool.ExeName . " could not be found on C drive. Please update the path manually in:`n" . IniFile . "`n`nSection: [" . tool.Section . "]"
				Tools[index].ExePath := ""
			}
			else
			{
				; Save the path to INI file
				IniWrite, % Tools[index].ExePath, %IniFile%, % tool.Section, ExePath
			}
		}
	}

	MsgBox, 64, Tool Switcher, Tool search completed. Configuration saved.
}

; Create hotkeys dynamically
for index, tool in Tools
{
	if (tool.Hotkey != "" && tool.ExePath != "")
	{
		Hotkey, % tool.Hotkey, HandleToolHotkey
	}
}

; Create main window cycling hotkey if enabled
if (MainHotkeyEnabled = 1 && MainHotkey != "")
{
	Hotkey, %MainHotkey%, MainWindowCycleHotkey
}

; Show GUI on start if command line arg was passed
if (ShowGuiOnStart)
	Gosub, ShowSettings

return

HandleToolHotkey:
	; Find which tool triggered this hotkey
	triggeredHotkey := A_ThisHotkey

	for index, tool in Tools
	{
		if (tool.Hotkey = triggeredHotkey)
		{
			; Determine window detection method
			if (tool.WindowTitle != "")
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
			; (WinGet returns windows in Z-order which changes after each activation)
			Loop % validWindows.Length() - 1
			{
				for i, val in validWindows
				{
					if (i < validWindows.Length() && validWindows[i] > validWindows[i+1])
					{
						temp := validWindows[i]
						validWindows[i] := validWindows[i+1]
						validWindows[i+1] := temp
					}
				}
			}

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
						; Only one valid window, send to background
						Send !{Esc}
					}
					else
					{
						; Multiple valid windows, cycle to next
						nextIndex := activeIndex + 1
						if (nextIndex > validWindows.Length())
							nextIndex := 1
						WinActivate, % "ahk_id " . validWindows[nextIndex]
						if (MoveMouse = 1)
						{
							CoordMode, Mouse, Screen
							WinGetPos, winX, winY, winW, winH, A
							MouseMove, winX + winW // 2, winY + winH // 2, 0
						}
					}
				}
				else
				{
					; No valid window is active, activate first one
					WinActivate, % "ahk_id " . validWindows[1]
					if (MoveMouse = 1)
					{
						CoordMode, Mouse, Screen
						WinGetPos, winX, winY, winW, winH, A
						MouseMove, winX + winW // 2, winY + winH // 2, 0
					}
				}
			}

			break
		}
	}
return

MainWindowCycleHotkey:
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
		validWindows.Push(windowID)
	}

	if (validWindows.Length() <= 1)
		return

	; Sort by handle for consistent ordering
	Loop % validWindows.Length() - 1
	{
		for i, val in validWindows
		{
			if (i < validWindows.Length() && validWindows[i] > validWindows[i+1])
			{
				temp := validWindows[i]
				validWindows[i] := validWindows[i+1]
				validWindows[i+1] := temp
			}
		}
	}

	; Find current window and cycle to next
	WinGet, activeID, ID, A
	nextIndex := 1
	for idx, winID in validWindows
	{
		if (winID = activeID)
		{
			nextIndex := idx + 1
			if (nextIndex > validWindows.Length())
				nextIndex := 1
			break
		}
	}

	WinActivate, % "ahk_id " . validWindows[nextIndex]
	if (MoveMouse = 1)
	{
		CoordMode, Mouse, Screen
		WinGetPos, winX, winY, winW, winH, A
		MouseMove, winX + winW // 2, winY + winH // 2, 0
	}
return

; ==================== Dark Mode Helper Functions ====================

ApplyDarkMode(hwnd) {
	; Dark title bar (Windows 10 1809+)
	DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", 20, "Int*", 1, "Int", 4)
}

ApplyDarkListView(hwndLV) {
	; Apply dark theme to ListView
	DllCall("uxtheme\SetWindowTheme", "Ptr", hwndLV, "Str", "DarkMode_Explorer", "Ptr", 0)
}

; ==================== Settings GUI ====================

ShowSettings:
	; Suspend hotkeys while GUI is open
	Suspend, On

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
	Gui, Settings:Add, Text, x20 y80, Hotkey:
	Gui, Settings:Add, Hotkey, x80 y77 w150 vHkMainHotkey, %MainHotkey%
	if (DarkMode = 1)
		Gui, Settings:Add, Text, x240 y80 cGray, (Cycles windows of same process)
	else
		Gui, Settings:Add, Text, x240 y80 cGray, (Cycles windows of same process)
	Gui, Settings:Add, Checkbox, x20 y110 vChkMoveMouse Checked%MoveMouse%, Move mouse to center of window when switching

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

	; Save main settings
	IniWrite, %ChkMainHotkeyEnabled%, %IniFile%, Settings, MainHotkeyEnabled
	IniWrite, %HkMainHotkey%, %IniFile%, Settings, MainHotkey
	IniWrite, %ChkMoveMouse%, %IniFile%, Settings, MoveMouse
	IniWrite, %RadioDarkMode%, %IniFile%, Settings, DarkMode

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

; ==================== Tool Edit Dialog ====================

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

ShowToolDialog:
	Gui, ToolDialog:Destroy
	Gui, ToolDialog:New, +OwnerSettings, % (EditingToolIndex = 0 ? "Add Tool" : "Edit Tool")
	Gui, ToolDialog:+OwnerSettings

	; Apply theme colors and font BEFORE adding controls
	if (DarkMode = 1)
	{
		Gui, ToolDialog:Color, 0x1E1E1E, 0x2D2D2D
		Gui, ToolDialog:Font, cSilver
	}
	else
	{
		Gui, ToolDialog:Font, cBlack
	}

	; Get existing values if editing
	if (EditingToolIndex > 0 && EditingToolIndex <= Tools.Length())
	{
		editTool := Tools[EditingToolIndex]
		tdName := editTool.Name
		tdHotkey := editTool.Hotkey
		tdExeName := editTool.ExeName
		tdExePath := editTool.ExePath
		tdWindowTitle := editTool.WindowTitle
		tdArguments := editTool.Arguments
		tdExcludeTitle := editTool.ExcludeTitle
	}
	else
	{
		tdName := ""
		tdHotkey := ""
		tdExeName := ""
		tdExePath := ""
		tdWindowTitle := ""
		tdArguments := ""
		tdExcludeTitle := ""
	}

	Gui, ToolDialog:Add, Text, x10 y15 w80, Name:
	Gui, ToolDialog:Add, Edit, x100 y12 w250 vTdName, %tdName%

	Gui, ToolDialog:Add, Text, x10 y45 w80, Hotkey:
	Gui, ToolDialog:Add, Hotkey, x100 y42 w150 vTdHotkey, %tdHotkey%

	Gui, ToolDialog:Add, Text, x10 y75 w80, Exe Name:
	Gui, ToolDialog:Add, Edit, x100 y72 w250 vTdExeName, %tdExeName%

	Gui, ToolDialog:Add, Text, x10 y105 w80, Exe Path:
	Gui, ToolDialog:Add, Edit, x100 y102 w220 vTdExePath, %tdExePath%
	Gui, ToolDialog:Add, Button, x325 y101 w25 gBrowseExePath, ...

	Gui, ToolDialog:Add, Text, x10 y135 w80, Window Title:
	Gui, ToolDialog:Add, Edit, x100 y132 w250 vTdWindowTitle, %tdWindowTitle%
	Gui, ToolDialog:Add, Text, x10 y155 cGray, (optional, for matching by title)

	Gui, ToolDialog:Add, Text, x10 y180 w80, Arguments:
	Gui, ToolDialog:Add, Edit, x100 y177 w250 vTdArguments, %tdArguments%

	Gui, ToolDialog:Add, Text, x10 y210 w80, Exclude Title:
	Gui, ToolDialog:Add, Edit, x100 y207 w250 vTdExcludeTitle, %tdExcludeTitle%
	Gui, ToolDialog:Add, Text, x10 y230 cGray, (windows containing this text are ignored)

	Gui, ToolDialog:Add, Button, x190 y260 w80 gToolDialogSave Default, Save
	Gui, ToolDialog:Add, Button, x280 y260 w80 gToolDialogClose, Cancel

	Gui, ToolDialog:Show, w360 h300

	; Apply dark title bar after showing
	if (DarkMode = 1)
	{
		Gui, ToolDialog:+LastFound
		toolDialogHwnd := WinExist()
		ApplyDarkMode(toolDialogHwnd)
	}
return

BrowseExePath:
	FileSelectFile, selectedFile, 3, , Select Executable, Executables (*.exe)
	if (selectedFile != "")
	{
		GuiControl, ToolDialog:, TdExePath, %selectedFile%
		; Auto-fill exe name if empty
		GuiControlGet, currentExeName, ToolDialog:, TdExeName
		if (currentExeName = "")
		{
			SplitPath, selectedFile, fileName
			GuiControl, ToolDialog:, TdExeName, %fileName%
		}
	}
return

ToolDialogSave:
	Gui, ToolDialog:Submit

	; Validate required fields
	if (TdName = "" || TdExeName = "" || TdExePath = "")
	{
		MsgBox, 48, Tool Switcher, Name, Exe Name, and Exe Path are required.
		return
	}

	; Create tool object
	newTool := {}
	newTool.Name := TdName
	newTool.Hotkey := TdHotkey
	newTool.ExeName := TdExeName
	newTool.ExePath := TdExePath
	newTool.WindowTitle := TdWindowTitle
	newTool.Arguments := TdArguments
	newTool.ExcludeTitle := TdExcludeTitle

	Gui, Settings:Default
	Gui, ListView, ToolListView

	if (EditingToolIndex = 0)
	{
		; Adding new tool
		LV_Add("", TdName, TdHotkey, TdExeName, TdExePath)
		Tools.Push(newTool)
	}
	else
	{
		; Editing existing tool
		LV_Modify(EditingToolIndex, "", TdName, TdHotkey, TdExeName, TdExePath)
		Tools[EditingToolIndex] := newTool
	}

	Gui, ToolDialog:Destroy
return

ToolDialogClose:
ToolDialogEscape:
	Gui, ToolDialog:Destroy
return

; ==================== End Settings GUI ====================

Reload:
	Reload
return

Exit:
	ExitApp
return

if(!A_IsCompiled) {
	#y::
		Send ^s
		reload
	return
}
