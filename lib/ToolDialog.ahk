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

	; Parse current hotkey into components
	parsedTdHk := ParseHotkey(tdHotkey)
	tdCtrl := parsedTdHk.ctrl
	tdShift := parsedTdHk.shift
	tdAlt := parsedTdHk.alt
	tdWin := parsedTdHk.win
	tdKeyVal := parsedTdHk.key

	Gui, ToolDialog:Add, Text, x10 y45 w80, Hotkey:
	Gui, ToolDialog:Add, Checkbox, x100 y45 vChkTdCtrl Checked%tdCtrl%, Ctrl
	Gui, ToolDialog:Add, Checkbox, x150 y45 vChkTdShift Checked%tdShift%, Shift
	Gui, ToolDialog:Add, Checkbox, x205 y45 vChkTdAlt Checked%tdAlt%, Alt
	Gui, ToolDialog:Add, Checkbox, x250 y45 vChkTdWin Checked%tdWin%, Win
	Gui, ToolDialog:Add, Text, x100 y70, Key:
	Gui, ToolDialog:Add, Edit, x135 y67 w60 vTdKey ReadOnly, %tdKeyVal%
	Gui, ToolDialog:Add, Button, x200 y66 w35 gSetToolKey, Set

	Gui, ToolDialog:Add, Text, x10 y100 w80, Exe Name:
	Gui, ToolDialog:Add, Edit, x100 y97 w250 vTdExeName, %tdExeName%

	Gui, ToolDialog:Add, Text, x10 y130 w80, Exe Path:
	Gui, ToolDialog:Add, Edit, x100 y127 w220 vTdExePath, %tdExePath%
	Gui, ToolDialog:Add, Button, x325 y126 w25 gBrowseExePath, ...

	Gui, ToolDialog:Add, Text, x10 y160 w80, Window Title:
	Gui, ToolDialog:Add, Edit, x100 y157 w250 vTdWindowTitle, %tdWindowTitle%
	Gui, ToolDialog:Add, Text, x10 y180 cGray, (optional, for matching by title)

	Gui, ToolDialog:Add, Text, x10 y205 w80, Arguments:
	Gui, ToolDialog:Add, Edit, x100 y202 w250 vTdArguments, %tdArguments%

	Gui, ToolDialog:Add, Text, x10 y235 w80, Exclude Title:
	Gui, ToolDialog:Add, Edit, x100 y232 w250 vTdExcludeTitle, %tdExcludeTitle%
	Gui, ToolDialog:Add, Text, x10 y255 cGray, (windows containing this text are ignored)

	; Pick Window button
	Gui, ToolDialog:Add, Button, x100 y280 w100 gStartTargetPicker, Pick Window

	Gui, ToolDialog:Add, Button, x190 y320 w80 gToolDialogSave Default, Save
	Gui, ToolDialog:Add, Button, x280 y320 w80 gToolDialogClose, Cancel

	Gui, ToolDialog:Show, w360 h360

	; Apply dark title bar after showing
	if (DarkMode = 1)
	{
		Gui, ToolDialog:+LastFound
		toolDialogHwnd := WinExist()
		ApplyDarkMode(toolDialogHwnd)
	}
return

SetToolKey:
	; Capture single key when Set button is clicked
	CaptureKeyToControl("ToolDialog", "TdKey")
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

	; Build hotkey from checkboxes and key field
	builtToolHotkey := BuildHotkey(ChkTdCtrl, ChkTdShift, ChkTdAlt, ChkTdWin, TdKey)

	; Create tool object
	newTool := {}
	newTool.Name := TdName
	newTool.Hotkey := builtToolHotkey
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
