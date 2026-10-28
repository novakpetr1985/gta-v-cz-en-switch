@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem GTA V CZ/EN Switch
rem UIA test - DIAGNOSTIC DUMP
rem ============================================================

set "TEST_NAME=UIA DUMP"
set "NOPAUSE=1"

set "PROJECT_DIR=%~dp0..\.."
set "UIA_FILE=%PROJECT_DIR%\scripts\uia.bat"
set "DUMP_FILE=%PROJECT_DIR%\diagnostics\gta_v_cz_en_uia_dump.txt"

set "TEST_RC=1"

echo.
echo ============================================================
echo Test: %TEST_NAME%
echo ============================================================
echo.

if not exist "%UIA_FILE%" (
    echo [FAIL] UIA modul nebyl nalezen:
    echo        %UIA_FILE%
    goto :TEST_END
)

rem ------------------------------------------------------------
rem Remove previous dump
rem ------------------------------------------------------------

if exist "%DUMP_FILE%" (
    del /q "%DUMP_FILE%" >nul 2>&1
)

rem ------------------------------------------------------------
rem UIA test input
rem ------------------------------------------------------------

set "UIA_MODE=invoke"
set "UIA_NAMES=P2_TEST_NEEXISTUJE"
set "UIA_REGEX="
set "UIA_NAV="
set "UIA_WINDOW_HANDLE="
set "UIA_DUMP=%DUMP_FILE%"
set "UIA_TIMING="

echo [INFO] Spoustim UIA modul...
echo [INFO] UIA_MODE=%UIA_MODE%
echo [INFO] UIA_NAMES=%UIA_NAMES%
echo [INFO] UIA_DUMP=%UIA_DUMP%
echo.

call "%UIA_FILE%"

set "UIA_RC=%ERRORLEVEL%"

echo.
echo [INFO] UIA_RC=%UIA_RC%
echo [INFO] UIA_RESULT=%UIA_RESULT%
echo [INFO] UIA_DUMP_PATH=%UIA_DUMP_PATH%

rem ------------------------------------------------------------
rem Expected result
rem ------------------------------------------------------------

if not "%UIA_RC%"=="2" (
    echo [FAIL] UIA vratilo neocekavany kod: %UIA_RC%
    goto :TEST_END
)

if /I not "%UIA_RESULT%"=="NOT_FOUND" (
    echo [FAIL] UIA_RESULT ma neocekavanou hodnotu: "%UIA_RESULT%"
    goto :TEST_END
)

echo [ OK ] UIA vratilo RC=2.
echo [ OK ] UIA_RESULT=NOT_FOUND.

rem ------------------------------------------------------------
rem Dump existence
rem ------------------------------------------------------------

if not exist "%DUMP_FILE%" (
    echo [FAIL] Diagnosticky dump nebyl vytvoren:
    echo        %DUMP_FILE%
    goto :TEST_END
)

echo [ OK ] Diagnosticky dump existuje.

rem ------------------------------------------------------------
rem Dump must not be empty
rem ------------------------------------------------------------

for %%F in ("%DUMP_FILE%") do set "DUMP_SIZE=%%~zF"

if not defined DUMP_SIZE (
    echo [FAIL] Nelze zjistit velikost diagnostickeho dumpu.
    goto :TEST_END
)

if "%DUMP_SIZE%"=="0" (
    echo [FAIL] Diagnosticky dump je prazdny.
    goto :TEST_END
)

echo [ OK ] Diagnosticky dump neni prazdny.
echo [INFO] Velikost dumpu: %DUMP_SIZE% B

set "TEST_RC=0"

:TEST_END

echo.
if "%TEST_RC%"=="0" (
    echo ============================================================
    echo [ OK ] TEST %TEST_NAME% - PASSED
    echo ============================================================
) else (
    echo ============================================================
    echo [FAIL] TEST %TEST_NAME% - FAILED
    echo ============================================================
)

if not defined NOPAUSE (
    pause
)

endlocal & exit /b %TEST_RC%
