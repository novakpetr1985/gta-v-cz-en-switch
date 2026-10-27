@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem GTA V CZ/EN Switch
rem UIA test - SEARCH TIMEOUT
rem ============================================================

set "TEST_NAME=UIA TIMEOUT"
set "NOPAUSE=1"

set "PROJECT_DIR=%~dp0..\.."
set "UIA_FILE=%PROJECT_DIR%\scripts\uia.bat"

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
rem UIA search timeout test
rem ------------------------------------------------------------
rem UIA_TIMEOUT urcuje dobu hledani prvku.
rem Pri nenalezeni prvku UIA korektne vraci RC=2 / NOT_FOUND.
rem Safety timeout PowerShell helperu je samostatny mechanismus.

set "UIA_MODE=invoke"
set "UIA_NAMES=P2_TEST_NEEXISTUJE"
set "UIA_REGEX="
set "UIA_NAV="
set "UIA_WINDOW_HANDLE="
set "UIA_DUMP="
set "UIA_TIMING="
set "UIA_TIMEOUT=1"

echo [INFO] Spoustim UIA modul...
echo [INFO] UIA_MODE=%UIA_MODE%
echo [INFO] UIA_NAMES=%UIA_NAMES%
echo [INFO] UIA_TIMEOUT=%UIA_TIMEOUT%
echo.

call "%UIA_FILE%"

set "UIA_RC=%ERRORLEVEL%"

echo.
echo [INFO] UIA_RC=%UIA_RC%
echo [INFO] UIA_RESULT=%UIA_RESULT%

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
