; ==================== HotkeyPreview.ahk ====================
; Shortcuts overview overlay window

global HotkeyPreviewVisible := 0

FormatHotkeyDisplay(hotkeyStr) {
	if (hotkeyStr = "")
		return ""

	parsed := ParseHotkey(hotkeyStr)
	display := ""

	if (parsed.ctrl)
		display .= "Ctrl + "
	if (parsed.shift)
		display .= "Shift + "
	if (parsed.alt)
		display .= "Alt + "
	if (parsed.win)
		display .= "Win + "

	; Capitalize first letter of key
	key := parsed.key
	if (StrLen(key) = 1)
	{
		StringUpper, key, key
		display .= key
	}
	else
		display .= key

	return display
}

ToggleHotkeyPreview:
	if (HotkeyPreviewVisible)
	{
		Gui, HotkeyPreview:Destroy
		HotkeyPreviewVisible := 0
		Hotkey, Escape, HotkeyPreviewClose, Off
		return
	}

	; Build list of tools with hotkeys
	toolsWithHotkeys := []
	for index, tool in Tools
	{
		if (tool.Hotkey != "")
		{
			entry := {}
			entry.Name := tool.Name != "" ? tool.Name : tool.ExeName
			entry.HotkeyDisplay := FormatHotkeyDisplay(tool.Hotkey)
			toolsWithHotkeys.Push(entry)
		}
	}

	if (toolsWithHotkeys.Length() = 0)
	{
		ToolTip, No tools with hotkeys configured
		SetTimer, RemoveToolTip, -2000
		return
	}

	; Create overlay GUI
	Gui, HotkeyPreview:New, -Caption +AlwaysOnTop +ToolWindow +Border +E0x08000000

	if (DarkMode = 1)
	{
		bgColor := "0x1E1E1E"
		textColor := "cWhite"
		hintColor := "cGray"
		hotkeyColor := "c58A6FF"
		borderColor := "0x444444"
		Gui, HotkeyPreview:Color, %bgColor%
	}
	else
	{
		bgColor := "0xF5F5F5"
		textColor := "cBlack"
		hintColor := "cGray"
		hotkeyColor := "c0055AA"
		borderColor := "0xCCCCCC"
		Gui, HotkeyPreview:Color, %bgColor%
	}

	; Calculate dimensions
	rowHeight := 32
	padding := 20
	titleHeight := 45
	footerHeight := 50
	colNameWidth := 200
	colHotkeyWidth := 200
	totalWidth := colNameWidth + colHotkeyWidth + padding * 3
	totalHeight := titleHeight + (toolsWithHotkeys.Length() * rowHeight) + footerHeight + padding * 2

	; Title
	Gui, HotkeyPreview:Font, s14 Bold %textColor%, Segoe UI
	Gui, HotkeyPreview:Add, Text, x%padding% y%padding% w%totalWidth%, Shortcuts Overview

	; Tool rows
	yPos := padding + titleHeight
	for index, entry in toolsWithHotkeys
	{
		; Tool name
		Gui, HotkeyPreview:Font, s11 Normal %textColor%, Segoe UI
		xName := padding
		Gui, HotkeyPreview:Add, Text, x%xName% y%yPos% w%colNameWidth% h%rowHeight% +0x200, % entry.Name

		; Hotkey display
		Gui, HotkeyPreview:Font, s11 Normal %hotkeyColor%, Consolas
		xHotkey := padding + colNameWidth + padding
		Gui, HotkeyPreview:Add, Text, x%xHotkey% y%yPos% w%colHotkeyWidth% h%rowHeight% +0x200, % entry.HotkeyDisplay

		yPos += rowHeight
	}

	; Footer hint
	yPos += 20
	Gui, HotkeyPreview:Font, s9 Normal %hintColor%, Segoe UI
	Gui, HotkeyPreview:Add, Text, x0 y%yPos% w%totalWidth% Center, Press hotkey again or Escape to close

	; Center on screen
	SysGet, MonW, 78
	SysGet, MonH, 79
	xPos := (MonW - totalWidth) // 2
	yPos_win := (MonH - totalHeight) // 2

	Gui, HotkeyPreview:Show, x%xPos% y%yPos_win% w%totalWidth% h%totalHeight% NoActivate

	; Apply dark title bar if dark mode
	if (DarkMode = 1)
	{
		Gui, HotkeyPreview:+LastFound
		previewHwnd := WinExist()
		ApplyDarkMode(previewHwnd)
	}

	HotkeyPreviewVisible := 1

	; Register Escape to close
	Hotkey, Escape, HotkeyPreviewClose, On
return

HotkeyPreviewClose:
	Gui, HotkeyPreview:Destroy
	HotkeyPreviewVisible := 0
	Hotkey, Escape, HotkeyPreviewClose, Off
return

RemoveToolTip:
	ToolTip
return
