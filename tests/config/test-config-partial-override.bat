@echo off
setlocal

REM ============================================================
REM GTA V CZ/EN Switch - Config Partial Override Test
REM ============================================================
REM
REM Ověření, že Config zachová již nastavenou hodnotu
REM a současně doplní chybějící výchozí hodnotu.
REM ============================================================

set "TEST_FAILED=0"

REM LOG_KEEP je nastaven volajicim skriptem a musi zustat zachovan.
REM LOG_LEVEL nastaven neni a Config proto musi pouzit vychozi hodnotu.
set "LOG_KEEP=10"

call "%~dp0..\..\config\config.bat"

if "%LOG_KEEP%"=="10" (
    echo [ OK ] LOG_KEEP override preserved: 10
) else (
    echo [FAIL] LOG_KEEP override expected 10, got %LOG_KEEP%
    set "TEST_FAILED=1"
)

if "%LOG_LEVEL%"=="INFO" (
    echo [ OK ] LOG_LEVEL default applied: INFO
) else (
    echo [FAIL] LOG_LEVEL expected INFO, got %LOG_LEVEL%
    set "TEST_FAILED=1"
)

if "%TEST_FAILED%"=="0" (
    echo.
    echo Config partial override test: PASS
    exit /b 0
)

echo.
echo Config partial override test: FAIL
exit /b 1
