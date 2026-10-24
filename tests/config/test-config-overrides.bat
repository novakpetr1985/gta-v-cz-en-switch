@echo off
setlocal

REM ============================================================
REM GTA V CZ/EN Switch - Config Override Test
REM ============================================================
REM
REM Ověření, že centrální konfigurace nepřepíše hodnoty,
REM které byly nastaveny volajícím skriptem.
REM ============================================================

set "TEST_FAILED=0"

REM Predem nastavene hodnoty simuluji konfiguraci dodanou volajicim skriptem.
REM Test overuje, ze centralni Config tyto hodnoty zachova.
set "LOG_KEEP=10"
set "LOG_LEVEL=DEBUG"

call "%~dp0..\..\config\config.bat"

if "%LOG_KEEP%"=="10" (
    echo [ OK ] LOG_KEEP override preserved: 10
) else (
    echo [FAIL] LOG_KEEP override expected 10, got %LOG_KEEP%
    set "TEST_FAILED=1"
)

if "%LOG_LEVEL%"=="DEBUG" (
    echo [ OK ] LOG_LEVEL override preserved: DEBUG
) else (
    echo [FAIL] LOG_LEVEL override expected DEBUG, got %LOG_LEVEL%
    set "TEST_FAILED=1"
)

if "%TEST_FAILED%"=="0" (
    echo.
    echo Config override test: PASS
    exit /b 0
)

echo.
echo Config override test: FAIL
exit /b 1
