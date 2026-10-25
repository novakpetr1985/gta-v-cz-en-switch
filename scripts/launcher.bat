@echo off

REM ============================================================
REM GTA V CZ/EN Switch - Launcher
REM ============================================================
REM
REM Funkcni modul volany hlavnim orchestratorom:
REM   gta-v-cz-en-switch.bat
REM
REM Ucel:
REM   1. Spustit LauncherPatcher.exe, pokud Launcher.exe nebezi.
REM   2. Pockat na proces Launcher.exe.
REM   3. Najit skutecne viditelne top-level okno Rockstar Launcheru.
REM   4. Obnovit okno a pokusit se jej aktivovat do popredi.
REM
REM Dulezite:
REM   - Skript nepouziva SETLOCAL, aby stav loggeru zustal v calleru.
REM   - Skript nevola FINISH; ukonceni behu patri orchestratoru.
REM   - Skript nema bezny PAUSE.
REM   - Pro samostatny diagnosticky test pouzij:
REM
REM       launcher.bat --test
REM
REM   - V testovacim rezimu zustane CMD po vysledku otevrene.
REM
REM Navratovy kod:
REM   0 = Launcher.exe bezi a jeho okno je nalezeno + aktivovano.
REM   1 = chyba.
REM
REM Konfigurace z config\config.bat:
REM   ROCKSTAR_PATCHER
REM   ROCKSTAR_LOG_DIR
REM   TIMEOUT_LAUNCHER
REM   TIMEOUT_WINDOW
REM
REM ============================================================


REM ============================================================
REM REZIM SPUSTENI
REM ============================================================

set "LAUNCHER_TEST="

if /I "%~1"=="--test" set "LAUNCHER_TEST=1"
if /I "%~1"=="-t" set "LAUNCHER_TEST=1"


REM ============================================================
REM INICIALIZACE CORE
REM ============================================================

set "CORE_DIR=%~dp0..\core\"

call "%CORE_DIR%logger.bat" STEP "1/2" "Pripravuji Rockstar Launcher."


REM ============================================================
REM KONTROLA CONFIGU
REM ============================================================

if not defined ROCKSTAR_PATCHER (
    call "%CORE_DIR%logger.bat" ERR "Promenna ROCKSTAR_PATCHER neni nastavena."
    set "LS_ERROR=V konfiguraci chybi ROCKSTAR_PATCHER."
    goto LS_FAIL
)

if not defined TIMEOUT_LAUNCHER set "TIMEOUT_LAUNCHER=120"
if not defined TIMEOUT_WINDOW set "TIMEOUT_WINDOW=15"


REM ============================================================
REM KONTROLA LAUNCHER PATCHERU
REM ============================================================

if exist "%ROCKSTAR_PATCHER%" goto LS_PATCHER_OK

call "%CORE_DIR%logger.bat" WARN "LauncherPatcher.exe nebyl nalezen v: %ROCKSTAR_PATCHER%"
call "%CORE_DIR%logger.bat" INFO "Zadej cestu k LauncherPatcher.exe nebo ke slozce Launcheru."
call "%CORE_DIR%logger.bat" INFO "Prazdny vstup ukonci beh."


:LS_ASK_PATCHER

set "LS_INPUT="

set /p "LS_INPUT=Cesta: "

if not defined LS_INPUT goto LS_PATCHER_CANCEL

set "LS_INPUT=%LS_INPUT:"=%"

if not defined LS_INPUT goto LS_PATCHER_CANCEL


REM Pokud uzivatel zadal slozku, doplnime LauncherPatcher.exe.

if exist "%LS_INPUT%\" set "LS_INPUT=%LS_INPUT%\LauncherPatcher.exe"

for %%F in ("%LS_INPUT%") do set "LS_NAME=%%~nxF"

if /I not "%LS_NAME%"=="LauncherPatcher.exe" goto LS_PATCHER_BAD

if not exist "%LS_INPUT%" goto LS_PATCHER_BAD

set "ROCKSTAR_PATCHER=%LS_INPUT%"

call "%CORE_DIR%logger.bat" OK "LauncherPatcher.exe nalezen: %ROCKSTAR_PATCHER%"

goto LS_PATCHER_OK


:LS_PATCHER_BAD

call "%CORE_DIR%logger.bat" WARN "LauncherPatcher.exe v zadane ceste nebyl nalezen: %LS_INPUT%"

goto LS_ASK_PATCHER


:LS_PATCHER_CANCEL

call "%CORE_DIR%logger.bat" ERR "Cesta k LauncherPatcher.exe nebyla zadana."

set "LS_ERROR=Cesta k LauncherPatcher.exe nebyla zadana."

goto LS_FAIL


:LS_PATCHER_OK

set "LS_INPUT="
set "LS_NAME="

call "%CORE_DIR%logger.bat" DEBUG "Patcher: %ROCKSTAR_PATCHER%"


REM ============================================================
REM KONTROLA, ZDA LAUNCHER JIZ BEZI
REM ============================================================

tasklist /FI "IMAGENAME eq Launcher.exe" 2>nul | find /I "Launcher.exe" >nul

if not errorlevel 1 goto LS_LAUNCHER_ALREADY_RUNNING


REM ============================================================
REM LAUNCHER NEBEZI - SPUSTENI PATCHERU
REM ============================================================

start "" "%ROCKSTAR_PATCHER%"

REM
REM `start` zde nepouzivame jako potvrzeni uspechu.
REM Skutecne overeni probiha nize kontrolou procesu Launcher.exe.
REM Pokud se LauncherPatcher.exe nepodari spustit, nasledna kontrola
REM Launcher.exe skonci timeoutem a vrati chybu.
REM

call "%CORE_DIR%logger.bat" OK "LauncherPatcher.exe spusten."


REM ============================================================
REM KROK 2/2 - CEKANI NA PROCES LAUNCHER.EXE
REM ============================================================

call "%CORE_DIR%logger.bat" STEP "2/2" "Cekam na Launcher.exe..."

set /a LS_WAIT=0


:LS_WAIT_LAUNCHER

tasklist /FI "IMAGENAME eq Launcher.exe" 2>nul | find /I "Launcher.exe" >nul

if not errorlevel 1 goto LS_LAUNCHER_FOUND

set /a LS_WAIT+=1

call "%CORE_DIR%logger.bat" INFO "Cekam na Launcher.exe: %LS_WAIT% s z %TIMEOUT_LAUNCHER% s." WAIT F

if %LS_WAIT% GEQ %TIMEOUT_LAUNCHER% (
    call "%CORE_DIR%logger.bat" ERR "Launcher.exe se nespustil do %TIMEOUT_LAUNCHER% s."
    set "LS_ERROR=Launcher.exe se nespustil v nastavenem limitu."
    goto LS_FAIL
)

timeout /t 1 /nobreak >nul

goto LS_WAIT_LAUNCHER


REM ============================================================
REM LAUNCHER JIZ BEZI
REM ============================================================

:LS_LAUNCHER_ALREADY_RUNNING

call "%CORE_DIR%logger.bat" WARN "Rockstar Launcher uz bezi. Nebudu jej znovu spoustet."

goto LS_LAUNCHER_FOUND


REM ============================================================
REM LAUNCHER NALEZEN
REM ============================================================

:LS_LAUNCHER_FOUND

set "LAUNCHER_PID="

for /f "tokens=2" %%p in ('tasklist /FI "IMAGENAME eq Launcher.exe" /NH') do (
    if not defined LAUNCHER_PID set "LAUNCHER_PID=%%p"
)

if not defined LAUNCHER_PID (
    call "%CORE_DIR%logger.bat" ERR "Nepodarilo se zjistit PID procesu Launcher.exe."
    set "LS_ERROR=Nepodarilo se zjistit PID procesu Launcher.exe."
    goto LS_FAIL
)

call "%CORE_DIR%logger.bat" OK "Launcher.exe bezi."

call "%CORE_DIR%logger.bat" DEBUG "Prvni nalezeny PID Launcher.exe: %LAUNCHER_PID%."

goto LS_ACTIVATE_WINDOW


REM ============================================================
REM AKTIVACE OKNA ROCKSTAR LAUNCHERU
REM ============================================================

:LS_ACTIVATE_WINDOW

set /a LS_WINDOW_WAIT=0


:LS_WINDOW_CHECK

set "LS_WINDOW_PID="
set "LS_WINDOW_HANDLE="
set "LS_WINDOW_TITLE="


REM ============================================================
REM HLEDANI SOCIALCLUBHELPER S OKNEM ROCKSTAR LAUNCHERU
REM ============================================================

for /f "tokens=1-3 delims=|" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Get-Process -Name 'SocialClubHelper' -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -eq 'Rockstar Games Launcher' } | Select-Object -First 1; if($null -eq $p){ Write-Output 'NOWINDOW' } else { Write-Output ('FOUND|'+$p.Id+'|'+$p.MainWindowHandle+'|'+$p.MainWindowTitle) }"') do (
    set "LS_WINDOW_STATUS=%%a"
    set "LS_WINDOW_PID=%%b"
    set "LS_WINDOW_HANDLE=%%c"
    set "LS_WINDOW_TITLE=%%d"
)


REM ============================================================
REM OKNO NALEZENO
REM ============================================================

if "%LS_WINDOW_STATUS%"=="FOUND" goto LS_WINDOW_ACTIVATE


REM ============================================================
REM OKNO ZATIM NENI DOSTUPNE
REM ============================================================

set /a LS_WINDOW_WAIT+=1

call "%CORE_DIR%logger.bat" INFO "Cekam na okno Rockstar Launcheru: %LS_WINDOW_WAIT% s z %TIMEOUT_WINDOW% s." WAIT F

if %LS_WINDOW_WAIT% GEQ %TIMEOUT_WINDOW% (
    call "%CORE_DIR%logger.bat" ERR "Okno Rockstar Launcheru se nepodarilo nalezt do %TIMEOUT_WINDOW% s."
    set "LS_ERROR=Okno Rockstar Launcheru nebylo nalezeno."
    goto LS_FAIL
)

timeout /t 1 /nobreak >nul

goto LS_WINDOW_CHECK


REM ============================================================
REM AKTIVACE NALEZENEHO OKNA
REM ============================================================

:LS_WINDOW_ACTIVATE

call "%CORE_DIR%logger.bat" DEBUG "Okno nalezeno: PID %LS_WINDOW_PID%, HWND %LS_WINDOW_HANDLE%."

powershell -NoProfile -ExecutionPolicy Bypass -Command "$sig='[DllImport(\"user32.dll\")] public static extern bool ShowWindowAsync(IntPtr hWnd,int nCmdShow); [DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(IntPtr hWnd);'; Add-Type -MemberDefinition $sig -Name Win32 -Namespace LauncherWindow; $h=[IntPtr]::new([Int64]%LS_WINDOW_HANDLE%); [LauncherWindow.Win32]::ShowWindowAsync($h,9) | Out-Null; [LauncherWindow.Win32]::SetForegroundWindow($h) | Out-Null" >nul 2>&1


REM ============================================================
REM OVERENI AKTIVNIHO OKNA
REM ============================================================

set "LS_FOREGROUND="

for /f "delims=" %%f in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$sig='[DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();'; Add-Type -MemberDefinition $sig -Name Win32 -Namespace LauncherForeground; [LauncherForeground.Win32]::GetForegroundWindow().ToInt64()"') do set "LS_FOREGROUND=%%f"

if "%LS_FOREGROUND%"=="%LS_WINDOW_HANDLE%" goto LS_WINDOW_SUCCESS


call "%CORE_DIR%logger.bat" WARN "Okno Rockstar Launcheru bylo nalezeno, ale nepodarilo se jej dostat do popredi."
set "LS_ERROR=Okno Rockstar Launcheru nebylo mozne aktivovat."
goto LS_FAIL


REM ============================================================
REM AKTIVACE USPESNA
REM ============================================================

:LS_WINDOW_SUCCESS

call "%CORE_DIR%logger.bat" OK "Rockstar Launcher okno je aktivni. PID %LS_WINDOW_PID%, HWND %LS_WINDOW_HANDLE%."

exit /b 0

REM ============================================================
REM TESTOVACI REZIM - USPESNY VYSLEDEK
REM ============================================================

:LS_TEST_SUCCESS

echo.
echo ============================================================
echo LAUNCHER USPESNE PRIPRAVEN
echo ============================================================
echo Launcher.exe PID : %LAUNCHER_PID%
echo Okno HWND         : %LAUNCHER_HWND%
echo ============================================================
echo.
echo Rockstar Launcher je aktivni.
echo.
echo Stiskni libovolnou klavesu pro ukonceni testu...

pause >nul

set "LS_WAIT="
set "LS_WINDOW_WAIT="
set "LS_WINDOW_HANDLE="
set "LS_WINDOW_RESULT="
set "LS_WINDOW_STATUS="
set "LS_WINDOW_PID="
set "LAUNCHER_TEST="

exit /b 0


REM ============================================================
REM CHYBOVE UKONCENI
REM ============================================================

:LS_FAIL

if not defined LS_ERROR set "LS_ERROR=Launcher modul skoncil chybou."

call "%CORE_DIR%logger.bat" ERR "%LS_ERROR%"


REM ============================================================
REM TESTOVACI REZIM - CHYBA
REM ============================================================

if "%LAUNCHER_TEST%"=="1" goto LS_TEST_FAILURE


REM ============================================================
REM NORMALNI CHYBOVY NAVRAT
REM ============================================================

set "LS_WAIT="
set "LS_WINDOW_WAIT="
set "LS_WINDOW_HANDLE="
set "LS_WINDOW_RESULT="
set "LS_WINDOW_STATUS="
set "LS_WINDOW_PID="
set "LAUNCHER_TEST="

exit /b 1


REM ============================================================
REM TESTOVACI REZIM - CHYBA
REM ============================================================

:LS_TEST_FAILURE

echo.
echo ============================================================
echo LAUNCHER SKONCIL CHYBOU
echo ============================================================
echo %LS_ERROR%
echo ============================================================
echo.
echo Stiskni libovolnou klavesu pro ukonceni testu...

pause >nul

set "LS_WAIT="
set "LS_WINDOW_WAIT="
set "LS_WINDOW_HANDLE="
set "LS_WINDOW_RESULT="
set "LS_WINDOW_STATUS="
set "LS_WINDOW_PID="
set "LAUNCHER_TEST="

exit /b 1
