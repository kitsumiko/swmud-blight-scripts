@echo off
REM SWMud Blight Scripts Installer for Windows
REM This script installs the SWMud Blight Scripts to your Blightmud configuration directory

setlocal enabledelayedexpansion

REM Script directory (where this script is located)
set "SCRIPT_DIR=%~dp0"

echo.
echo ========================================
echo SWMud Blight Scripts Installer
echo ========================================
echo.

REM Check if running as administrator (optional, but helpful)
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] Running with administrator privileges
) else (
    echo [INFO] Running without administrator privileges (this is usually fine)
)
echo.

REM Function to find Blightmud config directory
set "CONFIG_DIR="

REM Try APPDATA first (most common)
if exist "%APPDATA%\blightmud" (
    set "CONFIG_DIR=%APPDATA%\blightmud"
    echo [INFO] Found Blightmud config directory: %CONFIG_DIR%
) else if exist "%LOCALAPPDATA%\blightmud" (
    set "CONFIG_DIR=%LOCALAPPDATA%\blightmud"
    echo [INFO] Found Blightmud config directory: %CONFIG_DIR%
) else (
    REM Default to APPDATA
    set "CONFIG_DIR=%APPDATA%\blightmud"
    echo [INFO] Blightmud config directory not found. Will create: %CONFIG_DIR%
)
echo.

REM Check if Blightmud is installed
where blightmud >nul 2>&1
if %errorLevel% == 0 (
    echo [SUCCESS] Blightmud is installed
    blightmud --version >nul 2>&1
    if !errorLevel! == 0 (
        for /f "tokens=*" %%i in ('blightmud --version 2^>^&1') do (
            echo [INFO] Blightmud version: %%i
            goto :version_done
        )
        :version_done
    )
) else (
    echo [WARNING] Blightmud command not found in PATH
    echo [INFO] This might be okay if Blightmud is installed but not in PATH
)
echo.

REM Create backup if installation exists
if exist "%CONFIG_DIR%\swmud" (
    echo [WARNING] Existing installation found. Creating backup...
    set "BACKUP_DIR=%CONFIG_DIR%.backup.%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
    set "BACKUP_DIR=!BACKUP_DIR: =0!"
    mkdir "!BACKUP_DIR!" 2>nul
    
    if exist "%CONFIG_DIR%\swmud" (
        xcopy /E /I /Y "%CONFIG_DIR%\swmud" "!BACKUP_DIR!\swmud\" >nul 2>&1
    )
    
    if exist "%CONFIG_DIR%\000_connect.lua" (
        copy /Y "%CONFIG_DIR%\000_connect.lua" "!BACKUP_DIR!\" >nul 2>&1
    )
    
    echo [SUCCESS] Backup created at: !BACKUP_DIR!
    echo.
)

REM Create config directory if it doesn't exist
if not exist "%CONFIG_DIR%" (
    echo [INFO] Creating config directory...
    mkdir "%CONFIG_DIR%"
    if !errorLevel! neq 0 (
        echo [ERROR] Failed to create config directory: %CONFIG_DIR%
        pause
        exit /b 1
    )
)

REM Copy swmud directory
if exist "%SCRIPT_DIR%swmud" (
    echo [INFO] Copying swmud directory...
    xcopy /E /I /Y "%SCRIPT_DIR%swmud" "%CONFIG_DIR%\swmud\" >nul
    if !errorLevel! == 0 (
        echo [SUCCESS] swmud directory copied
    ) else (
        echo [ERROR] Failed to copy swmud directory
        pause
        exit /b 1
    )
) else (
    echo [ERROR] swmud directory not found in %SCRIPT_DIR%
    pause
    exit /b 1
)

REM Copy 000_connect.lua
if exist "%SCRIPT_DIR%000_connect.lua" (
    echo [INFO] Copying 000_connect.lua...
    copy /Y "%SCRIPT_DIR%000_connect.lua" "%CONFIG_DIR%\" >nul
    if !errorLevel! == 0 (
        echo [SUCCESS] 000_connect.lua copied
    ) else (
        echo [ERROR] Failed to copy 000_connect.lua
        pause
        exit /b 1
    )
) else (
    echo [ERROR] 000_connect.lua not found in %SCRIPT_DIR%
    pause
    exit /b 1
)

REM Copy settings.ron if it exists (optional)
if exist "%SCRIPT_DIR%settings.ron" (
    if not exist "%CONFIG_DIR%\settings.ron" (
        echo [INFO] Copying settings.ron...
        copy /Y "%SCRIPT_DIR%settings.ron" "%CONFIG_DIR%\" >nul
        if !errorLevel! == 0 (
            echo [SUCCESS] settings.ron copied
        )
    ) else (
        echo [INFO] settings.ron already exists, skipping (to preserve your settings)
    )
)

REM Create private directory if it doesn't exist
if not exist "%CONFIG_DIR%\private" (
    echo [INFO] Creating private directory...
    mkdir "%CONFIG_DIR%\private"
)

echo.

REM Verify installation
echo [INFO] Verifying installation...
set "ERRORS=0"

if not exist "%CONFIG_DIR%\000_connect.lua" (
    echo [ERROR] 000_connect.lua not found
    set /a ERRORS+=1
)

if not exist "%CONFIG_DIR%\swmud" (
    echo [ERROR] swmud directory not found
    set /a ERRORS+=1
)

REM Check for required subdirectories
set "REQUIRED_DIRS=core utils ui commands parsers services models data"
for %%d in (%REQUIRED_DIRS%) do (
    if not exist "%CONFIG_DIR%\swmud\%%d" (
        echo [ERROR] swmud\%%d directory not found
        set /a ERRORS+=1
    )
)

if %ERRORS% == 0 (
    echo [SUCCESS] Installation verified successfully!
    echo.
    echo [SUCCESS] Installation completed successfully!
    echo.
    echo [INFO] Next steps:
    echo   1. Launch Blightmud: blightmud
    echo   2. The scripts will automatically load when you connect to SWMud
    echo   3. Use '/reload' in-game to reload scripts after making changes
    echo.
    echo [INFO] Config directory: %CONFIG_DIR%
    echo [INFO] For character-specific scripts, create: %CONFIG_DIR%\private\020_character.lua
    echo.
) else (
    echo [ERROR] Installation verification failed with %ERRORS% error(s)
    pause
    exit /b 1
)

pause

