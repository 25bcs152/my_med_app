@echo off
echo Building Python executable...
if not exist "assets\scripts" mkdir "assets\scripts"
pyinstaller --noconfirm --onefile --console --distpath "assets/scripts" --specpath "build" --name "process_excel" "assets/scripts/process_excel.py"
echo.
echo Build complete. Executable should be in assets/scripts/process_excel.exe
pause
