@echo off
setlocal EnableExtensions

REM ============================================================
REM GTA V CZ/EN Switch - Test Loggeru (SUCCESS)
REM ============================================================
REM
REM Ověřuje centrální logger:
REM     core\logger.bat
REM
REM Umístění testu:
REM     tests\logger\test-logger-success.bat
REM
REM ------------------------------------------------------------
REM CO TEST DĚLÁ
REM ------------------------------------------------------------
REM
REM   1. Zavolá logger se všemi veřejnými příkazy
REM      (INFO, DEBUG, OK, WARN, ERR, STEP, STEP_END, WAIT-událost,
REM      CONTEXT, F, FINISH) a se speciálními znaky ve zprávě.
REM   2. Po FINISH automaticky zkontroluje obsah logu (RUN_LOG)
REM      i kopii posledního logu (LATEST_LOG).
REM   3. Vrátí návratový kód:
REM          0 = všechny kontroly prošly,
REM          1 = některá kontrola selhala nebo chybí logger.
REM
REM Test sám žádnou logiku logování neobsahuje. Cesty a stav běhu
REM (RUN_LOG, LATEST_LOG, RUN_ID) poskytuje logger a test je po
REM prvním volání loggeru jen používá. Nic si nepočítá znovu.
REM
REM ------------------------------------------------------------
REM PROČ TEST VIDÍ PROMĚNNÉ LOGGERU
REM ------------------------------------------------------------
REM
REM Logger nepoužívá SETLOCAL, protože si stav běhu (RUN_ID,
REM časy, počítadla) drží v proměnných prostředí mezi voláními.
REM Po prvním CALL jsou proto v tomto testu k dispozici i:
REM     RUN_ID, RUN_LOG, LATEST_LOG, LOG_DIR, CORE_DIR
REM     a barvy z colors.bat (RED, GREEN, RESET ...).
REM
REM SETLOCAL na začátku testu zajistí, že se tyto proměnné po
REM skončení testu neprojeví v okně CMD, ze kterého byl spuštěn.
REM
REM ------------------------------------------------------------
REM SPUŠTĚNÍ
REM ------------------------------------------------------------
REM
REM   Běžně (s pauzou na konci):
REM       tests\logger\test-logger-success.bat
REM
REM   Bez pauzy (například pro automatické spuštění):
REM       set NOPAUSE=1
REM
REM ------------------------------------------------------------
REM CO NELZE OVĚŘIT AUTOMATICKY
REM ------------------------------------------------------------
REM
REM Výstup konzole se nezachytává, proto se automaticky neověřuje,
REM že DEBUG a zprávy s parametrem F nejsou v konzoli vidět.
REM To je nutné zkontrolovat okem při běhu testu: na obrazovce
REM se nesmí objevit řádky "Toto je DEBUG zprava.",
REM "Test DEBUG uvnitr kroku." ani "Tato zprava bude pouze v logu.".
REM
REM ============================================================


REM ------------------------------------------------------------
REM CESTA K TESTOVANÉMU LOGGERU
REM ------------------------------------------------------------
REM
REM %~dp0 je adresář tohoto testu (tests\logger\). Cesta k loggeru
REM vede o dvě úrovně výš a pak do core\.
REM
REM Cyklus FOR s %%~fI převede cestu na úplnou a normalizovanou
REM (bez částí "..").
REM
REM Proměnná se jmenuje LOGGER záměrně, aby se nepletla s proměnnými
REM CORE_DIR a LOG_DIR, které logger po inicializaci sám nastavuje.
REM ------------------------------------------------------------

for %%I in ("%~dp0..\..\core\logger.bat") do set "LOGGER=%%~fI"

REM Počítadlo selhaných kontrol. Zvyšují ho pomocné funkce níže.
set "FAILS=0"


REM ------------------------------------------------------------
REM KONTROLA EXISTENCE LOGGERU
REM ------------------------------------------------------------
REM
REM Bez loggeru nemá smysl test spouštět. Chybějící testovaný modul
REM se tak odliší od chyby v testu samotném.
REM
REM Pauza se přeskočí, je-li nastavena proměnná NOPAUSE.
REM ------------------------------------------------------------

if not exist "%LOGGER%" (
    echo.
    echo ============================================================
    echo CHYBA: Logger nebyl nalezen.
    echo ============================================================
    echo.
    echo Ocekavana cesta:
    echo %LOGGER%
    echo.
    if not defined NOPAUSE pause
    exit /b 1
)

echo.
echo ============================================================
echo TEST LOGGERU - SUCCESS
echo ============================================================
echo.


REM ============================================================
REM ZÁKLADNÍ LOGOVACÍ UDÁLOSTI
REM ============================================================
REM
REM Pořadí parametrů při volání loggeru:
REM     UROVEŇ  "zpráva"  [UDÁLOST]  [F]
REM
REM   INFO + SCRIPT_START  začátek běhu (krok je zatím INIT)
REM   DEBUG                jen do logu, v konzoli se nezobrazí
REM   INFO + CONFIG        běžná informace s vlastní událostí
REM   OK                   v logu úroveň INFO a událost SUCCESS
REM   WARN                 v logu úroveň WARN, v konzoli POZOR
REM   ERR                  v logu úroveň ERROR, v konzoli CHYBA
REM ============================================================

call "%LOGGER%" INFO "Test loggeru byl spusten." SCRIPT_START
call "%LOGGER%" DEBUG "Toto je DEBUG zprava." ENV
call "%LOGGER%" INFO "Toto je INFO zprava." CONFIG
call "%LOGGER%" OK "Test uspesne pokracuje."
call "%LOGGER%" WARN "Toto je testovaci varovani."
call "%LOGGER%" ERR "Toto je testovaci chyba."

REM ------------------------------------------------------------
REM SPECIÁLNÍ ZNAKY VE ZPRÁVĚ
REM ------------------------------------------------------------
REM
REM Znaky ampersand, svislítko, menší, větší a vykřičník by dříve
REM mohly rozbít zápis do logu nebo spustit cizí příkaz. Logger je
REM nyní zapisuje bezpečně a test ověří, že se do logu dostala celá
REM zpráva.
REM
REM Znak ^ se záměrně netestuje: příkaz CALL jej zdvojuje.
REM Dvojité uvozovky ve zprávě se nepoužívají (omezení loggeru).
REM ------------------------------------------------------------

call "%LOGGER%" INFO "Znaky & | < > ! v textu." SPECIAL


REM ============================================================
REM KROK 1/2 (očekávaný počet dotazů na log: 1)
REM ============================================================
REM
REM STEP uloží čas začátku kroku, vynuluje počítadlo WAIT a zapíše
REM STEP_START. Následný STEP_END zapíše dobu trvání a počet WAIT.
REM
REM Krátké čekání přes PowerShell slouží k tomu, aby měřená doba
REM kroku nebyla nulová. Na rozdíl od timeout funguje i tehdy,
REM když test běží s přesměrovaným vstupem v automatizaci.
REM ============================================================

call "%LOGGER%" STEP "1/2" "Test mereni kroku"
powershell -NoProfile -Command "Start-Sleep -Seconds 2" >nul

REM INFO s událostí WAIT zvýší počítadlo dotazů v aktuálním kroku.
call "%LOGGER%" INFO "Krok probiha." WAIT

REM DEBUG uvnitř kroku: musí se zapsat do logu, ne do konzole.
call "%LOGGER%" DEBUG "Test DEBUG uvnitr kroku." CONTEXT

powershell -NoProfile -Command "Start-Sleep -Seconds 1" >nul

REM STEP_END uzavře krok a zapíše:
REM     "Krok ... trval X,XX s, dotazu na log: 1."
call "%LOGGER%" STEP_END


REM ============================================================
REM KROK 2/2 (očekávaný počet dotazů na log: 0)
REM ============================================================
REM
REM Druhý krok neobsahuje žádný WAIT, takže počítadlo musí být
REM znovu vynulované a ve výsledku se objeví "dotazu na log: 0.".
REM ============================================================

call "%LOGGER%" STEP "2/2" "Test druheho kroku"
powershell -NoProfile -Command "Start-Sleep -Seconds 1" >nul
call "%LOGGER%" INFO "Druhy krok dokoncen." SUCCESS

REM ------------------------------------------------------------
REM STEP_END ZÁMĚRNĚ CHYBÍ
REM ------------------------------------------------------------
REM
REM FINISH musí rozpracovaný krok uzavřít sám. Test to ověří
REM kontrolou, že se v logu objevilo trvání druhého kroku.
REM ------------------------------------------------------------


REM ------------------------------------------------------------
REM F = POUZE DO LOGU
REM ------------------------------------------------------------
REM
REM Čtvrtý parametr F: zpráva se zapíše do logu, ale v konzoli
REM se nezobrazí.
REM ------------------------------------------------------------

call "%LOGGER%" INFO "Tato zprava bude pouze v logu." CONTEXT F


REM ------------------------------------------------------------
REM UKONČENÍ BĚHU
REM ------------------------------------------------------------
REM
REM FINISH SUCCESS 0:
REM     - uzavře případný otevřený krok,
REM     - vypočítá celkovou dobu běhu,
REM     - zapíše SCRIPT_END s výsledkem a návratovým kódem,
REM     - zkopíruje log do LATEST_LOG,
REM     - provede retenci starých logů.
REM ------------------------------------------------------------

call "%LOGGER%" FINISH SUCCESS 0


REM ============================================================
REM AUTOMATICKÁ KONTROLA LOGU
REM ============================================================
REM
REM Od této chvíle jsou díky loggeru k dispozici proměnné RUN_LOG,
REM LATEST_LOG a RUN_ID. Každá kontrola hledá doslovný text
REM v logu (viz funkce :ASSERT_HAS na konci souboru).
REM ============================================================

echo.
echo ------------------------------------------------------------
echo KONTROLA LOGU
echo ------------------------------------------------------------
echo.

REM Začátek a konec běhu.
call :ASSERT_HAS "SCRIPT_START" "| SCRIPT_START |"
call :ASSERT_HAS "SCRIPT_END" "| SCRIPT_END |"
call :ASSERT_HAS "vysledek SUCCESS, kod 0" "vysledek=SUCCESS kod=0"

REM DEBUG musí být v logu (v konzoli ne, to test neověří).
call :ASSERT_HAS "DEBUG je v logu" "Toto je DEBUG zprava."
call :ASSERT_HAS "DEBUG v kroku je v logu" "Test DEBUG uvnitr kroku."

REM Úrovně a mapování OK na událost SUCCESS.
call :ASSERT_HAS "uroven WARN" "| WARN |"
call :ASSERT_HAS "uroven ERROR" "| ERROR |"
call :ASSERT_HAS "OK je mapovano na SUCCESS" "| SUCCESS |"

REM Zpráva zapsaná pouze do logu (parametr F).
call :ASSERT_HAS "zprava s F je v logu" "Tato zprava bude pouze v logu."

REM Měření kroků a počítadlo WAIT.
call :ASSERT_HAS "krok 1: doba kroku" "Test mereni kroku trval"
call :ASSERT_HAS "krok 1: pocet WAIT = 1" "dotazu na log: 1."
call :ASSERT_HAS "krok 2 uzavren pri FINISH" "Test druheho kroku trval"
call :ASSERT_HAS "krok 2: pocet WAIT = 0" "dotazu na log: 0."

REM Speciální znaky musí být zapsané celé.
call :ASSERT_HAS "specialni znaky zapsany cele" "Znaky & | < > ! v textu."

REM Kopie posledního logu.
call :ASSERT_LATEST_HAS_RUN


REM ============================================================
REM VÝSLEDEK TESTU
REM ============================================================
REM
REM RESULT je návratový kód testu: 0 = vše v pořádku, 1 = chyba.
REM Barvy (GREEN, RED, RESET) pocházejí z colors.bat, který načetl
REM logger. Kdyby chyběly, výpis je jen bez barev.
REM ============================================================

set "RESULT=0"
if %FAILS% GTR 0 set "RESULT=1"

echo.
echo ============================================================
if %RESULT%==0 (
    echo TEST DOKONCEN - VSE V PORADKU
) else (
    echo %RED%TEST SELHAL - pocet chyb: %FAILS%%RESET%
)
echo ============================================================
echo.

REM Cesta k logu pochází přímo z loggeru (RUN_LOG), test ji
REM neskládá sám.
echo Log najdes v:
echo %RUN_LOG%
echo.

if not defined NOPAUSE pause

REM ------------------------------------------------------------
REM UKONČENÍ TESTU
REM ------------------------------------------------------------
REM
REM Příkaz ENDLOCAL spojený s EXIT na jednom řádku funguje takto:
REM příkazový řádek se nejprve celý rozvine (proměnná RESULT dostane
REM svou hodnotu), teprve poté se provede endlocal a exit. Hodnota
REM RESULT se tak dostane i za hranici SETLOCAL jako návratový kód.
REM ------------------------------------------------------------

endlocal & exit /b %RESULT%


REM ============================================================
REM POMOCNÉ FUNKCE TESTU
REM ============================================================
REM
REM Funkce se volají příkazem CALL :NÁZEV. Hlavní část testu končí
REM výše příkazem EXIT, takže se do této části nikdy nedostane
REM běžným průchodem.
REM ============================================================


REM ------------------------------------------------------------
REM :ASSERT_HAS "popis" "hledaný text"
REM ------------------------------------------------------------
REM
REM Zkontroluje, že RUN_LOG obsahuje hledaný text.
REM
REM Parametry:
REM     %1 = popis kontroly (zobrazí se v konzoli)
REM     %2 = hledaný text i s uvozovkami
REM
REM Přepínače FINDSTR:
REM     /l      doslovné hledání (ne regulární výraz)
REM     /c:     celý text včetně mezer jako jeden řetězec
REM
REM Parametr %2 se předává i s uvozovkami (%2, ne %~2). Díky tomu
REM zůstávají speciální znaky (ampersand, svislítko, menší a větší)
REM uvnitř uvozovek neškodné.
REM Popis (%1) obsahuje jen běžný text, proto jej lze vypsat přes %~1.
REM
REM Výsledek FINDSTR: errorlevel 0 = nalezeno, 1 = nenalezeno.
REM ------------------------------------------------------------

:ASSERT_HAS
findstr /l /c:%2 "%RUN_LOG%" >nul 2>&1
if errorlevel 1 (
    echo %RED%[FAIL]%RESET% %~1
    set /a FAILS+=1
) else (
    echo %GREEN%[ OK ]%RESET% %~1
)
exit /b 0


REM ------------------------------------------------------------
REM :ASSERT_LATEST_HAS_RUN
REM ------------------------------------------------------------
REM
REM Kopie posledního logu (LATEST_LOG) musí existovat a musí
REM obsahovat identifikátor tohoto běhu (RUN_ID).
REM
REM Po úspěšném FINISH se RUN_LOG zkopíruje do LATEST_LOG, takže
REM RUN_ID tohoto běhu v něm být musí.
REM ------------------------------------------------------------

:ASSERT_LATEST_HAS_RUN
if not exist "%LATEST_LOG%" (
    echo %RED%[FAIL]%RESET% latest log neexistuje
    set /a FAILS+=1
    exit /b 0
)
findstr /l /c:"%RUN_ID%" "%LATEST_LOG%" >nul 2>&1
if errorlevel 1 (
    echo %RED%[FAIL]%RESET% latest log neobsahuje tento beh
    set /a FAILS+=1
) else (
    echo %GREEN%[ OK ]%RESET% latest log obsahuje tento beh
)
exit /b 0
