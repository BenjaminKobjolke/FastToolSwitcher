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

	; Parse current hotkey into components
	parsedTdHk := ParseHotkey(tdHotkey)
	tdCtrl := parsedTdHk.ctrl
	tdShift := parsedTdHk.shift
	tdAlt := parsedTdHk.alt
	tdWin := parsedTdHk.win
	tdKeyVal := parsedTdHk.key

	Gui, ToolDialog:Add, Text, x15 y60 w100, Hotkey:
	Gui, ToolDialog:Add, Checkbox, x120 y60 vChkTdCtrl Checked%tdCtrl%, Ctrl
	Gui, ToolDialog:Add, Checkbox, x180 y60 vChkTdShift Checked%tdShift%, Shift
	Gui, ToolDialog:Add, Checkbox, x250 y60 vChkTdAlt Checked%tdAlt%, Alt
	Gui, ToolDialog:Add, Checkbox, x310 y60 vChkTdWin Checked%tdWin%, Win
	Gui, ToolDialog:Add, Text, x120 y95, Key:
	Gui, ToolDialog:Add, Edit, x165 y92 w70 vTdKey ReadOnly, %tdKeyVal%
	Gui, ToolDialog:Add, Button, x245 y91 w45 gSetToolKey, Set

	Gui, ToolDialog:Add, Text, x15 y135 w100, Exe Name:
	Gui, ToolDialog:Add, Edit, x120 y132 w300 vTdExeName, %tdExeName%

	Gui, ToolDialog:Add, Text, x15 y175 w100, Exe Path:
	Gui, ToolDialog:Add, Edit, x120 y172 w260 vTdExePath, %tdExePath%
	Gui, ToolDialog:Add, Button, x385 y171 w35 gBrowseExePath, ...

	Gui, ToolDialog:Add, Text, x15 y215 w100, Window Title:
	Gui, ToolDialog:Add, Edit, x120 y212 w300 vTdWindowTitle, %tdWindowTitle%
	if (DarkMode = 1)
		Gui, ToolDialog:Add, Text, x15 y245 cWhite, (optional, for matching by title)
	else
		Gui, ToolDialog:Add, Text, x15 y245 cGray, (optional, for matching by title)

	Gui, ToolDialog:Add, Text, x15 y280 w100, Arguments:
	Gui, ToolDialog:Add, Edit, x120 y277 w300 vTdArguments, %tdArguments%

	Gui, ToolDialog:Add, Text, x15 y320 w100, Exclude Title:
	Gui, ToolDialog:Add, Edit, x120 y317 w300 vTdExcludeTitle, %tdExcludeTitle%
	if (DarkMode = 1)
		Gui, ToolDialog:Add, Text, x15 y350 cWhite, (windows containing this text are ignored)
	else
		Gui, ToolDialog:Add, Text, x15 y350 cGray, (windows containing this text are ignored)

	; Send to background option
	Gui, ToolDialog:Add, Checkbox, x15 y385 vChkSendToBackground Checked%tdSendToBackground%, Send to background when already focused

	; Pick Window button
	Gui, ToolDialog:Add, Button, x120 y425 w120 gStartTargetPicker, Pick Window

	Gui, ToolDialog:Add, Button, x240 y475 w90 gToolDialogSave Default, Save
	Gui, ToolDialog:Add, Button, x340 y475 w90 gToolDialogClose, Cancel

	Gui, ToolDialog:Show, w440 h520

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
