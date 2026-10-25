@echo off

REM ============================================================
REM GTA V CZ/EN Switch - Configuration
REM ============================================================
REM
REM Centralni konfigurace cele aplikace.
REM
REM Tento soubor neni urcen ke spousteni jako samostatny program.
REM Jednotlive moduly jej nacitaji pomoci CALL.
REM
REM ============================================================


REM ============================================================
REM LOGGER
REM ============================================================

REM Pocet poslednich behu, ktere maji byt zachovany.
if not defined LOG_KEEP set "LOG_KEEP=30"

REM Vychozi uroven loggeru.
if not defined LOG_LEVEL set "LOG_LEVEL=INFO"


REM ============================================================
REM ROCKSTAR LAUNCHER
REM ============================================================

REM Cesta k LauncherPatcher.exe.
REM Patcher spousti Rockstar Launcher.
if not defined ROCKSTAR_PATCHER set "ROCKSTAR_PATCHER=C:\Program Files\Rockstar Games\Launcher\LauncherPatcher.exe"

REM Slozka s logy Rockstar Launcheru.
REM Tato hodnota je pripravena pro dalsi analyzu launcher.log.
if not defined ROCKSTAR_LOG_DIR set "ROCKSTAR_LOG_DIR=%USERPROFILE%\Documents\Rockstar Games\Launcher"

REM Maximalni doba cekani na proces Launcher.exe.
REM Hodnota je v sekundach.
if not defined TIMEOUT_LAUNCHER set "TIMEOUT_LAUNCHER=120"

REM Maximalni doba cekani na viditelne a aktivovatelne okno.
REM Hodnota je v sekundach.
if not defined TIMEOUT_WINDOW set "TIMEOUT_WINDOW=15"


REM ============================================================
REM KONEC MODULU
REM ============================================================

exit /b 0
