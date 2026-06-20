; ==================== ToolDialog.ahk ====================
; Add/Edit tool dialog

ShowToolDialog:
	Gui, ToolDialog:Destroy
	Gui, ToolDialog:New, +OwnerSettings, % (EditingToolIndex = 0 ? "Add Tool" : "Edit Tool")
	Gui, ToolDialog:+OwnerSettings

	; Apply theme colors and font BEFORE adding controls
	if (DarkMode = 1)
	{
		Gui, ToolDialog:Color, 0x1E1E1E, 0x2D2D2D
		Gui, ToolDialog:Font, s12 cWhite
	}
	else
	{
		Gui, ToolDialog:Font, s12 cBlack
	}

	; Reset picked window class (will be set by Pick Window button)
	PickedWindowClass := ""

	; Get existing values if editing
	if (EditingToolIndex > 0 && EditingToolIndex <= Tools.Length())
	{
		editTool := Tools[EditingToolIndex]
		tdName := editTool.Name
		tdHotkey := editTool.Hotkey
		tdExeName := editTool.ExeName
		tdExePath := editTool.ExePath
		tdWindowTitle := editTool.WindowTitle
		tdWindowClass := editTool.WindowClass
		tdArguments := editTool.Arguments
		tdExcludeTitle := editTool.ExcludeTitle
		tdSendToBackground := editTool.SendToBackground
	}
	else
	{
		tdName := ""
		tdHotkey := ""
		tdExeName := ""
		tdExePath := ""
		tdWindowTitle := ""
		tdWindowClass := ""
		tdArguments := ""
		tdExcludeTitle := ""
		tdSendToBackground := 0
	}

	Gui, ToolDialog:Add, Text, x15 y20 w100, Name:
	Gui, ToolDialog:Add, Edit, x120 y17 w300 vTdName, %tdName%

	; Hotkey(s) via the shared list row + popup editor (multiple hotkeys allowed)
	Gui, ToolDialog:Add, Text, x15 y45 w100, Hotkey(s):
	AddHotkeyListRow("ToolDialog", "Td", 65, tdHotkey, 0, "", 0)

	Gui, ToolDialog:Add, Text, x15 y155 w100, Exe Name:
	Gui, ToolDialog:Add, Edit, x120 y152 w300 vTdExeName, %tdExeName%

	Gui, ToolDialog:Add, Text, x15 y195 w100, Exe Path:
	Gui, ToolDialog:Add, Edit, x120 y192 w260 vTdExePath, %tdExePath%
	Gui, ToolDialog:Add, Button, x385 y191 w35 gBrowseExePath, ...

	Gui, ToolDialog:Add, Text, x15 y235 w100, Window Title:
	Gui, ToolDialog:Add, Edit, x120 y232 w300 vTdWindowTitle, %tdWindowTitle%
	if (DarkMode = 1)
		Gui, ToolDialog:Add, Text, x15 y265 cWhite, (optional, for matching by title)
	else
		Gui, ToolDialog:Add, Text, x15 y265 cGray, (optional, for matching by title)

	Gui, ToolDialog:Add, Text, x15 y300 w100, Arguments:
	Gui, ToolDialog:Add, Edit, x120 y297 w300 vTdArguments, %tdArguments%

	Gui, ToolDialog:Add, Text, x15 y340 w100, Exclude Title:
	Gui, ToolDialog:Add, Edit, x120 y337 w300 vTdExcludeTitle, %tdExcludeTitle%
	if (DarkMode = 1)
		Gui, ToolDialog:Add, Text, x15 y370 cWhite, (windows containing this text are ignored)
	else
		Gui, ToolDialog:Add, Text, x15 y370 cGray, (windows containing this text are ignored)

	; Send to background option
	Gui, ToolDialog:Add, Checkbox, x15 y405 vChkSendToBackground Checked%tdSendToBackground%, Send to background when already focused

	; Pick Window button
	Gui, ToolDialog:Add, Button, x120 y445 w120 gStartTargetPicker, Pick Window

	Gui, ToolDialog:Add, Button, x240 y495 w90 gToolDialogSave Default, Save
	Gui, ToolDialog:Add, Button, x340 y495 w90 gToolDialogClose, Cancel

	Gui, ToolDialog:Show, w520 h545

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

	; Hotkey list comes from the shared list field (already "|"-joined)
	builtToolHotkey := TdList

	; Check each hotkey in the list for a duplicate assignment
	for i, hk in SplitHotkeyList(builtToolHotkey)
	{
		conflict := FindHotkeyConflict(hk, EditingToolIndex)
		if (conflict != "")
		{
			MsgBox, 48, Tool Switcher, Hotkey %hk% is already assigned to %conflict%.`n`nPlease choose a different hotkey.
			return
		}
	}

	; Determine WindowClass: use PickedWindowClass if set (from Pick Window), else preserve existing
	if (PickedWindowClass != "")
		finalWindowClass := PickedWindowClass
	else
		finalWindowClass := tdWindowClass

	; Create tool object
	newTool := {}
	newTool.Name := TdName
	newTool.Hotkey := builtToolHotkey
	newTool.ExeName := TdExeName
	newTool.ExePath := TdExePath
	newTool.WindowTitle := TdWindowTitle
	newTool.WindowClass := finalWindowClass
	newTool.Arguments := TdArguments
	newTool.ExcludeTitle := TdExcludeTitle
	newTool.SendToBackground := ChkSendToBackground

	Gui, Settings:Default
	Gui, ListView, ToolListView

	if (EditingToolIndex = 0)
	{
		; Adding new tool
		LV_Add("", TdName, builtToolHotkey, TdExeName, TdExePath)
		Tools.Push(newTool)
	}
	else
	{
		; Editing existing tool
		LV_Modify(EditingToolIndex, "", TdName, builtToolHotkey, TdExeName, TdExePath)
		Tools[EditingToolIndex] := newTool
	}

	Gui, ToolDialog:Destroy
return

ToolDialogClose:
ToolDialogEscape:
	Gui, ToolDialog:Destroy
return
