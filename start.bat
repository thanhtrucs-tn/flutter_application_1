@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "BACKEND=%ROOT%Project_GiaLap\sos_care_backend"
set "SIMULATOR=%ROOT%Project_GiaLap\sos_device_simulator"

echo [1/3] Mo sos_care_backend (npm run dev)...
cd /d "%BACKEND%"
start "sos_care_backend" cmd /k npm run dev

echo [2/3] Mo flutter_application_1...
cd /d "%ROOT%"
start "flutter_application_1" cmd /k flutter run

echo [3/3] Mo sos_device_simulator...
cd /d "%SIMULATOR%"
start "sos_device_simulator" cmd /k flutter run

echo Ba project dang chay trong cua so cmd rieng. Cua so nay co the tat.
endlocal
