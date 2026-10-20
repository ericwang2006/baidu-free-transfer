@echo off
setlocal
cd /d "%~dp0"

echo ==================================================
echo  Build baidu-free-transfer.exe (Windows, onefile)
echo ==================================================
echo.

rem Locate a usable Python 3 interpreter.
py -3 --version >nul 2>nul
if not errorlevel 1 goto :use_py
python --version >nul 2>nul
if errorlevel 1 goto :no_python
set "PYTHON=python"
goto :python_found

:use_py
set "PYTHON=py -3"

:python_found
echo [1/3] Using Python launcher: %PYTHON%
if exist ".venv" (
    echo       Removing old virtual environment .venv ...
    rmdir /s /q ".venv"
    if exist ".venv" (
        echo [ERROR] Failed to remove .venv. Close programs using it and retry.
        goto :fail
    )
)
echo       Creating virtual environment .venv ...
%PYTHON% -m venv .venv
if errorlevel 1 goto :fail

call ".venv\Scripts\activate.bat"
if errorlevel 1 goto :fail

echo [2/3] Installing dependencies ...
python -m pip install --upgrade pip
if errorlevel 1 goto :fail
python -m pip install -r requirements.txt pyinstaller
if errorlevel 1 goto :fail

echo [3/3] Building dist\baidutransfer.exe ...
python -m PyInstaller --noconfirm --clean --onefile --console --name baidutransfer --paths . "baidutransfer\__main__.py"
if errorlevel 1 goto :fail
if not exist "dist\baidutransfer.exe" goto :fail

echo.
echo Build succeeded:
echo   %CD%\dist\baidutransfer.exe
echo.
echo Run it from a directory containing config.yaml, for example:
echo   baidutransfer.exe "https://pan.baidu.com/s/xxxx" -p pwd -r /remote/path
goto :done

:no_python
echo [ERROR] Python 3 was not found.
echo         Install Python 3.7+ from https://www.python.org/ and enable
echo         "Add python.exe to PATH", then run this script again.
goto :done

:fail
echo.
echo [ERROR] Build failed. See the messages above.

:done
echo.
if not defined CI pause
endlocal
