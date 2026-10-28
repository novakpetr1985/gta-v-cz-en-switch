@echo off
setlocal EnableExtensions

REM ============================================================
REM GTA V CZ/EN Switch - UI Automation layer (uia.bat)
REM ============================================================
REM
REM UCEL
REM   Znovupouzitelna vrstva, ktera v okne Rockstar Games
REM   Launcheru najde UI prvek (napr. GO OFFLINE) a aktivuje ho
REM   pres Windows UI Automation (Invoke) nebo fyzickym kliknutim.
REM
REM CO MODUL NEDELA
REM   - nespousti Launcher a nerozhoduje o stavu online/offline
REM   - nema zadnou business logiku (ta patri volajicimu modulu)
REM
REM JAK TO FUNGUJE
REM   1. nacte vstupy (UIA_*, nebo stare CLICK_*) a overi je
REM   2. v CMD pocka na okno Launcheru a da ho do popredi
REM   3. spusti PowerShell helper ulozeny na konci tohoto souboru
REM      mezi znackami PS_UIA_BEGIN a PS_UIA_END
REM   4. helper najde prvek (pripadne nejdriv klikne na navigaci,
REM      napr. zalozku Settings) a aktivuje ho
REM   5. navratovy kod se prevede na UIA_RESULT
REM
REM POZNAMKY K NAVRHU (proc je to udelane takto)
REM   * Aktivace okna bezi primo z CMD, ne v PowerShell helperu.
REM     Helper je skryty potomek a Windows mu casto zakaze menit
REM     okno v popredi (zamek popredi).
REM   * PowerShell prikazy v BAT casti jsou vzdy na JEDNOM radku
REM     v uvozovkach. Znak ^ uvnitr uvozovek nefunguje spolehlive
REM     jako pokracovani radku.
REM   * Znacky PS_UIA_BEGIN a PS_UIA_END se ve spoustecim prikazu
REM     skladaji ze dvou casti a v komentarich nesmi byt uvedeny
REM     v plnem tvaru s mrizkou, jinak by IndexOf nasel komentar
REM     misto skutecne znacky.
REM   * Soubor MUSI mit konce radku CRLF a obsahovat jen ASCII.
REM     S LF mohou goto/call prestat nachazet navesti.
REM   * Modul i volajici musi bezet ve stejne urovni opravneni.
REM     Proces bez admin prav nemuze ovladat okno Launcheru
REM     spusteneho jako administrator.
REM   * Modul pouziva SETLOCAL; volajicimu se vraci jen UIA_RESULT
REM     a UIA_DUMP_PATH.
REM
REM DIAGNOSTIKA
REM   uia.bat --activate     samostatny test aktivace okna
REM                          (spoustet z konzole, ne dvojklikem)
REM   %TEMP%\gta_v_cz_en_uia_trace.txt
REM                          stopa posledniho behu; vznika vzdy,
REM                          i kdyz modul skonci hned na zacatku
REM   UIA_DUMP               strom UI, pokud se prvek nenajde
REM   UIA_TIMING             casovani PowerShell helperu
REM
REM VOLANI (promenne nastavi volajici pred CALL)
REM
REM   UIA_MODE            invoke | mouse                (povinne)
REM   UIA_NAMES           nazvy hledaneho prvku, oddelene |
REM                       (povinne)
REM   UIA_REGEX           volitelny regularni vyraz pro Button
REM   UIA_NAV             volitelne nazvy navigace, oddelene |
REM   UIA_WINDOW_HANDLE   volitelny HWND okna Launcheru; po
REM                       aktivaci ho modul prepise nalezenym
REM   UIA_WINDOW_PROCESS  proces okna, vychozi SocialClubHelper
REM   UIA_WINDOW_TITLE    titulek okna,
REM                       vychozi Rockstar Games Launcher
REM   UIA_WINDOW_TIMEOUT  cekani na okno v s,
REM                       vychozi TIMEOUT_WINDOW z configu, jinak 15
REM   UIA_TIMEOUT         limit hledani prvku v s, vychozi 45
REM   UIA_DUMP            cesta k diagnostickemu vypisu
REM   UIA_DUMP_TIMEOUT    maximalni doba dumpu v s, vychozi 8
REM   UIA_DUMP_PATTERNS   1 = do dumpu zahrnout UIA patterns (pomale)
REM   UIA_TIMING          volitelna cesta k vykonnostni diagnostice
REM
REM Kompatibilita se starsim offline modulem (CLICK_MODE,
REM CLICK_NAMES, CLICK_REGEX, CLICK_NAV, OFF_WINDOW_HANDLE):
REM pokud jsou nastaveny UIA_* i stare promenne, UIA_* ma prednost.
REM
REM NAVRATOVE KODY
REM   0 = prvek byl uspesne aktivovan
REM   2 = okno Launcheru nebo prvek nebyl nalezen
REM       (je-li to mozne, vznikne UIA_DUMP)
REM   3 = okno nelze dat do popredi, nebo prvek nelze
REM       aktivovat zvolenou metodou
REM   4 = neplatne vstupy nebo chyba inicializace
REM   5 = pomocny PowerShell prekrocil bezpecnostni limit
REM
REM VYSLEDNE PROMENNE
REM   UIA_RESULT     SUCCESS | NOT_FOUND | ACTION_FAILED |
REM                  TIMEOUT | ERROR
REM   UIA_DUMP_PATH  cesta k dumpu (soubor existuje jen po selhani)
REM ============================================================


REM ============================================================
REM INICIALIZACE BEHU
REM ============================================================

REM Samostatny test: uia.bat --activate
set "UIA_SELFTEST="
if /I "%~1"=="--activate" set "UIA_SELFTEST=1"

REM Stopa behu v TEMP (prepisuje se pri kazdem spusteni).
set "UIA_TRACE=%TEMP%\gta_v_cz_en_uia_trace.txt"
>"%UIA_TRACE%" echo [%date% %time%] uia.bat spusten, soubor: %~f0
>>"%UIA_TRACE%" echo [%time%] UIA_MODE="%UIA_MODE%" CLICK_MODE="%CLICK_MODE%" selftest="%UIA_SELFTEST%"
>>"%UIA_TRACE%" echo [%time%] UIA_NAMES="%UIA_NAMES%" CLICK_NAMES="%CLICK_NAMES%"

REM Duvod predcasneho konce (zapisuje se do stopy v :UIA_END).
set "UIA_WHY="


REM ============================================================
REM VYCHOZI STAV
REM ============================================================

set "UIA_RC=4"
set "UIA_RESULT=ERROR"
set "UIA_DUMP_PATH="


REM ============================================================
REM ZPETNA KOMPATIBILITA
REM ============================================================

if not defined UIA_MODE if defined CLICK_MODE (
    set "UIA_MODE=%CLICK_MODE%"
)

if not defined UIA_NAMES if defined CLICK_NAMES (
    set "UIA_NAMES=%CLICK_NAMES%"
)

if not defined UIA_REGEX if defined CLICK_REGEX (
    set "UIA_REGEX=%CLICK_REGEX%"
)

if not defined UIA_NAV if defined CLICK_NAV (
    set "UIA_NAV=%CLICK_NAV%"
)

if not defined UIA_WINDOW_HANDLE if defined OFF_WINDOW_HANDLE (
    set "UIA_WINDOW_HANDLE=%OFF_WINDOW_HANDLE%"
)


REM ============================================================
REM VALIDACE VSTUPU
REM ============================================================

set "UIA_WHY=UIA_MODE chybi nebo neni invoke/mouse"
if not defined UIA_SELFTEST if /I not "%UIA_MODE%"=="invoke" if /I not "%UIA_MODE%"=="mouse" goto UIA_END

set "UIA_WHY=UIA_NAMES chybi"
if not defined UIA_SELFTEST if not defined UIA_NAMES goto UIA_END
set "UIA_WHY="


REM ============================================================
REM VYCHOZI HODNOTY
REM ============================================================

if not defined UIA_WINDOW_PROCESS (
    set "UIA_WINDOW_PROCESS=SocialClubHelper"
)

if not defined UIA_WINDOW_TITLE (
    set "UIA_WINDOW_TITLE=Rockstar Games Launcher"
)

if not defined UIA_TIMEOUT (
    set "UIA_TIMEOUT=45"
)

REM Dump je pouze diagnostika. Kratky samostatny limit zabrani tomu,
REM aby pomaly UI Automation provider zmenil vysledek nenalezeneho
REM prvku na bezpecnostni timeout helperu.
if not defined UIA_DUMP_TIMEOUT (
    set "UIA_DUMP_TIMEOUT=8"
)

REM TIMEOUT_WINDOW pochazi z configu; kdyz neni, pouzije se 15.
if not defined UIA_WINDOW_TIMEOUT set "UIA_WINDOW_TIMEOUT=%TIMEOUT_WINDOW%"
if not defined UIA_WINDOW_TIMEOUT set "UIA_WINDOW_TIMEOUT=15"


REM ============================================================
REM VALIDACE TIMEOUTU
REM ============================================================

set "UIA_WHY=neplatny UIA_TIMEOUT, UIA_WINDOW_TIMEOUT nebo UIA_DUMP_TIMEOUT"
for /f "delims=0123456789" %%A in ("%UIA_TIMEOUT%") do goto UIA_END
if %UIA_TIMEOUT% LEQ 0 goto UIA_END

for /f "delims=0123456789" %%A in ("%UIA_WINDOW_TIMEOUT%") do goto UIA_END
if %UIA_WINDOW_TIMEOUT% LEQ 0 goto UIA_END

for /f "delims=0123456789" %%A in ("%UIA_DUMP_TIMEOUT%") do goto UIA_END
if %UIA_DUMP_TIMEOUT% LEQ 0 goto UIA_END
if %UIA_DUMP_TIMEOUT% GTR 20 goto UIA_END
set "UIA_WHY="

REM Samostatny test aktivace pouziva vzdy vychozi identifikaci okna.
if defined UIA_SELFTEST (
    set "UIA_WINDOW_PROCESS=SocialClubHelper"
    set "UIA_WINDOW_TITLE=Rockstar Games Launcher"
    set "UIA_WINDOW_HANDLE="
    goto UIA_SELFTEST_RUN
)


REM ============================================================
REM DIAGNOSTICKY VYSTUP
REM
REM Promenna se plni mimo zavorkovany blok, protoze %PROMENNA%
REM uvnitr bloku se vyhodnoti drive, nez ji FOR nastavi.
REM ============================================================

if not defined UIA_DUMP (
    for %%I in ("%~dp0..") do set "UIA_PROJECT_DIR=%%~fI"
)

if not defined UIA_DUMP set "UIA_DUMP=%UIA_PROJECT_DIR%\diagnostics\gta_v_cz_en_uia_dump.txt"

for %%I in ("%UIA_DUMP%") do set "UIA_DUMP_DIR=%%~dpI"

if not exist "%UIA_DUMP_DIR%" mkdir "%UIA_DUMP_DIR%" >nul 2>&1

REM Stary dump z drivejsiho behu by zpusobil, ze UIA_DUMP_PATH
REM ukazuje na soubor, ktery k aktualnimu volani nepatri.
if exist "%UIA_DUMP%" del /q "%UIA_DUMP%" >nul 2>&1

set "UIA_DUMP_PATH=%UIA_DUMP%"


REM ============================================================
REM VLASTNI CESTA K TOMUTO SOUBORU
REM ============================================================

set "UIA_SELF=%~f0"


REM ============================================================
REM BEZPECNOSTNI LIMIT POWERSHELLU
REM
REM Na okno ceka uz CMD cast (viz AKTIVACE OKNA), helper tedy
REM dostane jen:
REM   UIA_TIMEOUT   = hledani prvku
REM   + 25 sekund   = rezerva pro inicializaci/ukonceni
REM ============================================================

set /a UIA_PROCESS_TIMEOUT=(UIA_TIMEOUT+25)*1000


REM ============================================================
REM :UIA_ACTIVATE_WINDOW
REM
REM Navratove kody:
REM   0 = okno je v popredi
REM   2 = okno se neobjevilo do UIA_WINDOW_TIMEOUT
REM   3 = okno se nepodarilo dat do popredi
REM
REM Priorita:
REM   1. explicitni UIA_WINDOW_HANDLE
REM   2. hledani okna podle procesu + titulku
REM ============================================================

:UIA_ACTIVATE_WINDOW

set /a UIA_ACT_WAIT=0

:UIA_ACT_CHECK

set "UIA_ACT_STATUS="
set "UIA_ACT_HWND="

REM ------------------------------------------------------------
REM 1. Explicitni HWND ma prednost pred vyhledanim procesu.
REM ------------------------------------------------------------

if defined UIA_WINDOW_HANDLE goto UIA_ACT_EXPLICIT_CHECK

REM ------------------------------------------------------------
REM 2. Fallback: hledani okna podle procesu + titulku.
REM ------------------------------------------------------------

for /f "tokens=1,2 delims=|" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Get-Process -Name $env:UIA_WINDOW_PROCESS -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -eq $env:UIA_WINDOW_TITLE } | Select-Object -First 1; if($null -eq $p){ Write-Output 'NOWINDOW' } else { Write-Output ('FOUND|'+$p.MainWindowHandle) }"') do (
    set "UIA_ACT_STATUS=%%a"
    set "UIA_ACT_HWND=%%b"
)

if "%UIA_ACT_STATUS%"=="FOUND" goto UIA_ACT_ACTIVATE

set /a UIA_ACT_WAIT+=1
if %UIA_ACT_WAIT% GEQ %UIA_WINDOW_TIMEOUT% (
    >>"%UIA_TRACE%" echo [%time%] okno nenalezeno do %UIA_WINDOW_TIMEOUT% s, proces=%UIA_WINDOW_PROCESS%
    exit /b 2
)

timeout /t 1 /nobreak >nul 2>&1 || ping -n 2 127.0.0.1 >nul
goto UIA_ACT_CHECK


:UIA_ACT_EXPLICIT_CHECK

REM ------------------------------------------------------------
REM Overeni explicitniho HWND.
REM ------------------------------------------------------------

set "UIA_ACT_HWND=%UIA_WINDOW_HANDLE%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$q=[char]34; $sig='[DllImport('+$q+'user32.dll'+$q+')] public static extern bool IsWindow(IntPtr hWnd);'; Add-Type -MemberDefinition $sig -Name Win32 -Namespace UiaExplicit -ErrorAction Stop; $h=[IntPtr]::new([Int64]$env:UIA_WINDOW_HANDLE); if([UiaExplicit.Win32]::IsWindow($h)){exit 0}; exit 1"

if errorlevel 1 (
    >>"%UIA_TRACE%" echo [%time%] explicitni UIA_WINDOW_HANDLE je neplatny: %UIA_WINDOW_HANDLE%
    exit /b 2
)

>>"%UIA_TRACE%" echo [%time%] pouzit explicitni UIA_WINDOW_HANDLE=%UIA_ACT_HWND%
goto UIA_ACT_ACTIVATE


:UIA_ACT_ACTIVATE

set "UIA_WINDOW_HANDLE=%UIA_ACT_HWND%"
>>"%UIA_TRACE%" echo [%time%] okno nalezeno, HWND=%UIA_ACT_HWND%

REM ------------------------------------------------------------
REM Aktivace okna:
REM - obnoveni minimalizovaneho okna
REM - pripojeni k vlaknu aktualniho foreground okna
REM - BringWindowToTop
REM - SetForegroundWindow
REM - overeni skutecneho foreground HWND
REM ------------------------------------------------------------

powershell -NoProfile -ExecutionPolicy Bypass -Command "$q=[char]34; $d='[DllImport('+$q+'user32.dll'+$q+')] '; $sig=$d+'public static extern bool ShowWindowAsync(IntPtr h,int c); '+$d+'public static extern bool SetForegroundWindow(IntPtr h); '+$d+'public static extern bool BringWindowToTop(IntPtr h); '+$d+'public static extern IntPtr GetForegroundWindow(); '+$d+'public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p); '+$d+'public static extern bool AttachThreadInput(uint a,uint b,bool f); [DllImport('+$q+'kernel32.dll'+$q+')] public static extern uint GetCurrentThreadId();'; Add-Type -MemberDefinition $sig -Name Win32 -Namespace UiaAct; $h=[IntPtr]::new([Int64]$env:UIA_ACT_HWND); [UiaAct.Win32]::ShowWindowAsync($h,9) | Out-Null; Start-Sleep -Milliseconds 150; for($i=0;$i -lt 3;$i++){ $fg=[UiaAct.Win32]::GetForegroundWindow(); $pp=[uint32]0; $ft=[uint32]0; $ft=[UiaAct.Win32]::GetWindowThreadProcessId($fg,[ref]$pp); $me=[UiaAct.Win32]::GetCurrentThreadId(); $att=$false; if($ft -ne 0 -and $ft -ne $me){ $att=[UiaAct.Win32]::AttachThreadInput($me,$ft,$true) }; [UiaAct.Win32]::BringWindowToTop($h) | Out-Null; [UiaAct.Win32]::SetForegroundWindow($h) | Out-Null; if($att){ [UiaAct.Win32]::AttachThreadInput($me,$ft,$false) | Out-Null }; Start-Sleep -Milliseconds 250; if([UiaAct.Win32]::GetForegroundWindow() -eq $h){ exit 0 } }; exit 1" >nul 2>&1

if errorlevel 1 (
    >>"%UIA_TRACE%" echo [%time%] okno se nepodarilo dat do popredi
    exit /b 3
)

>>"%UIA_TRACE%" echo [%time%] okno je v popredi


REM ============================================================
REM SPUSTENI POWERSHELL HELPERU
REM
REM PowerShell kod je ulozen mezi radky se znackami PS_UIA_BEGIN
REM a PS_UIA_END (na zacatku radku, s mrizkou). Znacky se ve
REM spoustecim prikazu skladaji ze dvou casti a v komentarich
REM nesmi byt uvedeny v plnem tvaru - IndexOf by jinak nasel
REM komentar misto skutecne znacky.
REM
REM Prikaz musi byt na JEDNOM radku: znak ^ uvnitr uvozovek
REM nefunguje spolehlive jako pokracovani radku.
REM
REM Do TEMP se vytvori pouze docasny .ps1 soubor.
REM ============================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=Get-Content -LiteralPath $env:UIA_SELF -Raw; $begin='#PS_UIA_'+'BEGIN'; $end='#PS_UIA_'+'END'; $a=$t.IndexOf($begin); $b=$t.IndexOf($end); if($a -lt 0 -or $b -le $a){exit 4}; $code=$t.Substring($a+$begin.Length,$b-$a-$begin.Length); $f=Join-Path $env:TEMP ('GTA_CZ_EN_uia_'+[guid]::NewGuid().ToString()+'.ps1'); $rc=4; try{ Set-Content -LiteralPath $f -Value $code -Encoding UTF8; $p=Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',([char]34+$f+[char]34) -WindowStyle Hidden -PassThru; $null=$p.Handle; if($p.WaitForExit([int]$env:UIA_PROCESS_TIMEOUT)){ if($null -ne $p.ExitCode){$rc=[int]$p.ExitCode} } else { try{$p.Kill()}catch{}; $rc=5 } }catch{ $rc=4 }; Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; exit $rc" >nul 2>&1

set "UIA_RC=%ERRORLEVEL%"
>>"%UIA_TRACE%" echo [%time%] PowerShell helper skoncil kodem %UIA_RC%


REM ============================================================
REM PREVOD NAVRATOVEHO KODU NA UIA_RESULT
REM ============================================================

if "%UIA_RC%"=="0" (
    set "UIA_RESULT=SUCCESS"
)

if "%UIA_RC%"=="2" (
    set "UIA_RESULT=NOT_FOUND"
)

if "%UIA_RC%"=="3" (
    set "UIA_RESULT=ACTION_FAILED"
)

if "%UIA_RC%"=="5" (
    set "UIA_RESULT=TIMEOUT"
)

REM Jakykoli jiny kod (napr. 1 pri padu skriptu) je chyba.
if "%UIA_RESULT%"=="ERROR" set "UIA_RC=4"


REM ============================================================
REM KONEC
REM ============================================================

if not defined UIA_WHY if not "%UIA_RC%"=="0" set "UIA_WHY=viz kod"

:UIA_END

>>"%UIA_TRACE%" echo [%time%] konec: rc=%UIA_RC% vysledek=%UIA_RESULT% duvod=%UIA_WHY%

endlocal & set "UIA_RESULT=%UIA_RESULT%" & set "UIA_DUMP_PATH=%UIA_DUMP_PATH%" & exit /b %UIA_RC%


REM ============================================================
REM :UIA_SELFTEST_RUN  (uia.bat --activate)
REM
REM Spusti jen aktivaci okna a vypise, co je ve skutecnosti
REM v popredi a jak se jmenuji okna Rockstar Launcheru.
REM
REM Test nesmi byt ovlivnen hodnotami UIA_WINDOW_PROCESS,
REM UIA_WINDOW_TITLE ani UIA_WINDOW_HANDLE zdedenymi z prostredi.
REM Pred skokem sem se nastavuji vychozi hodnoty.
REM ============================================================

:UIA_SELFTEST_RUN

echo.
echo [UIA] Test aktivace okna
echo [UIA] Hledam: proces=%UIA_WINDOW_PROCESS%, titulek=%UIA_WINDOW_TITLE%, limit=%UIA_WINDOW_TIMEOUT% s

call :UIA_ACTIVATE_WINDOW
set "UIA_ACT_RC=%ERRORLEVEL%"

echo [UIA] Kod aktivace: %UIA_ACT_RC% - 0 = OK, 2 = okno nenalezeno, 3 = nejde do popredi
echo [UIA] Nalezeny HWND: %UIA_ACT_HWND%
echo [UIA] Stopa behu: %UIA_TRACE%

powershell -NoProfile -ExecutionPolicy Bypass -Command "$q=[char]34; $s='[DllImport('+$q+'user32.dll'+$q+')] public static extern IntPtr GetForegroundWindow(); [DllImport('+$q+'user32.dll'+$q+')] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p); [DllImport('+$q+'user32.dll'+$q+', CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h,System.Text.StringBuilder t,int n);'; Add-Type -MemberDefinition $s -Name W -Namespace UiaDiag; $f=[UiaDiag.W]::GetForegroundWindow(); $pp=[uint32]0; [void][UiaDiag.W]::GetWindowThreadProcessId($f,[ref]$pp); $sb=New-Object System.Text.StringBuilder 256; [void][UiaDiag.W]::GetWindowText($f,$sb,256); $pn=(Get-Process -Id $pp -ErrorAction SilentlyContinue).ProcessName; Write-Host ('[UIA] V popredi: HWND='+$f+' proces='+$pn+' PID='+$pp+' titulek='+$sb.ToString()); Write-Host '[UIA] Okna, jejichz titulek obsahuje Rockstar:'; Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -like '*Rockstar*' } | ForEach-Object { Write-Host ('[UIA]   '+$_.ProcessName+' PID='+$_.Id+' HWND='+$_.MainWindowHandle+' titulek='+$_.MainWindowTitle) }"

echo.
pause
endlocal & exit /b %UIA_ACT_RC%


#PS_UIA_BEGIN

# ============================================================
# POWERSHELL HELPER
#
# Tento kod uia.bat pri kazdem volani vyrizne do docasneho .ps1
# v TEMP a spusti ho skryte. Vstupy dostava pres promenne
# prostredi (UIA_*), vysledek vraci jako exit code:
#   0 = prvek aktivovan   2 = nenalezen   3 = akci nelze provest
#   4 = chyba inicializace
# Soubor musi zustat ASCII.
# ============================================================

$ErrorActionPreference = 'Stop'


# ============================================================
# INICIALIZACE WINDOWS UI AUTOMATION
# ============================================================

try {

    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class GtaUiaNative
{
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(
        uint f,
        uint dx,
        uint dy,
        uint d,
        UIntPtr e
    );

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr h);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr h, int c);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr h);

    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr h);
}
'@

    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes

}
catch {
    exit 4
}


[GtaUiaNative]::SetProcessDPIAware() | Out-Null


# ============================================================
# UI AUTOMATION OBJEKTY
# ============================================================

$AE = [System.Windows.Automation.AutomationElement]
$TS = [System.Windows.Automation.TreeScope]

$root = $AE::RootElement

$trueCondition =
    [System.Windows.Automation.Condition]::TrueCondition

$buttonCondition =
    New-Object System.Windows.Automation.PropertyCondition(
        $AE::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Button
    )


# ============================================================
# VSTUPY
# ============================================================

$names = @(
    $env:UIA_NAMES -split '\|' |
    Where-Object { $_ }
)

$navNames = @(
    $env:UIA_NAV -split '\|' |
    Where-Object { $_ }
)

$mode = $env:UIA_MODE
$regex = $env:UIA_REGEX

$deadline =
    (Get-Date).AddSeconds([int]$env:UIA_TIMEOUT)

$timingPath = $env:UIA_TIMING

$watch =
    [System.Diagnostics.Stopwatch]::StartNew()


# ============================================================
# TIMING
# ============================================================

function Write-UIATiming($label)
{
    if (-not $timingPath) {
        return
    }

    try {
        (
            '{0} | {1} ms' -f
            $label,
            [math]::Round(
                $watch.Elapsed.TotalMilliseconds,
                0
            )
        ) |
        Add-Content -LiteralPath $timingPath -Encoding UTF8
    }
    catch {}
}


Write-UIATiming 'START'


# ============================================================
# HLEDANI OKEN ROCKSTAR LAUNCHERU
# ============================================================

function Get-LauncherWindows
{
    $windows = @()


    # --------------------------------------------------------
    # 1. Primarni metoda - konkretni HWND
    # --------------------------------------------------------

    if ($env:UIA_WINDOW_HANDLE)
    {
        try
        {
            $handle =
                [IntPtr]::new(
                    [Int64]$env:UIA_WINDOW_HANDLE
                )

            if (
                $handle -ne [IntPtr]::Zero -and
                [GtaUiaNative]::IsWindow($handle)
            )
            {
                $window =
                    $AE::FromHandle($handle)

                if ($window)
                {
                    $windows += $window
                }
            }
        }
        catch {}
    }


    # Pokud byl nalezen konkretni window handle,
    # dalsi fallback neni potreba.

    if ($windows.Count -gt 0)
    {
        return $windows
    }


    # --------------------------------------------------------
    # 2. Fallback - proces + titulek
    # --------------------------------------------------------

    $pids = @(
        Get-Process `
            -Name $env:UIA_WINDOW_PROCESS `
            -ErrorAction SilentlyContinue |
        Where-Object {
            $_.MainWindowHandle -ne 0 -and
            $_.MainWindowTitle -eq $env:UIA_WINDOW_TITLE
        } |
        ForEach-Object {
            $_.Id
        }
    )


    # --------------------------------------------------------
    # 3. UI Automation top-level okna
    # --------------------------------------------------------

    foreach (
        $window in
        $root.FindAll(
            $TS::Children,
            $trueCondition
        )
    )
    {
        try
        {
            $current = $window.Current

            if (
                ($pids -contains $current.ProcessId) -or
                (
                    $current.Name -eq $env:UIA_WINDOW_TITLE -and
                    $current.NativeWindowHandle -ne 0
                )
            )
            {
                $windows += $window
            }
        }
        catch {}
    }


    return $windows
}


Write-UIATiming 'UIAUTOMATION_READY'


# ============================================================
# INVOKE
# ============================================================

function Invoke-Element($element)
{
    $pattern = $null

    try
    {
        if (
            -not $element.TryGetCurrentPattern(
                [System.Windows.Automation.InvokePattern]::Pattern,
                [ref]$pattern
            )
        )
        {
            return $false
        }

        $pattern.Invoke()
        return $true
    }
    catch
    {
        return $false
    }
}


# ============================================================
# MOUSE CLICK
# ============================================================

function Mouse-Click($element, $window)
{
    try
    {
        $rect =
            $element.Current.BoundingRectangle

        if (
            $rect.IsEmpty -or
            $rect.Width -le 0 -or
            $rect.Height -le 0
        )
        {
            return $false
        }


        $handle =
            [IntPtr]$window.Current.NativeWindowHandle


        # ----------------------------------------------------
        # Aktivace okna
        # ----------------------------------------------------

        if ([GtaUiaNative]::IsIconic($handle))
        {
            [GtaUiaNative]::ShowWindow(
                $handle,
                9
            ) | Out-Null
        }

        [GtaUiaNative]::SetForegroundWindow(
            $handle
        ) | Out-Null

        Start-Sleep -Milliseconds 250


        # ----------------------------------------------------
        # Pozice stredu prvku
        # ----------------------------------------------------

        $x =
            [int](
                $rect.X +
                ($rect.Width / 2)
            )

        $y =
            [int](
                $rect.Y +
                ($rect.Height / 2)
            )


        [GtaUiaNative]::SetCursorPos(
            $x,
            $y
        ) | Out-Null

        Start-Sleep -Milliseconds 80


        # ----------------------------------------------------
        # Mouse down
        # ----------------------------------------------------

        [GtaUiaNative]::mouse_event(
            0x0002,
            0,
            0,
            0,
            [UIntPtr]::Zero
        )


        Start-Sleep -Milliseconds 60


        # ----------------------------------------------------
        # Mouse up
        # ----------------------------------------------------

        [GtaUiaNative]::mouse_event(
            0x0004,
            0,
            0,
            0,
            [UIntPtr]::Zero
        )


        return $true
    }
    catch
    {
        return $false
    }
}


# ============================================================
# NAVIGACNI KLIK
#
# Stejne jako v offline.bat: nejprve Invoke, a kdyz prvek
# InvokePattern nema, fyzicky klik. Zalozky v Launcheru
# casto Invoke nepodporuji, takze jen-Invoke by navigaci
# nikdy neprovedl.
# ============================================================

function Click-Element($element, $window)
{
    if (Invoke-Element $element)
    {
        return $true
    }

    return (
        Mouse-Click $element $window
    )
}


# ============================================================
# HLEDANI PRVKU
# ============================================================

function Find-Element(
    $window,
    $candidateNames,
    $allowRegex
)
{
    # --------------------------------------------------------
    # 1. Presny Name
    # --------------------------------------------------------

    foreach ($name in $candidateNames)
    {
        $condition =
            New-Object `
                System.Windows.Automation.PropertyCondition(
                    $AE::NameProperty,
                    $name
                )

        Write-UIATiming 'FIND_NAME_START'

        $found =
            $window.FindFirst(
                $TS::Descendants,
                $condition
            )

        Write-UIATiming 'FIND_NAME_END'

        if ($found)
        {
            return $found
        }
    }


    # --------------------------------------------------------
    # 2. Regex pouze nad Button prvky
    # --------------------------------------------------------

    if ($allowRegex -and $regex)
    {
        foreach (
            $button in
            $window.FindAll(
                $TS::Descendants,
                $buttonCondition
            )
        )
        {
            if (
                $button.Current.Name -imatch $regex
            )
            {
                return $button
            }
        }
    }


    return $null
}


# ============================================================
# HLEDANI NAVIGACE
#
# Nazev jako "Settings" se v okne muze vyskytovat vicekrat
# (zalozka i nadpis stranky). Vybirame prvek nejvyse v okne,
# tj. zalozku - stejne jako Find-Nav v offline.bat.
# ============================================================

function Find-Navigation($window, $candidateNames)
{
    $best = $null
    $bestY = [double]::MaxValue

    foreach ($name in $candidateNames)
    {
        $condition =
            New-Object `
                System.Windows.Automation.PropertyCondition(
                    $AE::NameProperty,
                    $name
                )

        foreach (
            $element in
            $window.FindAll(
                $TS::Descendants,
                $condition
            )
        )
        {
            $y =
                $element.Current.BoundingRectangle.Y

            if ($y -lt $bestY)
            {
                $bestY = $y
                $best = $element
            }
        }
    }

    return $best
}


# ============================================================
# DIAGNOSTICKY DUMP
# ============================================================

function Write-DiagnosticDump($windows)
{
    try
    {
        # Dump zapisujeme prubezne. Pokud nektery UIA provider odpovida
        # pomalu, zustane k dispozici alespon castecna diagnostika.
        @(
            ('Cas: {0}; hledano: {1}' -f (Get-Date), $env:UIA_NAMES),
            ('Proces: {0}; titulek: {1}; top-level oken: {2}' -f $env:UIA_WINDOW_PROCESS, $env:UIA_WINDOW_TITLE, @($windows).Count)
        ) | Set-Content -LiteralPath $env:UIA_DUMP -Encoding UTF8

        $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
        $script:nodeCount = 0
        $script:dumpStopped = $false
        $script:dumpDeadline = (Get-Date).AddSeconds([int]$env:UIA_DUMP_TIMEOUT)
        $includePatterns = $env:UIA_DUMP_PATTERNS -eq '1'


        function Dump-Node(
            $element,
            $depth
        )
        {
            if (
                $script:nodeCount -ge 1500 -or
                $depth -gt 14 -or
                (Get-Date) -ge $script:dumpDeadline
            )
            {
                $script:dumpStopped = $true
                return
            }


            $script:nodeCount++


            try
            {
                $current = $element.Current
            }
            catch
            {
                return
            }


            $name =
                (
                    $current.Name -replace '\s+', ' '
                )


            if ($name.Length -gt 80)
            {
                $name =
                    $name.Substring(0, 80)
            }


            $line =
                ('{0}{1} | name="{2}" | class={3} | id={4}' -f
                    (' ' * $depth),
                    $current.ControlType.ProgrammaticName,
                    $name,
                    $current.ClassName,
                    $current.AutomationId)

            # GetSupportedPatterns muze byt u nekterych provideru pomale.
            # Je proto dostupne jen pri explicitni diagnosticke volbe.
            if ($includePatterns)
            {
                try
                {
                    $patterns = @(
                        $element.GetSupportedPatterns() |
                        ForEach-Object { $_.ProgrammaticName }
                    ) -join ', '
                    $line += ' | patterns=' + $patterns
                }
                catch {}
            }

            Add-Content -LiteralPath $env:UIA_DUMP -Value $line -Encoding UTF8


            $child =
                $walker.GetFirstChild($element)


            while ($child -ne $null)
            {
                if ((Get-Date) -ge $script:dumpDeadline)
                {
                    $script:dumpStopped = $true
                    break
                }

                Dump-Node `
                    $child `
                    ($depth + 1)

                if ($script:dumpStopped) { break }

                $child =
                    $walker.GetNextSibling($child)
            }
        }


        foreach ($window in @($windows))
        {
            Dump-Node $window 0
            if ($script:dumpStopped) { break }
        }

        if ($script:dumpStopped)
        {
            Add-Content -LiteralPath $env:UIA_DUMP -Value 'Dump byl zkracen kvuli limitu UIA_DUMP_TIMEOUT.' -Encoding UTF8
        }
    }
    catch {}
}


# ============================================================
# HLAVNI HLEDACI CYKLUS
#
# Okno Launcheru uz ve vlastni CMD casti vyhledal a aktivoval
# uia.bat a predal jeho HWND v UIA_WINDOW_HANDLE. Tady se jen
# opakovane hleda cilovy prvek, dokud nevyprsi UIA_TIMEOUT.
# ============================================================

$target = $null
$targetWindow = $null

$lastNavigation =
    (Get-Date).AddSeconds(-60)


while (
    (Get-Date) -lt $deadline -and
    -not $target
)
{
    try
    {
        $windows =
            @(Get-LauncherWindows)


        foreach ($window in $windows)
        {
            $target =
                Find-Element `
                    $window `
                    $names `
                    $true


            if ($target)
            {
                $targetWindow = $window
                break
            }


            # ------------------------------------------------
            # Volitelna navigace.
            #
            # Navigacni prvek se zkusi maximalne jednou za 10 s.
            # ------------------------------------------------

            if (
                $navNames.Count -gt 0 -and
                (
                    (Get-Date) - $lastNavigation
                ).TotalSeconds -ge 10
            )
            {
                $navigation =
                    Find-Navigation `
                        $window `
                        $navNames


                if ($navigation)
                {
                    Click-Element `
                        $navigation `
                        $window |
                        Out-Null


                    $lastNavigation =
                        Get-Date


                    Start-Sleep -Seconds 2
                }
            }
        }
    }
    catch
    {
        # Okno nebo prvek mohly mezitim zaniknout
        # (napr. prekresleni UI) - zkusime to znovu.
        $target = $null
    }


    if (-not $target)
    {
        Start-Sleep -Milliseconds 750
    }
}


# ============================================================
# CIL NENALEZEN
# ============================================================

if (-not $target)
{
    Write-UIATiming 'TARGET_NOT_FOUND'
    Write-UIATiming 'DUMP_START'

    Write-DiagnosticDump `
        @(Get-LauncherWindows)

    Write-UIATiming 'DUMP_END'

    exit 2
}


Write-UIATiming 'TARGET_FOUND'


# ============================================================
# INVOKE MODE
# ============================================================

if ($mode -eq 'invoke')
{
    Write-UIATiming 'INVOKE_START'


    if (
        Invoke-Element $target
    )
    {
        Write-UIATiming 'INVOKE_END'
        Write-UIATiming 'TOTAL_SUCCESS'

        exit 0
    }


    exit 3
}


# ============================================================
# MOUSE MODE
# ============================================================

if (
    Mouse-Click `
        $target `
        $targetWindow
)
{
    Write-UIATiming 'MOUSE_END'
    Write-UIATiming 'TOTAL_SUCCESS'

    exit 0
}


exit 3


#PS_UIA_END
