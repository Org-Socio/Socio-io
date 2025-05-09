@echo off
:: Socio.io Native Host Installer for Windows
echo Installing Socio.io Native Messaging Host...

:: Get the directory where the script is located
set SCRIPT_DIR=%~dp0

:: Create a log file
echo Installation started at %date% %time% > "%SCRIPT_DIR%install_log.txt"

:: Check if running as administrator
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: This script must be run as administrator.
    echo ERROR: This script must be run as administrator. >> "%SCRIPT_DIR%install_log.txt"
    echo Please right-click on this script and select "Run as administrator".
    goto :error
)

:: Check if Python is installed
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Python is not installed or not in PATH.
    echo ERROR: Python is not installed or not in PATH. >> "%SCRIPT_DIR%install_log.txt"
    echo Please install Python and make sure it's in your PATH.
    goto :error
)

:: Get Python version
for /f "tokens=*" %%a in ('python --version 2^>^&1') do (
    echo Python version: %%a
    echo Python version: %%a >> "%SCRIPT_DIR%install_log.txt"
)

:: Update the manifest file with the correct path
echo Updating manifest file with correct paths...
echo Updating manifest file with correct paths... >> "%SCRIPT_DIR%install_log.txt"

:: Create a temporary file with the updated content
echo {> "%SCRIPT_DIR%temp_manifest.json"
echo   "name": "com.socioio.contentfilter",>> "%SCRIPT_DIR%temp_manifest.json"
echo   "description": "Socio.io Content Filter Native Host",>> "%SCRIPT_DIR%temp_manifest.json"
echo   "path": "%SCRIPT_DIR:\=\\%socioio_host_win.bat",>> "%SCRIPT_DIR%temp_manifest.json"
echo   "type": "stdio",>> "%SCRIPT_DIR%temp_manifest.json"
echo   "allowed_origins": [>> "%SCRIPT_DIR%temp_manifest.json"
echo     "chrome-extension://<extension-id>/",>> "%SCRIPT_DIR%temp_manifest.json"
echo     "chrome-extension://*/",>> "%SCRIPT_DIR%temp_manifest.json"
echo     "edge-extension://<extension-id>/",>> "%SCRIPT_DIR%temp_manifest.json"
echo     "edge-extension://*/">> "%SCRIPT_DIR%temp_manifest.json"
echo   ]>> "%SCRIPT_DIR%temp_manifest.json"
echo }>> "%SCRIPT_DIR%temp_manifest.json"

:: Replace the original manifest with the updated one
copy /y "%SCRIPT_DIR%temp_manifest.json" "%SCRIPT_DIR%socioio_host_win.json" >nul
del "%SCRIPT_DIR%temp_manifest.json"

echo Manifest file updated.
echo Manifest file updated. >> "%SCRIPT_DIR%install_log.txt"

:: Set the registry key path for Chrome
set REG_KEY=HKCU\Software\Google\Chrome\NativeMessagingHosts\com.socioio.contentfilter

:: Create the registry key for Chrome
echo Creating registry key for Chrome...
echo Creating registry key for Chrome... >> "%SCRIPT_DIR%install_log.txt"
reg add "%REG_KEY%" /ve /t REG_SZ /d "%SCRIPT_DIR%socioio_host_win.json" /f
if %ERRORLEVEL% NEQ 0 (
    echo Failed to create registry key for Chrome.
    echo Failed to create registry key for Chrome. >> "%SCRIPT_DIR%install_log.txt"
    goto :error
)

:: Verify the registry key for Chrome
reg query "%REG_KEY%" /ve
if %ERRORLEVEL% NEQ 0 (
    echo Failed to verify registry key for Chrome.
    echo Failed to verify registry key for Chrome. >> "%SCRIPT_DIR%install_log.txt"
    goto :error
)

:: Set the registry key path for Edge
set REG_KEY=HKCU\Software\Microsoft\Edge\NativeMessagingHosts\com.socioio.contentfilter

:: Create the registry key for Edge
echo Creating registry key for Edge...
echo Creating registry key for Edge... >> "%SCRIPT_DIR%install_log.txt"
reg add "%REG_KEY%" /ve /t REG_SZ /d "%SCRIPT_DIR%socioio_host_win.json" /f
if %ERRORLEVEL% NEQ 0 (
    echo Failed to create registry key for Edge.
    echo Failed to create registry key for Edge. >> "%SCRIPT_DIR%install_log.txt"
    goto :error
)

:: Verify the registry key for Edge
reg query "%REG_KEY%" /ve
if %ERRORLEVEL% NEQ 0 (
    echo Failed to verify registry key for Edge.
    echo Failed to verify registry key for Edge. >> "%SCRIPT_DIR%install_log.txt"
    goto :error
)

:: Test the native host
echo Testing native host...
echo Testing native host... >> "%SCRIPT_DIR%install_log.txt"
python "%SCRIPT_DIR%test_host.py" >> "%SCRIPT_DIR%install_log.txt" 2>&1

echo Native messaging host installed successfully.
echo Native messaging host installed successfully. >> "%SCRIPT_DIR%install_log.txt"
echo You can now use the Socio.io extension with automatic backend startup.
echo Installation completed at %date% %time% >> "%SCRIPT_DIR%install_log.txt"
goto :end

:error
echo Installation failed. Please check the log file for details.
echo Installation failed at %date% %time% >> "%SCRIPT_DIR%install_log.txt"

:end
echo.
echo Press any key to exit...
pause > nul