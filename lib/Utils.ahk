; ==================== Utils.ahk ====================
; Dark Mode Helper Functions

ApplyDarkMode(hwnd) {
	; Dark title bar (Windows 10 1809+)
	DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", 20, "Int*", 1, "Int", 4)
}

ApplyDarkListView(hwndLV) {
	; Apply dark theme to ListView
	DllCall("uxtheme\SetWindowTheme", "Ptr", hwndLV, "Str", "DarkMode_Explorer", "Ptr", 0)
}
