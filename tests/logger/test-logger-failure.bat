@echo off
setlocal EnableExtensions

REM ============================================================
REM GTA V CZ/EN Switch - Test Loggeru (FAILURE)
REM ============================================================
REM
REM Negativní test centrálního loggeru:
REM     core\logger.bat
REM
REM Umístění testu:
REM     tests\logger\test-logger-failure.bat
REM
REM ------------------------------------------------------------
REM CO TEST DĚLÁ
REM ------------------------------------------------------------
REM
REM Simuluje běh aplikace, který skončí uprostřed kroku bez volání
REM FINISH (jako při pádu aplikace). Poté zkontroluje, že logger
REM zanechal správný stav.
REM
REM Ověřuje, že:
REM     - log vzniká průběžně a obsahuje vše do poslední chyby,
REM     - rozpracovaný krok má v logu STEP_START,
REM     - SCRIPT_END v logu NENÍ (FINISH nebyl zavolán),
REM     - gta-v-cz-en-switch-latest.log tento běh NEOBSAHUJE
REM       (latest se aktualizuje pouze při FINISH).
REM
REM ------------------------------------------------------------
REM NÁVRATOVÝ KÓD TESTU
REM ------------------------------------------------------------
REM
REM     0 = logger se při předčasném ukončení chová správně,
REM     1 = některá kontrola selhala nebo chybí logger.
REM
REM Simulovaná chyba aplikace je jen záznam ERROR v logu. Nemá vliv
REM na návratový kód testu.
REM
REM ------------------------------------------------------------
REM PROČ TEST VIDÍ PROMĚNNÉ LOGGERU
REM ------------------------------------------------------------
REM
REM Logger nepoužívá SETLOCAL, jeho stav běhu zůstává v proměnných
REM prostředí. Po prvním CALL proto test vidí RUN_ID, RUN_LOG,
REM LATEST_LOG a barvy z colors.bat (RED, GREEN, RESET).
REM SETLOCAL na začátku testu zajistí, že po skončení testu zmizí.
REM
REM ------------------------------------------------------------
REM SPUŠTĚNÍ
REM ------------------------------------------------------------
REM
REM   Běžně (s pauzou na konci):
REM       tests\logger\test-logger-failure.bat
REM
REM   Bez pauzy (například pro automatické spuštění):
REM       set NOPAUSE=1
REM
REM ============================================================


REM ------------------------------------------------------------
REM CESTA K TESTOVANÉMU LOGGERU
REM ------------------------------------------------------------
REM
REM Stejný postup jako v test-logger-success.bat: úplná
REM normalizovaná cesta (bez částí "..") a název proměnné LOGGER,
REM který se nepřekrývá s proměnnými nastavovanými loggerem.
REM ------------------------------------------------------------

for %%I in ("%~dp0..\..\core\logger.bat") do set "LOGGER=%%~fI"

REM Počítadlo selhaných kontrol. Zvyšují ho pomocné funkce níže.
set "FAILS=0"


REM ------------------------------------------------------------
REM KONTROLA EXISTENCE LOGGERU
REM ------------------------------------------------------------
REM
REM Bez loggeru nemá smysl negativní test spouštět. Test v tom
REM případě skončí s kódem 1 ještě před simulovaným během.
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
echo TEST LOGGERU - FAILURE
echo ============================================================
echo.
echo Simulovany beh bude zamerne ukoncen pred FINISH.
echo.


REM ============================================================
REM SIMULOVANÝ BĚH APLIKACE
REM ============================================================

REM SCRIPT_START: logger se při prvním volání sám inicializuje
REM (vytvoří RUN_ID a soubor RUN_LOG s hlavičkou).
call "%LOGGER%" INFO "Failure test loggeru byl spusten." SCRIPT_START

REM Zápisy se musí objevit v logu ihned, ne až na konci běhu.
call "%LOGGER%" INFO "Prvni cast failure testu." CONTEXT
call "%LOGGER%" DEBUG "DEBUG pred umyslnym ukoncenim." CONTEXT

REM ------------------------------------------------------------
REM KROK 1/2 - řádně ukončený (očekávaný počet dotazů: 1)
REM ------------------------------------------------------------
REM
REM Před chybou musí v logu existovat kompletní historie prvního
REM kroku včetně STEP_END s dobou trvání a počtem dotazů.
REM ------------------------------------------------------------

call "%LOGGER%" STEP "1/2" "Prvni testovaci krok"
REM PowerShell čekání funguje i při přesměrovaném vstupu automatického běhu.
powershell -NoProfile -Command "Start-Sleep -Seconds 2" >nul
call "%LOGGER%" INFO "Prvni krok probiha." WAIT
powershell -NoProfile -Command "Start-Sleep -Seconds 1" >nul
call "%LOGGER%" STEP_END

REM ------------------------------------------------------------
REM KROK 2/2 - pouze zahájený, v něm "aplikace spadne"
REM ------------------------------------------------------------
REM
REM Krok se nezavře (chybí STEP_END) a nezavolá se FINISH.
REM V logu proto musí být STEP_START druhého kroku a poslední
REM ERROR, ale žádný STEP_END druhého kroku ani SCRIPT_END.
REM ------------------------------------------------------------

call "%LOGGER%" STEP "2/2" "Rozpracovany krok"
call "%LOGGER%" ERROR "Testovaci chyba - beh bude nyni umyslne ukoncen." ERROR

REM Zde záměrně NEVOLÁME: logger.bat FINISH


REM ============================================================
REM AUTOMATICKÁ KONTROLA LOGU
REM ============================================================
REM
REM Po prvním volání loggeru jsou k dispozici proměnné RUN_LOG,
REM LATEST_LOG a RUN_ID. Test je jen používá.
REM ============================================================

echo.
echo ------------------------------------------------------------
echo KONTROLA LOGU
echo ------------------------------------------------------------
echo.

REM Záznamy před chybou musí být v logu.
call :ASSERT_HAS "SCRIPT_START" "| SCRIPT_START |"
call :ASSERT_HAS "zprava pred chybou" "Prvni cast failure testu."
call :ASSERT_HAS "DEBUG pred chybou" "DEBUG pred umyslnym ukoncenim."

REM První krok je kompletní, druhý pouze zahájený.
call :ASSERT_HAS "krok 1 uzavren, dotazu na log 1" "dotazu na log: 1."
call :ASSERT_HAS "STEP_START rozpracovaneho kroku" "[2/2] Rozpracovany krok"

REM Poslední záznam před ukončením.
call :ASSERT_HAS "posledni ERROR" "Testovaci chyba - beh bude nyni umyslne ukoncen."

REM Co v logu být NESMÍ: SCRIPT_END vzniká až ve FINISH.
call :ASSERT_MISSING "SCRIPT_END v logu neni" "| SCRIPT_END |"

REM Kopie posledního logu se bez FINISH neaktualizuje.
call :ASSERT_LATEST_NOT_HAS_RUN


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
    echo TEST DOKONCEN - LOGGER SE PRI PADU CHOVA SPRAVNE
) else (
    echo %RED%TEST SELHAL - pocet chyb: %FAILS%%RESET%
)
echo ============================================================
echo.

REM Cesta k logu pochází přímo z loggeru (RUN_LOG).
echo Log najdes v:
echo %RUN_LOG%
echo.

if not defined NOPAUSE pause

REM ------------------------------------------------------------
REM UKONČENÍ TESTU
REM ------------------------------------------------------------
REM
REM Příkazový řádek s ENDLOCAL a EXIT se nejprve celý
REM rozvine (proměnná RESULT dostane hodnotu), potom se provede endlocal
REM a exit. Hodnota tak přežije konec SETLOCAL jako návratový kód.
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
REM :ASSERT_MISSING "popis" "text, který v logu být nesmí"
REM ------------------------------------------------------------
REM
REM Opak funkce :ASSERT_HAS. Kontrola projde, když se hledaný
REM text v RUN_LOG NEnachází.
REM ------------------------------------------------------------

:ASSERT_MISSING
findstr /l /c:%2 "%RUN_LOG%" >nul 2>&1
if errorlevel 1 (
    echo %GREEN%[ OK ]%RESET% %~1
) else (
    echo %RED%[FAIL]%RESET% %~1
    set /a FAILS+=1
)
exit /b 0


REM ------------------------------------------------------------
REM :ASSERT_LATEST_NOT_HAS_RUN
REM ------------------------------------------------------------
REM
REM Bez FINISH se LATEST_LOG neaktualizuje. Pokud soubor existuje
REM (zůstal z dřívějšího běhu), nesmí obsahovat RUN_ID tohoto
REM běhu. Pokud neexistuje vůbec, kontrola také projde.
REM
REM Změníš-li někdy chování loggeru tak, že se latest aktualizuje
REM už při startu nebo při chybě, uprav i tuto kontrolu.
REM ------------------------------------------------------------

:ASSERT_LATEST_NOT_HAS_RUN
if not exist "%LATEST_LOG%" (
    echo %GREEN%[ OK ]%RESET% latest log tento beh neobsahuje
    exit /b 0
)
findstr /l /c:"%RUN_ID%" "%LATEST_LOG%" >nul 2>&1
if errorlevel 1 (
    echo %GREEN%[ OK ]%RESET% latest log tento beh neobsahuje
) else (
    echo %RED%[FAIL]%RESET% latest log obsahuje beh bez FINISH
    set /a FAILS+=1
)
exit /b 0
