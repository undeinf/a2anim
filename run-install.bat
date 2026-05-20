@echo off
setlocal enabledelayedexpansion

:: --------------------------------------------------------
:: FORCE COMMAND PROMPT ONLY
:: --------------------------------------------------------
echo %CMDCMDLINE% | findstr /i "powershell.exe pwsh.exe" >nul
if %ERRORLEVEL% equ 0 goto :force_cmd
goto :check_node

:force_cmd
echo [WARNING] This script must run in Native Command Prompt (CMD), not PowerShell.
echo Re-launching in a clean CMD window...
pause
start cmd.exe /c "%~dp0%~nx0"
exit /b

:: --------------------------------------------------------
:: DYNAMIC NODE FOLDER DETECTION
:: --------------------------------------------------------
:check_node
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
if not "%NODE_BIN_DIR%"=="" goto :setup_paths
cls
echo ===================================================
echo  ERROR: PORTABLE NODE FOLDER NOT FOUND
echo ===================================================
echo Could not locate a folder containing 'node.exe' in this directory.
echo Please ensure you have extracted your Node 16 ZIP here.
echo.
pause
exit /b 1

:: --------------------------------------------------------
:: ENVIRONMENT PATH SETUP
:: --------------------------------------------------------
:setup_paths
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
set "choice="
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
if %ERRORLEVEL% neq 0 goto :err_node_exec

if not exist "%NPM_CLI%" goto :err_npm_missing

echo.
echo Starting dependency installation...
node "%NPM_CLI%" install --legacy-peer-deps
if %ERRORLEVEL% neq 0 goto :err_install_failed

echo.
echo SUCCESS: Dependencies installed cleanly.
pause
goto :menu

:err_node_exec
echo ERROR: Portable Node binary failed to execute.
goto :error_exit

:err_npm_missing
echo ERROR: Expected npm CLI manager missing at: "%NPM_CLI%"
goto :error_exit

:err_install_failed
echo.
echo ERROR: 'npm install' encountered a critical failure.
goto :error_exit


:: --------------------------------------------------------
:: ROUTINE: START APP
:: --------------------------------------------------------
:run_start
cls
echo ===================================================
echo  [RUN] Executing Legacy Build Matrix
echo ===================================================
if not exist "node_modules\" goto :err_no_modules

:: Trigger local project scripts
call npm run m365-build
if %ERRORLEVEL% neq 0 goto :err_run_failed
pause
goto :menu

:err_no_modules
echo WARNING: 'node_modules' folder is missing!
echo Please run option [1] (First-Time Setup) before starting.
pause
goto :menu

:err_run_failed
echo.
echo ERROR: Application crashed or stopped with exit code %ERRORLEVEL%.
goto :error_exit


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
