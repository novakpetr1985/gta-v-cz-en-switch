@echo off

setlocal EnableExtensions

REM ============================================================
REM GTA V CZ/EN Switch - hlavni vstupni bod (orchestrace)
REM ============================================================
REM
REM Spousti jednotlive kroky ze slozky scripts\ ve spravnem
REM poradi, vyhodnocuje jejich navratove kody a beh ukoncuje
REM pres centralni logger.
REM
REM Aktualni workflow:
REM   1. scripts\launcher.bat
REM   2. scripts\offline.bat
REM   3. scripts\uia.bat
REM
REM Navratovy kod:
REM   0 = vsechny provedene kroky byly uspesne
REM   1 = nektery krok skoncil chybou
REM
REM Bez cekani na klavesu na konci:
REM   set NOPAUSE=1
REM
REM ============================================================

title GTA V CZ/EN Switch

REM ============================================================
REM INICIALIZACE
REM ============================================================
REM
REM Prvni volani loggeru inicializuje:
REM   - RUN_ID
REM   - RUN_LOG
REM   - CORE_DIR
REM   - barvy konzole
REM   - centralni konfiguraci
REM
REM ============================================================

call "%~dp0core\logger.bat" INFO "Start aplikace." SCRIPT_START F

echo.

echo %BOLD%%WHITE%GTA V CZ/EN Switch%RESET%

REM ============================================================
REM KROKY
REM ============================================================

REM ------------------------------------------------------------
REM 1. LAUNCHER
REM ------------------------------------------------------------

call "%~dp0scripts\launcher.bat"
if errorlevel 1 goto END_ERROR


REM ------------------------------------------------------------
REM 2. OFFLINE
REM ------------------------------------------------------------

call "%~dp0scripts\offline.bat"
if errorlevel 1 goto END_ERROR


REM ------------------------------------------------------------
REM 3. UI AUTOMATION
REM ------------------------------------------------------------

call "%~dp0scripts\uia.bat"
if errorlevel 1 goto END_ERROR


REM ============================================================
REM UKONCENI - USPESNE
REM ============================================================
REM
REM Pokud se sem beh dostane, vsechny provedene kroky vratily kod 0.
REM
REM ============================================================

:END_OK

call "%CORE_DIR%logger.bat" NL

call "%CORE_DIR%logger.bat" OK "Launcher bezi v offline rezimu a UI Automation probehla uspesne."

call "%CORE_DIR%logger.bat" FINISH SUCCESS 0

if not defined NOPAUSE pause

exit /b 0


REM ============================================================
REM UKONCENI - CHYBA
REM ============================================================
REM
REM Nektery z provedenych kroku vratil nenulovy navratovy kod.
REM Podrobnosti jsou dostupne v centralnim logu.
REM
REM ============================================================

:END_ERROR

call "%CORE_DIR%logger.bat" NL

call "%CORE_DIR%logger.bat" ERR "Beh skoncil chybou. Podrobnosti v logu: %RUN_LOG%"

call "%CORE_DIR%logger.bat" FINISH FAILURE 1

if not defined NOPAUSE pause

exit /b 1
