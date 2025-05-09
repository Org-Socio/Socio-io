@echo off
REM Socio.io Native Host Launcher
REM This script launches the Python native host

REM Log startup
echo %date% %time% - Starting Socio.io native host > "%~dp0socioio_host_launcher.log"

REM Try to use Python from PATH
python --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %date% %time% - Python not found in PATH, trying specific paths >> "%~dp0socioio_host_launcher.log"
    
    REM Try common Python installation paths
    if exist "C:\Python39\python.exe" (
        echo %date% %time% - Using Python from C:\Python39 >> "%~dp0socioio_host_launcher.log"
        "C:\Python39\python.exe" "%~dp0socioio_host.py"
    ) else if exist "C:\Python310\python.exe" (
        echo %date% %time% - Using Python from C:\Python310 >> "%~dp0socioio_host_launcher.log"
        "C:\Python310\python.exe" "%~dp0socioio_host.py"
    ) else if exist "C:\Program Files\Python39\python.exe" (
        echo %date% %time% - Using Python from Program Files >> "%~dp0socioio_host_launcher.log"
        "C:\Program Files\Python39\python.exe" "%~dp0socioio_host.py"
    ) else if exist "C:\Program Files\Python310\python.exe" (
        echo %date% %time% - Using Python from Program Files >> "%~dp0socioio_host_launcher.log"
        "C:\Program Files\Python310\python.exe" "%~dp0socioio_host.py"
    ) else if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python39\python.exe" (
        echo %date% %time% - Using Python from AppData >> "%~dp0socioio_host_launcher.log"
        "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python39\python.exe" "%~dp0socioio_host.py"
    ) else if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python310\python.exe" (
        echo %date% %time% - Using Python from AppData >> "%~dp0socioio_host_launcher.log"
        "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python310\python.exe" "%~dp0socioio_host.py"
    ) else (
        echo %date% %time% - Python not found in common locations >> "%~dp0socioio_host_launcher.log"
        echo Python not found. Please install Python and make sure it's in your PATH. > "%~dp0python_error.txt"
        exit /b 1
    )
) else (
    echo %date% %time% - Using Python from PATH >> "%~dp0socioio_host_launcher.log"
    python "%~dp0socioio_host.py"
)

echo %date% %time% - Native host exited with code %ERRORLEVEL% >> "%~dp0socioio_host_launcher.log"