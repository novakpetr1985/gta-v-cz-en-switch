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
REM KONEC MODULU
REM ============================================================

exit /b 0
