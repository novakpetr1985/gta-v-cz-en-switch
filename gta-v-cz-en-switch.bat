@echo off
setlocal EnableExtensions
REM ============================================================
REM GTA V CZ/EN Switch - hlavni vstupni bod (orchestrace)
REM ============================================================
REM
REM Spousti jednotlive kroky ze slozky scripts\ ve spravnem poradi,
REM vyhodnocuje jejich navratove kody a beh ukoncuje pres logger.
REM
REM Aktualni kroky:
REM   1. scripts\launcher.bat - spusteni Rockstar Launcheru
REM
REM Navratovy kod: 0 = OK, 1 = chyba.
REM Bez cekani na klavesu na konci: set NOPAUSE=1
REM ============================================================

title GTA V CZ/EN Switch

REM Prvni volani inicializuje logger (RUN_ID, RUN_LOG, CORE_DIR,
REM barvy i konfiguraci z config\config.bat).
call "%~dp0core\logger.bat" INFO "Start aplikace." SCRIPT_START F

echo.
echo %BOLD%%WHITE%GTA V CZ/EN Switch%RESET%

REM ============================================================
REM KROKY
REM ============================================================

call "%~dp0scripts\launcher.bat"
if errorlevel 1 goto END_ERROR


REM ============================================================
REM UKONCENI
REM ============================================================

:END_OK
call "%CORE_DIR%logger.bat" NL
call "%CORE_DIR%logger.bat" OK "Rockstar Launcher je spusten."
call "%CORE_DIR%logger.bat" FINISH SUCCESS 0
if not defined NOPAUSE pause
exit /b 0

:END_ERROR
call "%CORE_DIR%logger.bat" NL
call "%CORE_DIR%logger.bat" ERR "Beh skoncil chybou. Podrobnosti v logu: %RUN_LOG%"
call "%CORE_DIR%logger.bat" FINISH FAILURE 1
if not defined NOPAUSE pause
exit /b 1
