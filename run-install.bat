@echo off
setlocal enabledelayedexpansion

:: --------------------------------------------------------
:: FORCE COMMAND PROMPT ONLY
:: --------------------------------------------------------
echo %CMDCMDLINE% | findstr /i "powershell.exe pwsh.exe" >nul
if %ERRORLEVEL% equ 0 goto :force_cmd
goto :check_node

:force_cmd
echo.
echo [WARNING] This script must run in Native Command Prompt (CMD), not PowerShell.
echo Re-launching in a clean CMD window...
echo.
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
    if exist "%%~i\node.exe" (
        set "NODE_BIN_DIR=%%~i"
        goto :node_found
    )
)

goto :node_not_found

:node_found
if defined NODE_BIN_DIR goto :setup_paths

:node_not_found
cls
echo ===================================================
echo  ERROR: PORTABLE NODE FOLDER NOT FOUND
echo ===================================================
echo.
echo Could not locate a folder containing 'node.exe' under:
echo   %SCRIPT_DIR%
echo.
echo Please ensure you have extracted your Node 16 ZIP into
echo a subfolder here (e.g. node16\node.exe).
echo.
pause
exit /b 1

:: --------------------------------------------------------
:: ENVIRONMENT PATH SETUP
:: --------------------------------------------------------
:setup_paths
set "NPM_BIN_DIR=%NODE_BIN_DIR%\node_modules\npm\bin"
set "NPM_CLI=%NPM_BIN_DIR%\npm-cli.js"

:: Prepend portable node to PATH for this session only
set "PATH=%NODE_BIN_DIR%;%NPM_BIN_DIR%;%PATH%"

:: Required for Node 17+ / legacy Webpack + React 16 builds
set "NODE_OPTIONS=--openssl-legacy-provider"

:: --------------------------------------------------------
:: INTERACTIVE MENU
:: --------------------------------------------------------
:menu
cls
echo.
echo  ===================================================
echo   Legacy Environment Controller (Node 16 Sandbox)
echo  ===================================================
echo   Node Path : %NODE_BIN_DIR%
echo   npm CLI   : %NPM_CLI%
echo  ---------------------------------------------------
echo.
echo   [1]  First-Time Setup    (npm install)
echo   [2]  Build Application   (npm run m365-build)
echo   [3]  Start Local Server  (npm start)
echo   [4]  Verify Environment  (node -v / npm -v)
echo   [5]  Exit
echo.
echo  ===================================================
echo.
set "choice="
set /p choice="  Select an option (1-5): "

if "%choice%"=="1" goto :run_install
if "%choice%"=="2" goto :run_build
if "%choice%"=="3" goto :run_start
if "%choice%"=="4" goto :run_verify
if "%choice%"=="5" exit /b 0

echo.
echo  [!] Invalid option. Please enter 1, 2, 3, 4, or 5.
echo.
pause
goto :menu


:: --------------------------------------------------------
:: ROUTINE: VERIFY ENVIRONMENT
:: --------------------------------------------------------
:run_verify
cls
echo  ===================================================
echo   [VERIFY] Environment Check
echo  ===================================================
echo.
echo  -- Detected node.exe path --
echo  %NODE_BIN_DIR%\node.exe
echo.

:: Test direct execution using full path
echo  -- Node.js version (direct call) --
"%NODE_BIN_DIR%\node.exe" -v
if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERROR: node.exe exists but failed to run.
    echo  Possible causes:
    echo    1. Wrong architecture (x86 vs x64) for this machine
    echo    2. Missing Visual C++ Redistributable
    echo    3. Antivirus blocking execution
    echo    4. Corrupted ZIP extraction
    goto :error_exit
)

echo.
echo  -- npm CLI path --
echo  %NPM_CLI%
echo.

if not exist "%NPM_CLI%" (
    echo  ERROR: npm-cli.js not found at above path.
    echo  Ensure node_modules\npm\bin\ exists inside the portable folder.
    goto :error_exit
)

echo  -- npm version (direct call) --
"%NODE_BIN_DIR%\node.exe" "%NPM_CLI%" -v
if %ERRORLEVEL% neq 0 (
    echo  ERROR: npm-cli.js failed. Check: %NPM_CLI%
    goto :error_exit
)

echo.
echo  -- NODE_OPTIONS --
echo  %NODE_OPTIONS%
echo.
echo  All checks passed.
echo.
pause
goto :menu


:: --------------------------------------------------------
:: ROUTINE: SETUP / INSTALLATION
:: --------------------------------------------------------
:run_install
cls
echo  ===================================================
echo   [SETUP] Installing Dependencies
echo  ===================================================
echo.
echo  Detected node.exe: %NODE_BIN_DIR%\node.exe
echo.

:: Use FULL PATH to node.exe to avoid any PATH resolution issues
echo  -- Verifying node.exe (full path) --
"%NODE_BIN_DIR%\node.exe" -v
if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERROR: node.exe exists at the path above but FAILED to execute.
    echo.
    echo  Common causes:
    echo    [A] Architecture mismatch  - You may have a 32-bit node.exe on a 64-bit OS
    echo        or vice versa. Download the correct version from:
    echo        https://nodejs.org/dist/latest-v16.x/
    echo.
    echo    [B] Missing VC++ Runtime   - Install "Visual C++ Redistributable 2015-2022"
    echo        from Microsoft and retry.
    echo.
    echo    [C] Antivirus blocking     - Temporarily disable AV or whitelist node.exe.
    echo.
    echo    [D] Corrupted extraction   - Re-extract the Node 16 ZIP and retry.
    echo.
    goto :error_exit
)

:: Verify npm CLI exists
if not exist "%NPM_CLI%" (
    echo  ERROR: npm CLI not found at:
    echo    %NPM_CLI%
    echo.
    echo  Ensure your Node 16 ZIP was fully extracted including node_modules\npm\bin\
    goto :error_exit
)

echo.
echo  Running: npm install --legacy-peer-deps
echo.
"%NODE_BIN_DIR%\node.exe" "%NPM_CLI%" install --legacy-peer-deps
if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERROR: npm install failed with exit code %ERRORLEVEL%.
    goto :error_exit
)

echo.
echo  ===================================================
echo   SUCCESS: Dependencies installed successfully.
echo  ===================================================
echo.
pause
goto :menu


:: --------------------------------------------------------
:: ROUTINE: BUILD APP (npm run m365-build)
:: --------------------------------------------------------
:run_build
cls
echo  ===================================================
echo   [BUILD] Running m365 Build
echo  ===================================================
echo.

if not exist "%SCRIPT_DIR%node_modules\" (
    echo  WARNING: 'node_modules' folder not found!
    echo  Please run option [1] First-Time Setup first.
    echo.
    pause
    goto :menu
)

echo  Running: npm run m365-build
echo.
"%NODE_BIN_DIR%\node.exe" "%NPM_CLI%" run m365-build
if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERROR: Build exited with code %ERRORLEVEL%.
    goto :error_exit
)

echo.
pause
goto :menu


:: --------------------------------------------------------
:: ROUTINE: START LOCAL DEV SERVER (npm start)
:: --------------------------------------------------------
:run_start
cls
echo  ===================================================
echo   [START] Launching Local Development Server
echo  ===================================================
echo.

if not exist "%SCRIPT_DIR%node_modules\" (
    echo  WARNING: 'node_modules' folder not found!
    echo  Please run option [1] First-Time Setup first.
    echo.
    pause
    goto :menu
)

echo  Running: npm start
echo  Press Ctrl+C to stop the server and return to menu.
echo.
"%NODE_BIN_DIR%\node.exe" "%NPM_CLI%" start
if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERROR: Server exited with code %ERRORLEVEL%.
    goto :error_exit
)

echo.
pause
goto :menu


:: --------------------------------------------------------
:: SHARED ERROR HANDLER
:: --------------------------------------------------------
:error_exit
echo.
echo  ===================================================
echo   FAILURE: Task halted. See error above.
echo  ===================================================
echo.
pause
goto :menu
