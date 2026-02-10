# Tools Directory

## Running Batch Files (.bat)

Claude Code runs in a bash shell and cannot execute `.bat` files directly. Use PowerShell:

```bash
powershell -Command "cd 'D:\GIT\BenjaminKobjolke\FastTools\FastToolSwitcher\tools'; cmd /c '.\script.bat'"
```

For long-running scripts, set a timeout (up to 600000ms / 10 minutes):

```bash
# timeout: 300000
powershell -Command "cd 'D:\GIT\BenjaminKobjolke\FastTools\FastToolSwitcher\tools'; cmd /c '.\publish_release.bat'"
```

## Available Scripts

| Script | Description |
|--------|-------------|
| `build.bat` | Compile `FastToolSwitcher.ahk` into `FastToolSwitcher.exe` |
| `increment_version.bat` | Increment patch version in `version.txt` (e.g., 1.0.0 -> 1.0.1) |
| `decrement_version.bat` | Decrement patch version in `version.txt` |
| `get_version.bat` | Display current version from `version.txt` |
| `translator_release_notes.bat` | Translate `en.json` release notes to all supported languages |
| `publish_release.bat` | Sign exe, upload to FTP, upload release notes |

## PowerShell Scripts

If a `.bat` wrapper doesn't work, run the `.ps1` directly:

```bash
powershell -ExecutionPolicy Bypass -File "D:\GIT\BenjaminKobjolke\FastTools\FastToolSwitcher\tools\increment_version.ps1"
```
