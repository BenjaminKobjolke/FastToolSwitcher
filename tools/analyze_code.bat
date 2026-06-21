@echo off
d:
cd "D:\GIT\BenjaminKobjolke\cli-code-analyzer"

call venv\Scripts\python.exe main.py --language autohotkey --path "D:\GIT\BenjaminKobjolke\FastTools\FastToolSwitcher" --verbosity minimal --output "D:\GIT\BenjaminKobjolke\FastTools\FastToolSwitcher\code_analysis_results" --maxamountoferrors 50 --rules "D:\GIT\BenjaminKobjolke\FastTools\FastToolSwitcher\code_analysis_rules.json"

cd %~dp0..
