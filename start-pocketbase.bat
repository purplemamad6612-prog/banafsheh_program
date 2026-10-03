@echo off
setlocal
cd /d "%~dp0"
if not exist "pocketbase.exe" (
  echo PocketBase executable not found.
  echo Download the Windows release and place pocketbase.exe beside this file.
  pause
  exit /b 1
)
echo Starting PocketBase on http://127.0.0.1:8090
"%~dp0pocketbase.exe" serve --http=127.0.0.1:8090
pause
