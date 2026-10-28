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

REM Cesta k LauncherPatcher.exe.
if not defined ROCKSTAR_PATCHER set "ROCKSTAR_PATCHER=C:\Program Files\Rockstar Games\Launcher\LauncherPatcher.exe"

REM Adresar s launcher.log Rockstar Games Launcheru.
REM Standardne <Dokumenty>\Rockstar Games\Launcher. Cesta k Dokumentum
REM se zjisti ze systemu, aby fungovala i s presmerovanymi slozkami
REM (OneDrive). Predem nastavena hodnota se neprepisuje.
if not defined ROCKSTAR_LOG_DIR (
    for /f "delims=" %%D in ('powershell -NoProfile -Command "[Environment]::GetFolderPath('MyDocuments')"') do set "ROCKSTAR_LOG_DIR=%%D\Rockstar Games\Launcher"
)
if not defined ROCKSTAR_LOG_DIR set "ROCKSTAR_LOG_DIR=%USERPROFILE%\Documents\Rockstar Games\Launcher"


REM ============================================================
REM TIMEOUTY
REM ============================================================

REM Maximalni doba cekani na proces Launcher.exe.
if not defined TIMEOUT_LAUNCHER set "TIMEOUT_LAUNCHER=120"

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
