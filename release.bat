@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: Check if src folder exists
if not exist "src" (
    echo Error: src folder not found
    pause
    exit /b 1
)

:: Check if pfExtend.toc file exists
if not exist "src\pfExtend.toc" (
    echo Error: src\pfExtend.toc file not found
    pause
    exit /b 1
)

:: Read version number from pfExtend.toc - specifically match ## Version:
set "version="
for /f "tokens=3" %%a in ('findstr /R /C:"^## Version:" "src\pfExtend.toc"') do (
    set "version=%%a"
    goto :version_found
)

:version_found
:: Check if version was successfully retrieved
if not defined version (
    echo Error: Failed to read version number from src\pfExtend.toc
    pause
    exit /b 1
)

echo Detected version: %version%

:: Set zip filename
set "zipname=pfExtend_%version%.zip"

:: Delete existing zip file if present
if exist "%zipname%" (
    echo Removing existing %zipname%
    del "%zipname%"
)

:: Create temporary folder for root directory renaming
set "tempdir=%TEMP%\pfExtend_release_%RANDOM%"
mkdir "%tempdir%"
xcopy /E /I /Q "src" "%tempdir%\pfExtend" >nul

:: Create zip archive using PowerShell
echo Creating archive %zipname% ...
powershell -NoProfile -Command "Compress-Archive -Path '%tempdir%\pfExtend' -DestinationPath '%zipname%' -Force"

:: Clean up temporary folder
rmdir /S /Q "%tempdir%"

:: Check result
if exist "%zipname%" (
    echo Successfully created archive: %zipname%
) else (
    echo Error: Failed to create archive
    pause
    exit /b 1
)

pause