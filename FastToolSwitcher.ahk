#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance force
#Persistent ;Script nicht beenden nach der Auto-Execution-Section

SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2

; Include ONLY files with functions (no labels) before auto-execute section
#Include lib/Utils.ahk
#Include lib/Config.ahk

; Initialize configuration
InitConfig()
LoadTools()
SearchMissingExePaths()
RegisterHotkeys()

; Setup system tray menu
Menu, Tray, NoStandard
Menu, Tray, Add, Settings, ShowSettings
Menu, Tray, Add  ; Separator
Menu, Tray, Add, More tools, OpenMoreTools
if (!A_IsCompiled) {
	Menu, Tray, Add  ; Separator
	Menu, Tray, Add, Reload
}
Menu, Tray, Add  ; Separator
Menu, Tray, Add, Exit
Menu, Tray, Icon, %IconPath%

; Show GUI on start if command line arg was passed
if (ShowGuiOnStart)
	Gosub, ShowSettings

return  ; End of auto-execute section

; ==================== System Handlers ====================

Reload:
	Reload
return

Exit:
	ExitApp
return

; Include files with LABELS after auto-execute section
#Include lib/HotkeyCapture.ahk
#Include lib/WindowManager.ahk
#Include lib/SettingsGUI.ahk
#Include lib/ToolDialog.ahk
#Include lib/TargetPicker.ahk

; Debug hotkey (only when not compiled)
#If !A_IsCompiled
#y::
	Send ^s
	reload
return
#If
