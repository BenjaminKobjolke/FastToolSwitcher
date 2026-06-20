; ==================== Config.ahk ====================
; Configuration loading, saving, and global variables

; Global variables
global IniFile := ""
global Tools := []
global MainHotkeyEnabled := 0
global MainHotkey := ""
global MainHotkeyReversedEnabled := 0
global MainHotkeyReversed := ""
global OverviewHotkeyEnabled := 0
global OverviewHotkey := ""
global IgnoreHotkeyEnabled := 0
global IgnoreHotkey := ""
global IgnoredWindows := {}                          ; HWND -> 1, session only
global IGNORED_SUFFIX := " - FastToolSwitcher - ignored"
global IGNORED_STATE_FILE := A_Temp . "\FastToolSwitcher_ignored.txt"  ; reload handoff only
global MoveMouse := 1
global DarkMode := 1
global MouseMoveSpeed := 0
global StartWithWindows := 0
global IconPath := ""
global IconIndex := 0
global ShowGuiOnStart := false
global EditingToolIndex := 0

InitConfig() {
	global

	; Get script name without extension for INI file
	SplitPath, A_ScriptName,, , , ScriptNameNoExt
	IniFile := A_ScriptDir . "\" . ScriptNameNoExt . ".ini"
	ExampleIniFile := A_ScriptDir . "\" . ScriptNameNoExt . ".example.ini"

	if (!FileExist(IniFile) && FileExist(ExampleIniFile))
		FileCopy, %ExampleIniFile%, %IniFile%

	; Read main settings from INI (use temp var, then assign to globals)
	IniRead, tmp, %IniFile%, Settings, MainHotkeyEnabled, 0
	MainHotkeyEnabled := tmp
	IniRead, tmp, %IniFile%, Settings, MainHotkey, %A_Space%
	MainHotkey := tmp
	IniRead, tmp, %IniFile%, Settings, MainHotkeyReversedEnabled, 0
	MainHotkeyReversedEnabled := tmp
	IniRead, tmp, %IniFile%, Settings, MainHotkeyReversed, %A_Space%
	MainHotkeyReversed := tmp
	IniRead, tmp, %IniFile%, Settings, OverviewHotkeyEnabled, 0
	OverviewHotkeyEnabled := tmp
	IniRead, tmp, %IniFile%, Settings, OverviewHotkey, %A_Space%
	OverviewHotkey := tmp
	IniRead, tmp, %IniFile%, Settings, IgnoreHotkeyEnabled, 1
	IgnoreHotkeyEnabled := tmp
	IniRead, tmp, %IniFile%, Settings, IgnoreHotkey, ^!i
	IgnoreHotkey := tmp
	IniRead, tmp, %IniFile%, Settings, MoveMouse, 1
	MoveMouse := tmp
	IniRead, tmp, %IniFile%, Settings, DarkMode, 1
	DarkMode := tmp
	IniRead, tmp, %IniFile%, Settings, MouseMoveSpeed, 0
	MouseMoveSpeed := tmp
	IniRead, tmp, %IniFile%, Settings, StartWithWindows, 0
	StartWithWindows := tmp

	; Set icon path based on theme (use opposite for visibility)
	; When compiled, load main icon from exe; otherwise use data folder
	if (A_IsCompiled)
	{
		; Use the exe's embedded main icon (light icon)
		IconPath := A_ScriptFullPath
		IconIndex := 1
	}
	else
	{
		IconDir := A_ScriptDir . "\data"
		if (DarkMode = 1)
			IconPath := IconDir . "\icon_light.ico"
		else
			IconPath := IconDir . "\icon_dark.ico"
		IconIndex := 0
	}

	; Check for command line arguments
	ShowGuiOnStart := false
	for n, arg in A_Args
	{
		if (arg = "--gui" || arg = "-g")
			ShowGuiOnStart := true
	}
}

LoadTools() {
	global Tools, IniFile

	; Read tool count from INI
	IniRead, ToolCount, %IniFile%, Tools, ToolCount, 0

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
		IniRead, ToolWindowClass, %IniFile%, %ToolSection%, WindowClass, %A_Space%
		IniRead, ToolExePath, %IniFile%, %ToolSection%, ExePath, %A_Space%
		IniRead, ToolArguments, %IniFile%, %ToolSection%, Arguments, %A_Space%
		IniRead, ToolExcludeTitle, %IniFile%, %ToolSection%, ExcludeTitle, %A_Space%
		IniRead, ToolSendToBackground, %IniFile%, %ToolSection%, SendToBackground, 0

		; Skip tools with empty ExeName (invalid/missing tool definition)
		if (ToolExeName = "")
			continue

		; Store tool info
		Tool := {}
		Tool.Name := ToolName
		Tool.Hotkey := ToolHotkey
		Tool.ExeName := ToolExeName
		Tool.WindowTitle := ToolWindowTitle
		Tool.WindowClass := ToolWindowClass
		Tool.ExePath := ToolExePath
		Tool.Arguments := ToolArguments
		Tool.ExcludeTitle := ToolExcludeTitle
		Tool.SendToBackground := ToolSendToBackground
		Tool.Section := ToolSection

		Tools.Push(Tool)
	}
}

SearchMissingExePaths() {
	global Tools, IniFile

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
}

RegisterHotkeys() {
	global Tools, MainHotkeyEnabled, MainHotkey, MainHotkeyReversedEnabled, MainHotkeyReversed, OverviewHotkeyEnabled, OverviewHotkey, IgnoreHotkeyEnabled, IgnoreHotkey

	; Startup duplicate detection - warn about duplicate hotkeys in config
	; (each value may be a "|"-joined list of hotkeys)
	dupPairs := []
	for index, tool in Tools
	{
		if (tool.Hotkey != "")
			dupPairs.Push({list: tool.Hotkey, owner: (tool.Name != "" ? tool.Name : tool.ExeName)})
	}
	if (MainHotkeyEnabled = 1 && MainHotkey != "")
		dupPairs.Push({list: MainHotkey, owner: "Window Cycling"})
	if (MainHotkeyReversedEnabled = 1 && MainHotkeyReversed != "")
		dupPairs.Push({list: MainHotkeyReversed, owner: "Window Cycling (Reverse)"})
	if (OverviewHotkeyEnabled = 1 && OverviewHotkey != "")
		dupPairs.Push({list: OverviewHotkey, owner: "Shortcuts Overview"})
	if (IgnoreHotkeyEnabled = 1 && IgnoreHotkey != "")
		dupPairs.Push({list: IgnoreHotkey, owner: "Ignore Window"})
	duplicateWarnings := CollectHotkeyDuplicates(dupPairs)
	if (duplicateWarnings != "")
	{
		MsgBox, 48, Tool Switcher - Duplicate Hotkeys, The following hotkey conflicts were detected:`n`n%duplicateWarnings%`nOnly one assignment per hotkey will work. Please fix this in Settings.
	}

	; Create hotkeys dynamically (each value may hold multiple hotkeys)
	for index, tool in Tools
	{
		if (tool.Hotkey != "" && tool.ExePath != "")
		{
			RegisterHotkeyList(tool.Hotkey, "HandleToolHotkey")
		}
	}

	; Create main window cycling hotkey if enabled
	if (MainHotkeyEnabled = 1 && MainHotkey != "")
	{
		RegisterHotkeyList(MainHotkey, "MainWindowCycleHotkey")
	}

	; Create reverse window cycling hotkey if enabled
	if (MainHotkeyReversedEnabled = 1 && MainHotkeyReversed != "")
	{
		RegisterHotkeyList(MainHotkeyReversed, "MainWindowCycleHotkeyReversed")
	}

	; Create overview hotkey if enabled
	if (OverviewHotkeyEnabled = 1 && OverviewHotkey != "")
	{
		RegisterHotkeyList(OverviewHotkey, "ToggleHotkeyPreview")
	}

	; Create ignore-window hotkey if enabled (feature off when disabled)
	if (IgnoreHotkeyEnabled = 1 && IgnoreHotkey != "")
	{
		RegisterHotkeyList(IgnoreHotkey, "ToggleIgnoreActiveWindow")
	}
}
