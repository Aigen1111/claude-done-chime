:<<'__CMDBLOCK__'
@echo off
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0play-agy.ps1" %*
exit /b %errorlevel%
__CMDBLOCK__
exec bash "$(dirname "$0")/play-agy.sh" "$@"
