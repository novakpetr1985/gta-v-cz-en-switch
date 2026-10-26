@echo off
REM ============================================================
REM GTA V CZ/EN Switch - Configuration
REM ============================================================
REM
REM Centralni konfigurace cele aplikace.
REM
REM Tento soubor neni urcen ke spousteni jako samostatny program.
REM Jednotlive casti aplikace jej nacitaji pomoci CALL.
REM
REM ============================================================


REM ============================================================
REM LOGGER
REM ============================================================

REM Pocet poslednich logu, ktere maji byt zachovany.
if not defined LOG_KEEP set "LOG_KEEP=30"

REM Vychozi uroven loggeru pro budouci filtrovani zprav.
REM Aktualni logger tuto hodnotu zatim nepouziva jako filtr.
if not defined LOG_LEVEL set "LOG_LEVEL=INFO"


REM ============================================================
REM ROCKSTAR LAUNCHER
REM ============================================================

REM Slozka s launcher.log Rockstar Games Launcheru.
if not defined ROCKSTAR_LOG_DIR set "ROCKSTAR_LOG_DIR=%USERPROFILE%\Documents\Rockstar Games\Launcher"


REM ============================================================
REM TIMEOUTY
REM ============================================================

REM Maximalni doba cekani na viditelne a aktivovatelne okno Launcheru.
if not defined TIMEOUT_WINDOW set "TIMEOUT_WINDOW=15"

REM Maximalni doba cekani na potvrzeni offline rezimu po kliknuti.
if not defined TIMEOUT_OFFLINE_EFFECT set "TIMEOUT_OFFLINE_EFFECT=30"

REM Maximalni doba cekani na rucni potvrzeni GO OFFLINE.
if not defined TIMEOUT_OFFLINE_MANUAL set "TIMEOUT_OFFLINE_MANUAL=180"


REM ============================================================
REM KONEC MODULU
REM ============================================================

exit /b 0
