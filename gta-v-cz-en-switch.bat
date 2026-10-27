@echo off
setlocal EnableExtensions

REM ============================================================
REM GTA V CZ/EN SWITCH
REM Hlavní vstupní bod nástroje
REM ============================================================

REM ------------------------------------------------------------
REM PROJECT ROOT
REM ------------------------------------------------------------

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"


REM ------------------------------------------------------------
REM CORE / CONFIG
REM ------------------------------------------------------------

set "CONFIG_FILE=%PROJECT_DIR%\config\config.bat"
set "LOGGER_FILE=%PROJECT_DIR%\core\logger.bat"
set "UIA_FILE=%PROJECT_DIR%\scripts\uia.bat"


REM ------------------------------------------------------------
REM KONTROLA MODULŮ
REM ------------------------------------------------------------

if not exist "%CONFIG_FILE%" (
    echo [ERROR] Nenalezen config: %CONFIG_FILE%
    exit /b 1
)

if not exist "%LOGGER_FILE%" (
    echo [ERROR] Nenalezen logger: %LOGGER_FILE%
    exit /b 1
)

if not exist "%UIA_FILE%" (
    echo [ERROR] Nenalezen UIA modul: %UIA_FILE%
    exit /b 1
)


REM ------------------------------------------------------------
REM CONFIG
REM ------------------------------------------------------------

call "%CONFIG_FILE%"


REM ------------------------------------------------------------
REM LOGGER
REM ------------------------------------------------------------

call "%LOGGER_FILE%"


REM ------------------------------------------------------------
REM START
REM ------------------------------------------------------------

call "%LOGGER_FILE%" STEP "1/1" "UI Automation test"

call "%LOGGER_FILE%" INFO "Spoustim UI Automation modul."


REM ------------------------------------------------------------
REM UIA
REM ------------------------------------------------------------

set "UIA_MODE=invoke"
set "UIA_NAMES=PLAY"
set "UIA_REGEX="
set "UIA_NAV="

call "%UIA_FILE%"

set "UIA_EXIT_CODE=%ERRORLEVEL%"


REM ------------------------------------------------------------
REM VÝSLEDEK
REM ------------------------------------------------------------

if "%UIA_EXIT_CODE%"=="0" (

    call "%LOGGER_FILE%" OK "UI Automation modul dokoncen uspesne."

    call "%LOGGER_FILE%" FINISH SUCCESS 0

    endlocal
    exit /b 0

) else (

    call "%LOGGER_FILE%" ERROR "UI Automation modul skoncil s kodem %UIA_EXIT_CODE%."

    call "%LOGGER_FILE%" FINISH FAILURE %UIA_EXIT_CODE%

    endlocal
    exit /b %UIA_EXIT_CODE%

)
