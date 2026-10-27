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

REM Adresar s launcher.log Rockstar Games Launcheru.
REM Standardne <Dokumenty>\Rockstar Games\Launcher. Cesta k Dokumentum
REM se zjisti ze systemu, aby fungovala i s presmerovanymi slozkami
REM (OneDrive). Predem nastavena hodnota se neprepisuje.
if not defined ROCKSTAR_LOG_DIR (
    for /f "delims=" %%D in ('powershell -NoProfile -Command "[Environment]::GetFolderPath('MyDocuments')"') do set "ROCKSTAR_LOG_DIR=%%D\Rockstar Games\Launcher"
)
if not defined ROCKSTAR_LOG_DIR set "ROCKSTAR_LOG_DIR=%USERPROFILE%\Documents\Rockstar Games\Launcher"


REM ============================================================
REM KONEC MODULU
REM ============================================================

exit /b 0
