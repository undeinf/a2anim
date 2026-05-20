@echo off
setlocal enabledelayedexpansion

:: --------------------------------------------------------
:: FORCE COMMAND PROMPT ONLY
:: --------------------------------------------------------
echo %CMDCMDLINE% | findstr /i "powershell.exe pwsh.exe" >nul
if %ERRORLEVEL%==0 (
    echo [WARNING] This script must run in Native Command Prompt (CMD), not PowerShell.
    echo Re-launching in a clean CMD window...
    pause
    start cmd.exe /c "%~dp0%~nx0"
    exit /b
)

:: --------------------------------------------------------
:: DYNAMIC NODE FOLDER DETECTION
:: --------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
set "NODE_BIN_DIR="

:: Scan immediate subdirectories for the portable node executable
for /d %%i in ("%SCRIPT_DIR%*") do (
    if exist "%%i\node.exe" (
        set "NODE_BIN_DIR=%%i"
        goto :node_found
    )
)

:node_found
if "%NODE_BIN_DIR%"=="" (
    cls
    echo ===================================================
    echo  ERROR: PORTABLE NODE FOLDER NOT FOUND
    echo ===================================================
    echo Could not locate a folder containing 'node.exe' in this directory.
    echo Please ensure you have extracted your Node 16 ZIP here.
    echo.
    pause
    exit /b 1
)

:: Establish critical environment paths using absolute locations
set "NPM_BIN_DIR=%NODE_BIN_DIR%\node_modules\npm\bin"
set "NPM_CLI=%NPM_BIN_DIR%\npm-cli.js"

:: Isolate environment path updates locally to this terminal session
set "PATH=%NODE_BIN_DIR%;%NPM_BIN_DIR%;%PATH%"

:: Apply legacy OpenSSL provider option needed for Node 17+ and legacy Webpack/React 16
set "NODE_OPTIONS=--openssl-legacy-provider"

:: --------------------------------------------------------
:: INTERACTIVE MENU
:: --------------------------------------------------------
:menu
cls
echo ===================================================
echo  Legacy Environment Controller (Node 16 Sandbox)
echo ===================================================
echo  Detected Node Path: %NODE_BIN_DIR%
echo.
echo  [1] Run First-Time Setup (npm install)
echo  [2] Start Application (npm run m365-build)
echo  [3] Exit
echo ===================================================
set /p choice="Select an option (1-3): "

if "%choice%"=="1" goto :run_install
if "%choice%"=="2" goto :run_start
if "%choice%"=="3" exit /b 0
goto :menu


:: --------------------------------------------------------
:: ROUTINE: SETUP / INSTALLATION
:: --------------------------------------------------------
:run_install
cls
echo ===================================================
echo  [SETUP] Verifying Environment Components
echo ===================================================
node -v
if %ERRORLEVEL% neq 0 (
    echo ERROR: Portable Node binary failed to execute.
    goto :error_exit
)

if not exist "%NPM_CLI%" (
    echo ERROR: Expected npm CLI manager missing at:
    echo "%NPM_CLI%"
    goto :error_exit
)

echo.
echo Starting dependency installation...
node "%NPM_CLI%" install --legacy-peer-deps

if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: 'npm install' encountered a critical failure.
    goto :error_exit
)

echo.
echo SUCCESS: Dependencies installed cleanly.
pause
goto :menu


:: --------------------------------------------------------
:: ROUTINE: START APP
:: --------------------------------------------------------
:run_start
cls
echo ===================================================
echo  [RUN] Executing Legacy Build Matrix
echo ===================================================
if not exist "node_modules\" (
    echo WARNING: 'node_modules' folder is missing^! 
    echo Please run option [1] ^(First-Time Setup^) before starting.
    pause
    goto :menu
)

:: Trigger local project scripts
call npm run m365-build

if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Application crashed or stopped with exit code %ERRORLEVEL%.
    goto :error_exit
)
pause
goto :menu


:: --------------------------------------------------------
:: ERROR EXIT HANDLER
:: --------------------------------------------------------
:error_exit
echo.
echo ===================================================
echo  FAILURE: Task halted due to errors.
echo ===================================================
pause
goto :menu
