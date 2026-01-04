; ==================== Config.ahk ====================
; Configuration loading, saving, and global variables

; Global variables
global IniFile := ""
global Tools := []
global MainHotkeyEnabled := 1
global MainHotkey := "^+Space"
global MoveMouse := 1
global DarkMode := 1
global MouseMoveSpeed := 0
global StartWithWindows := 0
global IconPath := ""
global ShowGuiOnStart := false
global EditingToolIndex := 0

InitConfig() {
	global

	; Get script name without extension for INI file
	SplitPath, A_ScriptName,, , , ScriptNameNoExt
	IniFile := A_ScriptDir . "\" . ScriptNameNoExt . ".ini"

	; Read main settings from INI (use temp var, then assign to globals)
	IniRead, tmp, %IniFile%, Settings, MainHotkeyEnabled, 1
	MainHotkeyEnabled := tmp
	IniRead, tmp, %IniFile%, Settings, MainHotkey, ^+Space
	MainHotkey := tmp
	IniRead, tmp, %IniFile%, Settings, MoveMouse, 1
	MoveMouse := tmp
	IniRead, tmp, %IniFile%, Settings, DarkMode, 1
	DarkMode := tmp
	IniRead, tmp, %IniFile%, Settings, MouseMoveSpeed, 0
	MouseMoveSpeed := tmp
	IniRead, tmp, %IniFile%, Settings, StartWithWindows, 0
	StartWithWindows := tmp

	; Set icon path based on theme (use opposite for visibility)
	if (DarkMode = 1)
		IconPath := A_ScriptDir . "\data\icon_light.ico"
	else
		IconPath := A_ScriptDir . "\data\icon_dark.ico"

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

		; Skip tools with empty ExeName (invalid/missing tool definition)
		if (ToolExeName = "")
			continue

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
	global Tools, MainHotkeyEnabled, MainHotkey

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
}
