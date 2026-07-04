@echo off
REM PantherLang Installer — Windows Batch
REM
REM Usage:
REM   install.bat
REM

echo PantherLang Installer
echo =====================
echo.

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python 3.10+ is required but not found.
    echo Install Python from https://python.org
    exit /b 1
)

echo Installing pantherlang...
pip install --upgrade pantherlang 2>nul
if errorlevel 1 (
    echo Installing from local source...
    pip install -e .
)

echo.
echo PantherLang installed!
echo Try: panther doctor
