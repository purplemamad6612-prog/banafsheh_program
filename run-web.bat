@echo off
setlocal
cd /d "%~dp0"
where python >nul 2>nul
if errorlevel 1 (
  echo Python 3 is required to serve the PWA locally.
  pause
  exit /b 1
)
python -m http.server 4173 --bind 0.0.0.0
