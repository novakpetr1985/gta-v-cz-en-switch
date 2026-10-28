@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem GTA V CZ/EN Switch
rem UIA test - TIMING
rem ============================================================

set "TEST_NAME=UIA TIMING"
set "NOPAUSE=1"

set "PROJECT_DIR=%~dp0..\.."
set "UIA_FILE=%PROJECT_DIR%\scripts\uia.bat"
set "TIMING_FILE=%PROJECT_DIR%\diagnostics\uia-timing-test.txt"

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
rem Remove previous timing file
rem ------------------------------------------------------------

if exist "%TIMING_FILE%" (
    del /q "%TIMING_FILE%" >nul 2>&1
)

rem ------------------------------------------------------------
rem UIA test input
rem ------------------------------------------------------------
rem Pouzivame neexistujici prvek, aby test nespustil hru.
rem Testuje se NOT_FOUND timing flow.

set "UIA_MODE=invoke"
set "UIA_NAMES=P2_TEST_NEEXISTUJE"
set "UIA_REGEX="
set "UIA_NAV="
set "UIA_WINDOW_HANDLE="
set "UIA_DUMP="
set "UIA_TIMING=%TIMING_FILE%"
set "UIA_TIMEOUT=1"

echo [INFO] Spoustim UIA modul...
echo [INFO] UIA_MODE=%UIA_MODE%
echo [INFO] UIA_NAMES=%UIA_NAMES%
echo [INFO] UIA_TIMEOUT=%UIA_TIMEOUT%
echo [INFO] UIA_TIMING=%UIA_TIMING%
echo.

call "%UIA_FILE%"

set "UIA_RC=%ERRORLEVEL%"

echo.
echo [INFO] UIA_RC=%UIA_RC%
echo [INFO] UIA_RESULT=%UIA_RESULT%

rem ------------------------------------------------------------
rem Expected NOT_FOUND
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
rem Timing file existence
rem ------------------------------------------------------------

if not exist "%TIMING_FILE%" (
    echo [FAIL] Timing soubor nebyl vytvoren:
    echo        %TIMING_FILE%
    goto :TEST_END
)

echo [ OK ] Timing soubor existuje.

rem ------------------------------------------------------------
rem Timing file must not be empty
rem ------------------------------------------------------------

for %%F in ("%TIMING_FILE%") do set "TIMING_SIZE=%%~zF"

if not defined TIMING_SIZE (
    echo [FAIL] Nelze zjistit velikost timing souboru.
    goto :TEST_END
)

if "%TIMING_SIZE%"=="0" (
    echo [FAIL] Timing soubor je prazdny.
    goto :TEST_END
)

echo [ OK ] Timing soubor neni prazdny.
echo [INFO] Velikost timing souboru: %TIMING_SIZE% B

rem ------------------------------------------------------------
rem Expected NOT_FOUND timing events
rem ------------------------------------------------------------

for %%E in (
    "START"
    "UIAUTOMATION_READY"
    "FIND_NAME_START"
    "FIND_NAME_END"
    "TARGET_NOT_FOUND"
) do (
    findstr /C:"%%~E" "%TIMING_FILE%" >nul 2>&1

    if errorlevel 1 (
        echo [FAIL] Timing udalost nebyla nalezena: %%~E
        goto :TEST_END
    )

    echo [ OK ] Timing udalost: %%~E
)

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
