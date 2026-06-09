@echo off
setlocal
cd /d "%~dp0"
if "%1"=="chat" (
  bin\VindexLLMTest.exe --chat
) else (
  bin\VindexLLMTest.exe
)
pause
