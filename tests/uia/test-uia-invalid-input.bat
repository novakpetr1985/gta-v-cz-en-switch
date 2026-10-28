@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem GTA V CZ/EN Switch
rem UIA test - INVALID INPUT
rem ============================================================

set "TEST_NAME=UIA INVALID INPUT"
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
rem Invalid UIA input
rem ------------------------------------------------------------

set "UIA_MODE=invalid"
set "UIA_NAMES=PLAY"
set "UIA_REGEX="
set "UIA_NAV="
set "UIA_WINDOW_HANDLE="
set "UIA_DUMP="
set "UIA_TIMING="

echo [INFO] Spoustim UIA modul...
echo [INFO] UIA_MODE=%UIA_MODE%
echo [INFO] UIA_NAMES=%UIA_NAMES%
echo.

call "%UIA_FILE%"

set "UIA_RC=%ERRORLEVEL%"

echo.
echo [INFO] UIA_RC=%UIA_RC%
echo [INFO] UIA_RESULT=%UIA_RESULT%

rem ------------------------------------------------------------
rem Expected result
rem ------------------------------------------------------------

if not "%UIA_RC%"=="4" (
    echo [FAIL] UIA vratilo neocekavany kod: %UIA_RC%
    goto :TEST_END
)

if /I not "%UIA_RESULT%"=="ERROR" (
    echo [FAIL] UIA_RESULT ma neocekavanou hodnotu: "%UIA_RESULT%"
    goto :TEST_END
)

echo [ OK ] UIA vratilo RC=4.
echo [ OK ] UIA_RESULT=ERROR.
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
