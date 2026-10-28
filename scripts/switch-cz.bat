@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM GTA V CZ/EN Switch - Czech Language Switch
REM ============================================================

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "PROJECT_DIR=%%~fI"

set "CORE_DIR=%PROJECT_DIR%\core"
set "CONFIG_DIR=%PROJECT_DIR%\config"

REM ------------------------------------------------------------
REM CONFIG
REM ------------------------------------------------------------

if not exist "%CONFIG_DIR%\config.bat" (
    echo CHYBA: Nenalezen config\config.bat.
    exit /b 1
)

call "%CONFIG_DIR%\config.bat"

REM ------------------------------------------------------------
REM LOGGER
REM ------------------------------------------------------------

if not exist "%CORE_DIR%\logger.bat" (
    echo CHYBA: Nenalezen core\logger.bat.
    exit /b 1
)

call "%CORE_DIR%\logger.bat" INFO "Spoustim modul prepnuti hry do cestiny." SCRIPT_START

REM ============================================================
REM HASH - AKTUALNI ZNAME VERZE
REM ============================================================

set "EN_UPDATE_HASH=C9D33098E144668BD8F66DDDF0438701"
set "EN_UPDATE2_HASH=722591439E22FB7248A375FA62DB12D7"

set "CZ_UPDATE_HASH=1332F7A0285811D1900EDC070BC0F209"
set "CZ_UPDATE2_HASH=1336BD4B5F9651C2C1F425655740AAE1"

REM ============================================================
REM CESTY
REM ============================================================

REM TODO:
REM Cestu ke hre a cestu ke zdroji cestiny zde nastavime podle
REM architektury projektu.

echo.
echo Modul switch-cz.bat je pripraven.
echo.

exit /b 0
