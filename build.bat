@echo off
setlocal

set "AHK_COMPILER=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set "SCRIPT_NAME=FastToolSwitcher"
set "ICON_PATH=%~dp0data\icon_light.ico"

echo Building %SCRIPT_NAME%.exe...

if not exist "%AHK_COMPILER%" (
    echo Error: AutoHotkey compiler not found at:
    echo %AHK_COMPILER%
    echo.
    echo Please install AutoHotkey or update the path in this script.
    pause
    exit /b 1
)

"%AHK_COMPILER%" /in "%~dp0%SCRIPT_NAME%.ahk" /out "%~dp0%SCRIPT_NAME%.exe" /icon "%ICON_PATH%"

if %errorlevel% equ 0 (
    echo.
    echo Build successful: %SCRIPT_NAME%.exe
) else (
    echo.
    echo Build failed with error code: %errorlevel%
)

pause
