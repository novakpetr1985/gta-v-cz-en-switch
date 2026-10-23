@echo off
REM ============================================================
REM GTA V CZ/EN Switch - Logger
REM ============================================================
REM
REM Centrální modul pro logování celé aplikace.
REM
REM Tento soubor není určen ke spuštění jako samostatný program.
REM Jednotlivé části aplikace jej volají pomocí CALL a předávají
REM mu požadovanou logovací akci a případný text.
REM
REM Logger zajišťuje:
REM   - vytvoření identifikátoru běhu aplikace,
REM   - vytvoření samostatného logu pro každý běh,
REM   - průběžný zápis událostí,
REM   - barevný výpis důležitých zpráv do konzole,
REM   - měření celkové doby běhu,
REM   - měření doby jednotlivých kroků,
REM   - počítání dotazů / pollovacích cyklů,
REM   - zápis DEBUG informací pouze do logu,
REM   - vytvoření kopie posledního logu,
REM   - automatickou retenci starších logů.
REM
REM ------------------------------------------------------------
REM Umístění:
REM   core\logger.bat
REM
REM Logy:
REM   logs\
REM
REM Barevná paleta:
REM   core\colors.bat
REM
REM Použití:
REM   call "%CORE_DIR%\logger.bat" INFO "Text informace"
REM   call "%CORE_DIR%\logger.bat" INFO "Text" EVENT
REM   call "%CORE_DIR%\logger.bat" INFO "Text" EVENT F
REM   call "%CORE_DIR%\logger.bat" DEBUG "Debug informace"
REM   call "%CORE_DIR%\logger.bat" OK "Operace OK"
REM   call "%CORE_DIR%\logger.bat" WARN "Varování"
REM   call "%CORE_DIR%\logger.bat" ERR "Chyba"
REM   call "%CORE_DIR%\logger.bat" STEP "1/2" "Název kroku"
REM   call "%CORE_DIR%\logger.bat" STEP_END
REM   call "%CORE_DIR%\logger.bat" WAIT "Čekám..."
REM   call "%CORE_DIR%\logger.bat" CONTEXT "Kontext..."
REM   call "%CORE_DIR%\logger.bat" F "Pouze do logu"
REM   call "%CORE_DIR%\logger.bat" FINISH SUCCESS 0
REM
REM Parametr F znamená:
REM   - zpráva se zapíše do logu,
REM   - ale nebude zobrazena v konzoli.
REM
REM DEBUG a DETAIL mají obdobné chování:
REM   - zapisují se do logu,
REM   - standardně se nezobrazují v konzoli.
REM
REM ============================================================


REM ============================================================
REM PROMĚNNÉ DOSTUPNÉ VOLAJÍCÍMU
REM ============================================================
REM
REM Logger záměrně nepoužívá SETLOCAL: stav běhu (RUN_ID, časy,
REM počítadla) si musí pamatovat mezi jednotlivými voláními, a to
REM umí jen proměnné prostředí volajícího skriptu.
REM
REM Důsledek: po prvním volání jsou ve skriptu, který logger volá,
REM k dispozici i tyto proměnné:
REM
REM   RUN_ID       identifikátor běhu (YYYYMMDD-HHMMSS-fff-PID)
REM   RUN_LOG      úplná cesta k logu aktuálního běhu
REM   LOG_FILE     alias na RUN_LOG
REM   LATEST_LOG   úplná cesta ke kopii posledního dokončeného logu
REM   LOG_DIR      adresář s logy
REM   CORE_DIR     adresář core (s koncovým zpětným lomítkem)
REM   PROJECT_DIR  kořen projektu
REM   RESET, BOLD, BLUE, CYAN, GREEN, YELLOW, RED, GRAY, WHITE
REM                barvy načtené z colors.bat
REM
REM Skripty, které logger volají, tyto proměnné nemusí znovu
REM počítat ani načítat. Barevnou paletu stačí použít přímo.
REM
REM Pokud skript potřebuje, aby po jeho skončení v okně CMD nic
REM nezůstalo, použije na začátku SETLOCAL (jako testy loggeru).
REM
REM Pomocné proměnné loggeru začínají podtržítkem (_lvl, _ev, _d ...).
REM Jsou interní a volající je nemá používat.
REM ============================================================


REM ============================================================
REM INICIALIZACE
REM ============================================================
REM
REM Logger se inicializuje pouze při prvním volání.
REM
REM To je důležité proto, aby během jednoho běhu aplikace:
REM   - zůstal stejný RUN_ID,
REM   - všechny události šly do stejného RUN_LOG,
REM   - měření celkové doby používalo stejný SCRIPT_T0,
REM   - znovu se nevytvářela hlavička logu.
REM
REM Při dalších CALL se inicializace přeskočí a řízení pokračuje
REM přímo na dispatcher.
REM ------------------------------------------------------------

if defined LOGGER_INITIALIZED goto DISPATCH

REM Označení loggeru jako inicializovaného.
REM Díky tomu další volání nepřepisují stav aktuálního běhu.
set "LOGGER_INITIALIZED=1"

REM ------------------------------------------------------------
REM ZÁKLADNÍ CESTY
REM ------------------------------------------------------------
REM
REM %~dp0 = adresář tohoto logger.bat.
REM Logger se nachází v:
REM   <projekt>\core\
REM
REM Z něj se odvozuje:
REM   CORE_DIR    = adresář core
REM   PROJECT_DIR = kořen projektu
REM   LOG_DIR     = adresář s logy
REM ------------------------------------------------------------

REM Cesty se normalizují pomocí %%~fI. Pokud je logger zavolán přes
REM relativní cestu (například ...\tests\logger\..\..\core\logger.bat),
REM %~dp0 obsahuje i části "..". Bez normalizace by se tyto části
REM objevily ve všech odvozených cestách (RUN_LOG, LOG_DIR ...).
REM
REM CORE_DIR zůstává s koncovým zpětným lomítkem (používá se například
REM jako %CORE_DIR%colors.bat).

for %%I in ("%~dp0.") do set "CORE_DIR=%%~fI\"
set "LOGGER_DIR=%CORE_DIR%"
for %%I in ("%CORE_DIR%..") do set "PROJECT_DIR=%%~fI"
set "LOG_DIR=%PROJECT_DIR%\logs"


REM ------------------------------------------------------------
REM NAČTENÍ BAREVNÉ PALETY
REM ------------------------------------------------------------
REM
REM Barvy nejsou definovány přímo v loggeru.
REM Centrálně je poskytuje:
REM   core\colors.bat
REM
REM Logger tak používá stejnou barevnou paletu jako ostatní
REM části aplikace.
REM
REM Pokud colors.bat neexistuje, logger pokračuje bez jeho
REM načtení. Samotné logování tím není zastaveno.
REM ------------------------------------------------------------

if exist "%CORE_DIR%colors.bat" (
    call "%CORE_DIR%colors.bat"
)


REM ------------------------------------------------------------
REM VÝCHOZÍ KONFIGURACE
REM ------------------------------------------------------------
REM
REM LOG_KEEP:
REM   Počet jednotlivých běhů, které mají být zachovány.
REM   Výchozí hodnota je 30.
REM
REM LOG_LEVEL:
REM   Výchozí úroveň loggeru.
REM   Aktuálně je nastavena na INFO.
REM
REM Poznámka:
REM   LOG_LEVEL je připraven jako konfigurační hodnota pro další
REM   rozvoj loggeru. Aktuální logger ji nepoužívá jako filtr
REM   konzolových nebo logovacích zpráv.
REM ------------------------------------------------------------

if not defined LOG_KEEP set "LOG_KEEP=30"
if not defined LOG_LEVEL set "LOG_LEVEL=INFO"


REM ------------------------------------------------------------
REM LOG DIRECTORY
REM ------------------------------------------------------------
REM
REM Pokud adresář logs\ ještě neexistuje, logger jej automaticky
REM vytvoří.
REM
REM Díky tomu není nutné před prvním spuštěním ručně vytvářet
REM adresář pro logy.
REM ------------------------------------------------------------

if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%" >nul 2>&1
)


REM ------------------------------------------------------------
REM RUN ID, DATUM A ČASOVÁ ZÓNA
REM ------------------------------------------------------------
REM
REM Pro vytvoření identifikace běhu používáme PowerShell.
REM Důvodem je spolehlivé získání:
REM
REM   RUN_DATE:
REM     datum ve formátu YYYY-MM-DD
REM
REM   RUN_ID:
REM     identifikátor běhu ve formátu YYYYMMDD-HHMMSS-fff-PID
REM     (milisekundy a ID procesu PowerShellu zabraňují kolizi
REM     rychle po sobě nebo souběžně spuštěných běhů)
REM
REM   TZ_OFFSET:
REM     offset časové zóny, například +02:00
REM
REM PowerShell zde slouží pouze jako pomocný systémový nástroj
REM pro získání jednoznačnějšího času a data.
REM ------------------------------------------------------------

for /f "tokens=1,2,3" %%a in (
    'powershell -NoProfile -Command "$d=Get-Date; $d.ToString('yyyy-MM-dd')+' '+$d.ToString('yyyyMMdd-HHmmss-fff')+'-'+$PID+' '+$d.ToString('zzz')"'
) do (
    set "RUN_DATE=%%a"
    set "RUN_ID=%%b"
    set "TZ_OFFSET=%%c"
)


REM ------------------------------------------------------------
REM FALLBACK
REM ------------------------------------------------------------
REM
REM Pokud by se z nějakého důvodu nepodařilo získat údaje
REM pomocí PowerShellu, logger má připravené náhradní hodnoty.
REM
REM Cílem je, aby selhání získání času nezastavilo celé logování.
REM ------------------------------------------------------------

if not defined RUN_ID set "RUN_ID=run-%RANDOM%"
if not defined RUN_DATE set "RUN_DATE=%date%"
if not defined TZ_OFFSET set "TZ_OFFSET=?"


REM ------------------------------------------------------------
REM LOG SOUBORY
REM ------------------------------------------------------------
REM
REM RUN_LOG:
REM   hlavní log aktuálního běhu.
REM
REM Příklad:
REM   gta-v-cz-en-switch_20261023-030833-123-45678.log
REM
REM LOG_FILE:
REM   obecný alias na aktuální RUN_LOG.
REM
REM LATEST_LOG:
REM   kopie posledního dokončeného logu.
REM
REM LATEST_LOG umožňuje rychle otevřít poslední běh bez nutnosti
REM hledat nejnovější soubor podle názvu.
REM ------------------------------------------------------------

set "RUN_LOG=%LOG_DIR%\gta-v-cz-en-switch_%RUN_ID%.log"
set "LOG_FILE=%RUN_LOG%"
set "LATEST_LOG=%LOG_DIR%\gta-v-cz-en-switch-latest.log"


REM ------------------------------------------------------------
REM STAV BĚHU
REM ------------------------------------------------------------
REM
REM CUR_STEP:
REM   aktuální identifikátor kroku.
REM   Na začátku je INIT.
REM
REM STEP_NAME:
REM   textový název aktuálního kroku.
REM
REM STEP_T0:
REM   čas začátku měření aktuálního kroku.
REM
REM POLL_COUNT:
REM   počet dotazů / pollovacích cyklů zaznamenaných v aktuálním
REM   kroku.
REM
REM EXIT_CODE:
REM   návratový kód, který bude použit při dokončení běhu.
REM ------------------------------------------------------------

set "CUR_STEP=INIT"
set "STEP_NAME="
set "STEP_T0="
set "POLL_COUNT=0"
set "EXIT_CODE=0"


REM ------------------------------------------------------------
REM ČAS STARTU SKRIPTU
REM ------------------------------------------------------------
REM
REM SCRIPT_T0 obsahuje čas začátku celého běhu.
REM
REM Při FINISH se tento čas porovná s aktuálním časem a logger
REM vypočítá celkovou dobu běhu aplikace.
REM ------------------------------------------------------------

call :NOW_CS
set "SCRIPT_T0=%NOW_CS%"


REM ------------------------------------------------------------
REM HLAVIČKA LOGU
REM ------------------------------------------------------------
REM
REM Hlavička se vytvoří pouze pokud RUN_LOG ještě neexistuje.
REM
REM Obsahuje:
REM   - název aplikace,
REM   - ID běhu,
REM   - datum,
REM   - časovou zónu,
REM   - formát jednotlivých řádků,
REM   - seznam používaných logovacích úrovní.
REM
REM Poté se zapíše tlustý oddělovač.
REM ------------------------------------------------------------

if not exist "%RUN_LOG%" (
    >"%RUN_LOG%" echo # GTA V CZ/EN Switch - Logger
    >>"%RUN_LOG%" echo # ID behu: %RUN_ID%
    >>"%RUN_LOG%" echo # Datum: %RUN_DATE%
    >>"%RUN_LOG%" echo # Casova zona: UTC%TZ_OFFSET%
    >>"%RUN_LOG%" echo # Format: cas ^| uroven ^| id behu ^| krok ^| udalost ^| zprava
    >>"%RUN_LOG%" echo # Urovne: DEBUG, INFO, WARN, ERROR
    call :HR2
)


REM ============================================================
REM DISPATCHER
REM ============================================================
REM
REM Dispatcher rozhoduje, kterou interní část loggeru má dané
REM volání použít.
REM
REM První parametr určuje akci:
REM
REM   INFO      běžná informační zpráva
REM   OK        úspěšná operace
REM   WARN      varování
REM   ERR       chyba
REM   ERROR     chyba
REM   DETAIL    podrobná informace pouze do logu
REM   DEBUG     ladicí informace pouze do logu
REM   NL        prázdný řádek v konzoli
REM   STEP      začátek nového kroku
REM   STEP_END  ukončení aktuálního kroku
REM   FINISH    ukončení celého běhu
REM   WAIT      čekací / pollovací událost
REM   CONTEXT   kontextová informace
REM   F         zápis pouze do logu
REM   HR        tenký oddělovač
REM   HR2       tlustý oddělovač
REM   NOW_CS    získání aktuálního času v setinách sekundy
REM
REM Neznámá akce skončí ve :UNKNOWN.
REM ============================================================

:DISPATCH

if "%~1"=="" goto :EOF

if /I "%~1"=="INFO"     goto :P
if /I "%~1"=="OK"       goto :P
if /I "%~1"=="WARN"     goto :P
if /I "%~1"=="ERR"      goto :P
if /I "%~1"=="ERROR"    goto :P
if /I "%~1"=="DETAIL"   goto :P
if /I "%~1"=="DEBUG"    goto :P
if /I "%~1"=="NL"       goto :P

if /I "%~1"=="STEP"     goto :STEP
if /I "%~1"=="STEP_END" goto :STEP_END
if /I "%~1"=="FINISH"   goto :FINISH

if /I "%~1"=="WAIT"     goto :WAIT
if /I "%~1"=="CONTEXT"  goto :CONTEXT
if /I "%~1"=="F"        goto :LOG_ONLY

if /I "%~1"=="HR"       goto :HR
if /I "%~1"=="HR2"      goto :HR2
if /I "%~1"=="NOW_CS"   goto :NOW_CS

goto :UNKNOWN


REM ============================================================
REM :P
REM ============================================================
REM
REM Hlavní interní funkce pro zápis běžných logovacích zpráv.
REM
REM Obecný formát volání:
REM
REM   LEVEL "text"
REM   LEVEL "text" "EVENT"
REM   LEVEL "text" "EVENT" F
REM
REM Příklady:
REM
REM   call logger.bat INFO "Informace"
REM   call logger.bat WARN "Varování"
REM   call logger.bat ERR "Chyba"
REM   call logger.bat DEBUG "Debug informace"
REM   call logger.bat INFO "Kontrola dokončena" SUCCESS
REM   call logger.bat INFO "Pouze do logu" CONTEXT F
REM
REM F:
REM   zpráva se zapíše do logu, ale nezobrazí se v konzoli.
REM
REM DEBUG / DETAIL:
REM   zpráva se zapíše pouze do logu.
REM
REM Tato funkce zároveň:
REM   - převede vstupní úroveň na interní úroveň,
REM   - nastaví barvu konzole,
REM   - nastaví událost,
REM   - zapíše čas,
REM   - zapíše aktuální krok,
REM   - zapíše zprávu do RUN_LOG,
REM   - případně zobrazí zprávu v konzoli.
REM ============================================================

:P

REM Uložení požadované úrovně.
set "_lvl=%~1"


REM ------------------------------------------------------------
REM Prázdný řádek
REM ------------------------------------------------------------
REM
REM NL je speciální případ.
REM Zapíše pouze prázdný řádek do konzole a nepokračuje
REM do běžného logovacího zpracování.
REM ------------------------------------------------------------

if /I "%_lvl%"=="NL" (
    echo.
    exit /b 0
)


REM ------------------------------------------------------------
REM Výchozí hodnoty
REM ------------------------------------------------------------
REM
REM Pokud nebude vstup odpovídat žádné známé úrovni, používají
REM se tyto základní hodnoty.
REM
REM _ctag = textový štítek konzole
REM _col  = barva konzole
REM _flv  = skutečná úroveň uložená v logu
REM _ev   = výchozí typ události
REM ------------------------------------------------------------

set "_ctag=INFO "
set "_col=%CYAN%"
set "_flv=INFO"
set "_ev=GENERAL"


REM ------------------------------------------------------------
REM INFO
REM ------------------------------------------------------------
REM
REM Standardní informační zpráva.
REM
REM Konzole:
REM   INFO
REM
REM Log:
REM   INFO
REM
REM Výchozí událost:
REM   GENERAL
REM ------------------------------------------------------------

if /I "%_lvl%"=="INFO" (
    set "_ctag=INFO "
    set "_col=%CYAN%"
    set "_flv=INFO"
    set "_ev=GENERAL"
)


REM ------------------------------------------------------------
REM OK
REM ------------------------------------------------------------
REM
REM Úspěšná operace.
REM
REM Konzole:
REM   OK
REM
REM V logu se stále jedná o úroveň INFO, ale událost je
REM označena jako SUCCESS.
REM ------------------------------------------------------------

if /I "%_lvl%"=="OK" (
    set "_ctag=OK   "
    set "_col=%GREEN%"
    set "_flv=INFO"
    set "_ev=SUCCESS"
)


REM ------------------------------------------------------------
REM WARN
REM ------------------------------------------------------------
REM
REM Varování.
REM
REM Konzole:
REM   POZOR
REM
REM Log:
REM   WARN
REM
REM Událost:
REM   WARNING
REM ------------------------------------------------------------

if /I "%_lvl%"=="WARN" (
    set "_ctag=POZOR"
    set "_col=%YELLOW%"
    set "_flv=WARN"
    set "_ev=WARNING"
)


REM ------------------------------------------------------------
REM ERROR
REM ------------------------------------------------------------
REM
REM ERR i ERROR jsou dvě vstupní varianty stejné chybové úrovně.
REM
REM Obě:
REM   - zobrazí CHYBA,
REM   - použijí červenou barvu,
REM   - uloží ERROR,
REM   - nastaví událost ERROR.
REM ------------------------------------------------------------

if /I "%_lvl%"=="ERR" (
    set "_ctag=CHYBA"
    set "_col=%RED%"
    set "_flv=ERROR"
    set "_ev=ERROR"
)

if /I "%_lvl%"=="ERROR" (
    set "_ctag=CHYBA"
    set "_col=%RED%"
    set "_flv=ERROR"
    set "_ev=ERROR"
)


REM ------------------------------------------------------------
REM STEP
REM ------------------------------------------------------------
REM
REM STEP je speciální konzolový výpis používaný při začátku kroku.
REM
REM Konzole:
REM   STEP
REM
REM Barva:
REM   BOLD + BLUE
REM
REM Log:
REM   INFO
REM
REM Událost:
REM   STEP_START
REM
REM Samotné založení a měření kroku probíhá ve funkci :STEP.
REM ------------------------------------------------------------

if /I "%_lvl%"=="STEP" (
    set "_ctag=STEP "
    set "_col=%BOLD%%BLUE%"
    set "_flv=INFO"
    set "_ev=STEP_START"
)


REM ------------------------------------------------------------
REM DETAIL / DEBUG
REM ------------------------------------------------------------
REM
REM DETAIL i DEBUG jsou určeny pro technické informace.
REM
REM Obě:
REM   - používají úroveň DEBUG,
REM   - používají šedou barvu,
REM   - mají událost DETAIL,
REM   - nezobrazují se standardně v konzoli.
REM
REM Rozdíl mezi DETAIL a DEBUG je zachován jako rozhraní pro
REM volající části aplikace; interně mají stejné chování.
REM ------------------------------------------------------------

if /I "%_lvl%"=="DETAIL" (
    set "_ctag=DEBUG"
    set "_col=%GRAY%"
    set "_flv=DEBUG"
    set "_ev=DETAIL"
)

if /I "%_lvl%"=="DEBUG" (
    set "_ctag=DEBUG"
    set "_col=%GRAY%"
    set "_flv=DEBUG"
    set "_ev=DETAIL"
)


REM ------------------------------------------------------------
REM Volitelný EVENT
REM ------------------------------------------------------------
REM
REM Třetí parametr může přepsat výchozí typ události.
REM
REM Příklad:
REM   call logger.bat INFO "Čekám" WAIT
REM
REM Výsledná událost bude:
REM   WAIT
REM
REM Pokud třetí parametr není zadán, zůstane použita výchozí
REM událost nastavená podle úrovně.
REM ------------------------------------------------------------

if not "%~3"=="" set "_ev=%~3"

REM WAIT = jeden dotaz / pollovací cyklus.
REM
REM Každé volání:
REM   INFO "text" WAIT
REM
REM zvýší počet zaznamenaných dotazů v aktuálním kroku.
if /I "%~3"=="WAIT" set /a POLL_COUNT+=1


REM ------------------------------------------------------------
REM ČASOVÁ ZNAČKA
REM ------------------------------------------------------------
REM
REM Aktuální systémový čas se získá z proměnné %TIME%.
REM
REM Hodnota se upraví tak, aby byly hodiny vždy dvoumístné,
REM a následně se použije při sestavení řádku logu.
REM ------------------------------------------------------------

set "_ms=%time: =0%"


REM ------------------------------------------------------------
REM ZKRÁCENÝ IDENTIFIKÁTOR KROKU
REM ------------------------------------------------------------
REM
REM Do logu se zapisuje maximálně první 4 znaky CUR_STEP.
REM
REM Příklad:
REM   CUR_STEP=1/2
REM
REM Do logu:
REM   1/2
REM
REM Pro zachování pevné struktury se hodnota nejprve doplní
REM mezerami a následně zkrátí na 4 znaky.
REM ------------------------------------------------------------

set "_stp=%CUR_STEP%    "
set "_stp=%_stp:~0,4%"


REM ------------------------------------------------------------
REM ZÁPIS DO LOGU
REM ------------------------------------------------------------
REM
REM Každý běžný logovací řádek má formát:
REM
REM   datum čas | úroveň | ID běhu | krok | událost | zpráva
REM
REM
REM Příklad:
REM
REM   2026-10-23 03:08:33.69 | INFO | 20261023-030833-123-45678 | INIT | SCRIPT_START | Test loggeru byl spusten.
REM
REM
REM Zápis probíhá vždy do RUN_LOG.
REM ------------------------------------------------------------

REM Celý řádek se nejprve sestaví do proměnné uvnitř uvozovek, kde jsou
REM speciální znaky (ampersand, svislítko, menší, větší) neškodné.
REM Vypíše se přes zpožděnou expanzi, která obsah proměnné už dál
REM nevyhodnocuje. Zpožděná expanze je zapnutá jen lokálně
REM (SETLOCAL ... ENDLOCAL kolem jediného příkazu ECHO), takže stav
REM loggeru (POLL_COUNT, čas kroku apod.) tím není dotčen.
REM
REM Omezení: zpráva nesmí obsahovat dvojité uvozovky.
REM          Místo nich se používá apostrof.

set "_line=%RUN_DATE% %_ms:~0,8%.%_ms:~9,2% | %_flv% | %RUN_ID% | %_stp% | %_ev% | %~2"
setlocal EnableDelayedExpansion
>>"%RUN_LOG%" echo(!_line!
endlocal


REM ------------------------------------------------------------
REM F = POUZE DO LOGU
REM ------------------------------------------------------------
REM
REM Pokud je čtvrtý parametr F, logger po zápisu okamžitě skončí.
REM
REM Zpráva tedy:
REM   - zůstane v RUN_LOG,
REM   - nebude vypsána do konzole.
REM
REM Používá se například pro technické nebo závěrečné informace,
REM které není nutné zobrazovat uživateli.
REM ------------------------------------------------------------

if /I "%~4"=="F" exit /b 0


REM ------------------------------------------------------------
REM DEBUG / DETAIL = POUZE DO LOGU
REM ------------------------------------------------------------
REM
REM DEBUG a DETAIL jsou určeny pro podrobné diagnostické údaje.
REM
REM Tyto zprávy jsou záměrně skryté z konzole, aby běžný chod
REM aplikace nebyl zahlcen technickými informacemi.
REM ------------------------------------------------------------

if /I "%_lvl%"=="DETAIL" exit /b 0
if /I "%_lvl%"=="DEBUG" exit /b 0


REM ------------------------------------------------------------
REM BĚŽNÝ KONZOLOVÝ VÝPIS
REM ------------------------------------------------------------
REM
REM Všechny ostatní běžné úrovně se zobrazí s odpovídajícím
REM barevným štítkem.
REM
REM RESET je důležitý, aby barva loggeru nezůstala aktivní
REM i pro následující text vypisovaný jinou částí aplikace.
REM ------------------------------------------------------------

REM Výpis používá stejnou bezpečnou techniku jako zápis do logu,
REM aby speciální znaky ve zprávě nic nespustily ani nerozbily.
REM STEP používá stejný výpis, jen s jiným štítkem a barvou
REM nastavenými výše podle úrovně.

set "_cline=%_col%%_ctag%%RESET% %~2"
setlocal EnableDelayedExpansion
echo(!_cline!
endlocal

exit /b 0


REM ============================================================
REM :STEP
REM ============================================================
REM
REM Zahájení nového měřeného kroku.
REM
REM Použití:
REM
REM   call logger.bat STEP "1/2" "Název kroku"
REM
REM
REM Postup:
REM   1. Automaticky uzavře předchozí krok.
REM   2. Nastaví nový identifikátor kroku.
REM   3. Nastaví název kroku.
REM   4. Vynuluje počítadlo WAIT/POLL.
REM   5. Uloží počáteční čas kroku.
REM   6. Vypíše oddělovač.
REM   7. Zapíše STEP_START do logu.
REM
REM Díky automatickému uzavření předchozího kroku nemusí volající
REM skript před každým novým STEP ručně provádět STEP_END.
REM ============================================================

:STEP

REM Pokud je aktivní předchozí krok, nejprve jej uzavřeme.
call :STEP_END

REM Nastavení identifikátoru a názvu nového kroku.
set "CUR_STEP=%~2"
set "STEP_NAME=%~3"

REM Každý nový krok začíná s nulovým počtem pollovacích dotazů.
set "POLL_COUNT=0"

REM Uložení času začátku měření nového kroku.
call :NOW_CS
set "STEP_T0=%NOW_CS%"

echo.
call :HR

REM Zápis začátku kroku.
call :P STEP "[%~2] %~3"

exit /b 0


REM ============================================================
REM :STEP_END
REM ============================================================
REM
REM Uzavření aktuálního kroku.
REM
REM Pokud není aktivní měření STEP_T0, funkce nic neudělá.
REM
REM Při ukončení se:
REM   - získá aktuální čas,
REM   - vypočítá délka kroku,
REM   - převede čas na sekundy a setiny,
REM   - zapíše počet pollovacích dotazů,
REM   - uloží výsledek jako DEBUG / STEP_END,
REM   - deaktivuje měření kroku.
REM
REM Výsledek například:
REM
REM   Krok Test mereni kroku trval 3,27 s, dotazu na log: 1.
REM ============================================================

:STEP_END

REM Pokud není aktivní čas začátku kroku, není co uzavírat.
if not defined STEP_T0 exit /b 0

REM Získání aktuálního času.
call :NOW_CS

REM Výpočet rozdílu mezi koncem a začátkem kroku.
set /a "_d=NOW_CS-STEP_T0"

REM Ošetření přechodu přes půlnoc.
REM Pokud je výsledek záporný, přičte se délka celého dne
REM vyjádřená v setinách sekundy.
if %_d% LSS 0 (
    set /a "_d+=8640000"
)

REM Převod celkové hodnoty setin na celé sekundy.
set /a "_s=_d/100"

REM Získání zbývajících setin sekundy.
set /a "_c=_d%%100"

REM Jednociferné setiny doplníme nulou.
REM Například:
REM   3 -> 03
if %_c% LSS 10 set "_c=0%_c%"

REM Výsledek zapíšeme pouze do logu jako DETAIL / DEBUG.
REM Událost je STEP_END.
call :P DETAIL "Krok %STEP_NAME% trval %_s%,%_c% s, dotazu na log: %POLL_COUNT%." STEP_END

REM Deaktivace měření aktuálního kroku.
set "STEP_T0="

exit /b 0


REM ============================================================
REM :WAIT
REM ============================================================
REM
REM Záznam čekání nebo pollovacího cyklu.
REM
REM Použití:
REM
REM   call logger.bat WAIT "Čekám na dokončení..."
REM
REM
REM WAIT je zpracován přes :P jako:
REM   INFO + EVENT WAIT
REM
REM Funkce :P zároveň automaticky zvýší POLL_COUNT.
REM
REM Počítadlo se tak zvyšuje právě jednou za jedno volání WAIT.
REM ============================================================

:WAIT

call :P INFO "%~2" WAIT

exit /b 0


REM ============================================================
REM :CONTEXT
REM ============================================================
REM
REM Zápis kontextové informace.
REM
REM Použití:
REM
REM   call logger.bat CONTEXT "Aktuální stav..."
REM
REM Kontext se ukládá jako INFO s událostí CONTEXT.
REM ============================================================

:CONTEXT

call :P INFO "%~2" CONTEXT

exit /b 0


REM ============================================================
REM :LOG_ONLY
REM ============================================================
REM
REM Zápis informace pouze do logu.
REM
REM Použití:
REM
REM   call logger.bat F "Technická informace"
REM
REM Funkce interně použije:
REM   INFO + GENERAL + F
REM
REM Čtvrtý parametr F zajistí, že po zápisu nedojde
REM ke konzolovému výpisu.
REM ============================================================

:LOG_ONLY

call :P INFO "%~2" GENERAL F

exit /b 0


REM ============================================================
REM :FINISH
REM ============================================================
REM
REM Ukončení celého běhu loggeru.
REM
REM Použití:
REM
REM   call logger.bat FINISH SUCCESS 0
REM   call logger.bat FINISH FAILURE 1
REM
REM Parametry:
REM   %~2 = výsledek běhu
REM   %~3 = návratový kód
REM
REM Funkce:
REM   0. uzavře případně otevřený krok (STEP_END),
REM   1. uloží výsledek a návratový kód,
REM   2. vypočítá celkovou dobu běhu,
REM   3. zapíše SCRIPT_END,
REM   4. nastaví stav CUR_STEP=END,
REM   5. zapíše závěrečný oddělovač,
REM   6. aktualizuje gta-v-cz-en-switch-latest.log,
REM   7. provede retenci starých logů.
REM ============================================================

:FINISH

REM Pokud je rozpracovaný krok, nejprve ho uzavřeme, aby jeho doba
REM a počet dotazů nezůstaly nezaznamenané.
call :STEP_END

REM Uložení výsledku běhu.
set "FINISH_STATUS=%~2"
set "EXIT_CODE=%~3"

REM Pokud návratový kód nebyl zadán, použije se 0.
if not defined EXIT_CODE set "EXIT_CODE=0"


REM ------------------------------------------------------------
REM Celkový čas
REM ------------------------------------------------------------
REM
REM SCRIPT_T0 obsahuje čas začátku celého běhu.
REM Z aktuálního času se vypočítá celková délka.
REM ------------------------------------------------------------

call :NOW_CS

set /a "_d=NOW_CS-SCRIPT_T0"

REM Ošetření přechodu přes půlnoc.
if %_d% LSS 0 (
    set /a "_d+=8640000"
)

REM Převod na sekundy.
set /a "_s=_d/100"

REM Získání setin sekundy.
set /a "_c=_d%%100"

REM Jednociferné setiny doplníme nulou.
if %_c% LSS 10 set "_c=0%_c%"


REM ------------------------------------------------------------
REM Výsledek
REM ------------------------------------------------------------
REM
REM SUCCESS:
REM   zapisuje INFO + SCRIPT_END.
REM
REM FAILURE:
REM   zapisuje ERROR + SCRIPT_END.
REM
REM Čtvrtý parametr F zajišťuje, že tato technická závěrečná
REM zpráva nebude zobrazena v konzoli.
REM
REM Výsledný záznam obsahuje:
REM   - výsledek,
REM   - návratový kód,
REM   - celkovou dobu běhu.
REM ------------------------------------------------------------

if /I "%FINISH_STATUS%"=="SUCCESS" (

    call :P INFO "vysledek=SUCCESS kod=%EXIT_CODE% doba=%_s%,%_c% s" SCRIPT_END F

) else (

    call :P ERR "vysledek=FAILURE kod=%EXIT_CODE% doba=%_s%,%_c% s" SCRIPT_END F

)


REM ------------------------------------------------------------
REM Ukončení běhu
REM ------------------------------------------------------------
REM
REM Po zapsání SCRIPT_END je aktuální stav nastaven na END.
REM Následuje tlustý oddělovač, který vizuálně ukončuje aktuální
REM log.
REM ------------------------------------------------------------

set "CUR_STEP=END"

call :HR2


REM ------------------------------------------------------------
REM LATEST LOG
REM ------------------------------------------------------------
REM
REM RUN_LOG je konkrétní log aktuálního běhu.
REM
REM LATEST_LOG je jeho kopie:
REM   gta-v-cz-en-switch-latest.log
REM
REM Díky tomu lze vždy rychle otevřít poslední dokončený běh.
REM ------------------------------------------------------------

if exist "%RUN_LOG%" (
    copy /Y "%RUN_LOG%" "%LATEST_LOG%" >nul 2>&1
)


REM ------------------------------------------------------------
REM LOG RETENTION
REM ------------------------------------------------------------
REM
REM Retence udržuje pouze posledních LOG_KEEP run logů.
REM
REM Výchozí hodnota:
REM   30
REM
REM Starší soubory jsou odstraněny.
REM
REM Poznámka:
REM   gta-v-cz-en-switch-latest.log je zamýšlen jako samostatná kopie posledního
REM   logu a není určen jako samostatný run log. Má v názvu pomlčku
REM   místo podtržítka, takže ho vzor gta-v-cz-en-switch_*.log
REM   v retenci nezachytí a nezabírá místo mezi LOG_KEEP běhy.
REM ------------------------------------------------------------

call :CLEANUP_LOGS


REM ------------------------------------------------------------
REM Konec loggeru
REM ------------------------------------------------------------
REM
REM Logger je po FINISH dokončen.
REM Volající skript si může podle vlastního návrhu ponechat
REM odpovědnost za skutečný EXIT / návratový kód aplikace.
REM ------------------------------------------------------------

exit /b 0


REM ============================================================
REM :HR
REM ============================================================
REM
REM Zápis tenkého oddělovače do aktuálního logu.
REM
REM Používá se například při přechodu mezi jednotlivými kroky.
REM ============================================================

:HR

>>"%RUN_LOG%" echo ----------------------------------------------------------------

exit /b 0


REM ============================================================
REM :HR2
REM ============================================================
REM
REM Zápis tlustého oddělovače do aktuálního logu.
REM
REM Používá se:
REM   - při vytvoření hlavičky logu,
REM   - při ukončení celého běhu.
REM ============================================================

:HR2

>>"%RUN_LOG%" echo ================================================================

exit /b 0


REM ============================================================
REM :NOW_CS
REM ============================================================
REM
REM Získání aktuálního času v setinách sekundy od půlnoci.
REM
REM Výsledná hodnota je určena především pro měření časových
REM intervalů:
REM
REM   SCRIPT_T0 -> celková doba běhu
REM   STEP_T0   -> doba aktuálního kroku
REM
REM Převod na setiny umožňuje přesnější měření než celé sekundy.
REM ============================================================

:NOW_CS

REM Načtení aktuálního času.
REM Odstranění případné úvodní mezery u hodin.
set "_t=%time: =0%"

REM Převod:
REM   hodiny -> sekundy
REM   minuty -> sekundy
REM   sekundy -> setiny
REM
REM Výsledkem je počet setin sekundy od půlnoci.
set /a NOW_CS=((1%_t:~0,2%-100)*3600+(1%_t:~3,2%-100)*60+(1%_t:~6,2%-100))*100+(1%_t:~9,2%-100)

exit /b 0


REM ============================================================
REM :CLEANUP_LOGS
REM ============================================================
REM
REM Automatická retence logů.
REM
REM LOG_KEEP určuje, kolik nejnovějších souborů se má ponechat.
REM
REM Příkladem při:
REM   LOG_KEEP=30
REM
REM zůstane 30 nejnovějších souborů odpovídajících vzoru:
REM   gta-v-cz-en-switch_*.log
REM
REM Starší soubory jsou odstraněny.
REM
REM Řazení /o-n:
REM   - podle názvu sestupně (RUN_ID = YYYYMMDD-HHMMSS-fff-PID),
REM   - nejnovější soubor je první,
REM   - řazení nezávisí na časovém razítku souboru.
REM
REM skip=%LOG_KEEP%:
REM   - prvních LOG_KEEP souborů přeskočí,
REM   - všechny další odstraní.
REM ============================================================

:CLEANUP_LOGS

REM Pokud není LOG_KEEP nastaveno, použije se výchozí hodnota.
if not defined LOG_KEEP set "LOG_KEEP=30"

REM Získání seznamu logů seřazeného od nejnovějšího.
REM
REM Prvních LOG_KEEP souborů se přeskočí.
REM Každý další soubor je následně odstraněn.
for /f "skip=%LOG_KEEP% delims=" %%F in (
    'dir /b /o-n "%LOG_DIR%\gta-v-cz-en-switch_*.log" 2^>nul'
) do (
    del /q "%LOG_DIR%\%%F" >nul 2>&1
)

exit /b 0


REM ============================================================
REM :UNKNOWN
REM ============================================================
REM
REM Tato část se použije v případě, že dispatcher obdrží
REM neznámou akci.
REM
REM Místo tichého selhání se vytvoří chybový záznam do logu.
REM ============================================================

:UNKNOWN

call :P ERR "Neznama logger akce: %~1" LOGGER_ERROR

exit /b 0


REM ============================================================
REM KONEC MODULU
REM ============================================================
REM
REM Tento bod slouží jako bezpečný konec souboru.
REM
REM Interní CALL mohou používat jednotlivé labely výše, zatímco
REM běžný průchod souborem je ukončen zde.
REM ============================================================

:EOF

exit /b 0
