@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "BACKEND=%ROOT%Project_GiaLap\sos_care_backend"
set "SIMULATOR=%ROOT%Project_GiaLap\sos_device_simulator"

echo ============================================
echo   SOS Care - Khoi dong tat ca project
echo ============================================
echo.

REM --- Buoc 0: Hoi tao lai DB (Y/N) ---
set "RECREATE_DB=N"
set /p "RECREATE_DB=  [DB] Tao lai database moi? [Y= xoa + tao lai + migrate / N= giu nguyen]: "
if /i "!RECREATE_DB!"=="Y" (
    echo.
    echo  [DB] Dang tao lai database...
    cd /d "%BACKEND%"
    echo  [DB] 1/3 - db:drop
    call npx sequelize-cli db:drop
    echo  [DB] 2/3 - db:create
    call npx sequelize-cli db:create
    echo  [DB] 3/3 - db:migrate
    call npx sequelize-cli db:migrate
    if errorlevel 1 (
        echo  [DB] CO LOI khi migrate - xem chi tiet tren.
        pause
    ) else (
        echo  [DB] Da tao lai DB thanh cong.
    )
    echo.
) else (
    echo  [DB] Bo qua - giu nguyen du lieu hien co.
    echo.
)

REM --- Buoc 1: sos_care_backend ---
echo [1/3] Mo sos_care_backend (npm run dev)...
cd /d "%BACKEND%"
start "sos_care_backend" cmd /k npm run dev

REM --- Buoc 2: flutter_application_1 ---
echo [2/3] Mo flutter_application_1...
cd /d "%ROOT%"
start "flutter_application_1" cmd /k flutter run

REM --- Buoc 3: sos_device_simulator ---
echo [3/3] Mo sos_device_simulator...
cd /d "%SIMULATOR%"
start "sos_device_simulator" cmd /k flutter run

echo.
echo Ba project dang chay trong cua so cmd rieng. Cua so nay co the tat.
endlocal