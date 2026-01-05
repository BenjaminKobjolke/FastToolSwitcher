; ==================== WindowManager.ahk ====================
; Window cycling and hotkey handlers

HandleToolHotkey:
	; Find which tool triggered this hotkey
	triggeredHotkey := A_ThisHotkey

	for index, tool in Tools
	{
		if (tool.Hotkey = triggeredHotkey)
		{
			; Determine window detection method (priority: WindowClass > WindowTitle > ExeName)
			if (tool.WindowClass != "")
			{
				; Use window class (for special cases like File Explorer)
				windowSpec := "ahk_class " . tool.WindowClass
			}
			else if (tool.WindowTitle != "")
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
							MouseMove, winX + winW // 2, winY + winH // 2, %MouseMoveSpeed%
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
						MouseMove, winX + winW // 2, winY + winH // 2, %MouseMoveSpeed%
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
		MouseMove, winX + winW // 2, winY + winH // 2, %MouseMoveSpeed%
	}
return
