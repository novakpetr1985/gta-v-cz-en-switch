@echo off
REM ============================================================
REM GTA V CZ/EN Switch - Color Palette
REM ============================================================

REM ------------------------------------------------------------
REM BAREVNÁ PALETA
REM ANSI escape sekvence - světlé varianty pro tmavé pozadí
REM ------------------------------------------------------------

REM ------------------------------------------------------------
REM Význam barev ve výpisech
REM ------------------------------------------------------------
REM BLUE   (94) - nadpisy kroků
REM CYAN   (96) - běžné informace
REM GREEN  (92) - úspěch
REM YELLOW (93) - varování a upozornění
REM RED    (91) - chyba
REM GRAY   (90) - vedlejší údaje, čas, podrobnosti
REM WHITE  (97) - standardní světlý text a zvýraznění
REM ------------------------------------------------------------
REM Formátovací atributy
REM ------------------------------------------------------------
REM BOLD   (1)  - tučné zvýraznění
REM RESET  (0)  - návrat na výchozí formátování
REM ------------------------------------------------------------

REM ------------------------------------------------------------
REM Inicializace ANSI escape sekvence
REM Znak ESC se získá z promptu CMD pomocí kódu $E.
REM ------------------------------------------------------------

for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

REM ------------------------------------------------------------
REM Základní formátování
REM ------------------------------------------------------------

set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"

REM ------------------------------------------------------------
REM Barvy popředí - světlé varianty
REM ------------------------------------------------------------

set "BLUE=%ESC%[94m"
set "CYAN=%ESC%[96m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "GRAY=%ESC%[90m"
set "WHITE=%ESC%[97m"
