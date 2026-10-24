@echo off

REM SETLOCAL zajistuje, ze promenne nastavene behem testu
REM nezustanou v prostredi volajiciho skriptu.
setlocal

REM ============================================================
REM GTA V CZ/EN Switch - Config Test
REM ============================================================
REM
REM Ověření výchozích hodnot centrální konfigurace.
REM ============================================================

set "TEST_FAILED=0"

REM Test musi zacit bez hodnot zdedenych z prostredi volajiciho.
REM Tim se overuje, ze Config skutecne nastavi sve vychozi hodnoty.
set "LOG_KEEP="
set "LOG_LEVEL="

call "%~dp0..\..\config\config.bat"

if "%LOG_KEEP%"=="30" (
    echo [ OK ] LOG_KEEP=30
) else (
    echo [FAIL] LOG_KEEP expected 30, got %LOG_KEEP%
    set "TEST_FAILED=1"
)

if "%LOG_LEVEL%"=="INFO" (
    echo [ OK ] LOG_LEVEL=INFO
) else (
    echo [FAIL] LOG_LEVEL expected INFO, got %LOG_LEVEL%
    set "TEST_FAILED=1"
)

if "%TEST_FAILED%"=="0" (
    echo.
    echo Config test: PASS
    exit /b 0
)

echo.
echo Config test: FAIL
exit /b 1
