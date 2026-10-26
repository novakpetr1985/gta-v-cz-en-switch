@echo off
setlocal EnableExtensions

REM Samostatny test modulu: offline.bat --test nebo offline.bat -t.
set "OFFLINE_TEST="
if /I "%~1"=="--test" set "OFFLINE_TEST=1"
if /I "%~1"=="-t" set "OFFLINE_TEST=1"

REM ====================================================================
REM  GTA V CZ/EN Switch - Offline Module
REM
REM  Ucel:
REM    Samostatny modul pro prepnuti Rockstar Games Launcheru
REM    do offline rezimu.
REM
REM  Postup:
REM    1. Overi existenci Launcher.exe a launcher.log.
REM    2. Vytvori casovy marker aktualniho behu.
REM    3. Z launcher.log zjisti stav aktualniho spusteni Launcheru.
REM    4. Pokud je Launcher online:
REM       - vyhleda Settings a GO OFFLINE,
REM       - pokusi se pouzit UI Automation Invoke,
REM       - pri neuspechu pouzije fyzicky klik mysi,
REM       - pri neuspechu preda ovladani uzivateli pro rucni klik.
REM    5. Po prepnuti overuje novy zaznam:
REM       - startupinfo] Command line: obsahuje -scOfflineOnly,
REM       - za nim se objevi Signed In.
REM
REM  Dulezite:
REM    Modul pouze prepinani do offline rezimu. Nespousti Launcher,
REM    neprovadi update GTA V ani Rockstar Launcheru a neni orchestrator.
REM
REM  Navratove kody modulu:
REM    0 = offline rezim byl uspesne potvrzen
REM    1 = nepodarilo se prepnout/potvrdit offline rezim
REM    2 = rozhodujici zaznam zatim neni v launcher.log
REM    9 = chyba pri cteni nebo zpracovani launcher.log
REM
REM  Modul pouziva sdilenou konfiguraci a logger.
REM  FINISH nevola; dokonceni celeho behu patri orchestratoru.
REM ====================================================================


REM ====================================================================
REM  INICIALIZACE MODULU
REM ====================================================================

set "CORE_DIR=%~dp0..\core\"

REM Prvni volani loggeru nacte config\config.bat.
call "%CORE_DIR%logger.bat" STEP "1/3" "Pripravuji offline rezim."

if not defined ROCKSTAR_LOG_DIR (
    call "%CORE_DIR%logger.bat" ERR "Promenna ROCKSTAR_LOG_DIR neni nastavena."
    set "FINAL_RC=1"
    goto END_MODULE
)

if not defined TIMEOUT_WINDOW set "TIMEOUT_WINDOW=15"
if not defined TIMEOUT_OFFLINE_EFFECT set "TIMEOUT_OFFLINE_EFFECT=30"
if not defined TIMEOUT_OFFLINE_MANUAL set "TIMEOUT_OFFLINE_MANUAL=180"

set "ROCKSTAR_LOG=%ROCKSTAR_LOG_DIR%\launcher.log"

REM Launcher musi byt pripraven pred prepinanim do offline rezimu.
tasklist /FI "IMAGENAME eq Launcher.exe" 2>nul | find /I "Launcher.exe" >nul
if errorlevel 1 (
    call "%CORE_DIR%logger.bat" ERR "Launcher.exe nebezi. Nejprve spust launcher modul."
    set "FINAL_RC=1"
    goto END_MODULE
)

REM Docasny marker pro urceni noveho behu Launcheru
set "LOG_START=%TEMP%\gta_v_cz_en_offline_start.tmp"

REM Cesta tohoto skriptu
set "SELF=%~f0"

REM Koren projektu
set "PROJECT_ROOT=%~dp0.."
for %%I in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fI"

REM Diagnosticky adresar projektu
set "DIAGNOSTICS_DIR=%PROJECT_ROOT%\diagnostics"

REM Docasny UI Automation dump
set "UIA_DUMP=%DIAGNOSTICS_DIR%\gta_v_cz_en_offline_uia_dump.txt"

if not exist "%DIAGNOSTICS_DIR%" (
    mkdir "%DIAGNOSTICS_DIR%" >nul 2>&1
)

if not exist "%DIAGNOSTICS_DIR%" (
    echo [CHYBA] Nepodarilo se vytvorit diagnosticky adresar:
    echo         %DIAGNOSTICS_DIR%
    endlocal & exit /b 9
)


REM ====================================================================
REM  KONTROLA LOGU A AKTIVACE OKNA
REM ====================================================================

if not exist "%ROCKSTAR_LOG%" (
    call "%CORE_DIR%logger.bat" ERR "launcher.log nebyl nalezen: %ROCKSTAR_LOG%"
    set "FINAL_RC=9"
    goto END_MODULE
)

call "%CORE_DIR%logger.bat" STEP "2/3" "Aktivuji okno Rockstar Launcheru."
call :ACTIVATE_LAUNCHER_WINDOW
if errorlevel 1 goto FAILURE


REM ====================================================================
REM  ZACHYCENI CASU
REM
REM  Marker se pouziva pouze pro urceni radku vytvorenych pri aktualnim
REM  behu Launcheru.
REM ====================================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "(Get-Date).ToString('yyyy-MM-dd HH:mm:ss') | Set-Content -LiteralPath $env:LOG_START -Encoding ASCII"

if not exist "%LOG_START%" (
    echo [CHYBA] Nepodarilo se vytvorit casovy marker.
    set "FINAL_RC=9"
    goto END_MODULE
)


REM ====================================================================
REM  KONTROLA AKTUALNIHO STAVU
REM ====================================================================

call :OFFLINE_STATE
set "OFF_RC=%ERRORLEVEL%"

if "%OFF_RC%"=="0" (
    call "%CORE_DIR%logger.bat" OK "Rockstar Launcher uz bezi v offline rezimu."
    goto SUCCESS
)

if "%OFF_RC%"=="2" (
    call "%CORE_DIR%logger.bat" INFO "Offline stav zatim neni potvrzen."
)

if "%OFF_RC%"=="9" (
    call "%CORE_DIR%logger.bat" ERR "Nepodarilo se precist launcher.log."
    goto FAILURE
)

if "%OFF_RC%"=="1" (
    call "%CORE_DIR%logger.bat" INFO "Rockstar Launcher bezi online."
)


REM ====================================================================
REM  PREPNUTI DO OFFLINE
REM ====================================================================

call "%CORE_DIR%logger.bat" STEP "3/3" "Prepinam Rockstar Launcher do offline rezimu."
call "%CORE_DIR%logger.bat" INFO "Oteviram Settings a hledam GO OFFLINE."
call "%CORE_DIR%logger.bat" DEBUG "UI Automation pouzije HWND %OFF_WINDOW_HANDLE%, PID %OFF_WINDOW_PID%."


REM --------------------------------------------------------------------
REM  1. POKUS - UI AUTOMATION INVOKE
REM --------------------------------------------------------------------

set "CLICK_MODE=invoke"
set "CLICK_NAMES=GO OFFLINE|Go Offline|Go offline"
set "CLICK_REGEX=^\s*go\s+offline\s*$"
set "CLICK_NAV=SETTINGS|Settings"

call :CLICK
set "CLICK_RC=%ERRORLEVEL%"

if "%CLICK_RC%"=="0" (
    call "%CORE_DIR%logger.bat" OK "GO OFFLINE byl aktivovan metodou Invoke."
    set "OFF_LIMIT=%TIMEOUT_OFFLINE_EFFECT%"
    goto WAIT_OFFLINE
)

call "%CORE_DIR%logger.bat" WARN "Invoke nebyl uspesny."


REM --------------------------------------------------------------------
REM  2. POKUS - FYZICKY KLIK MYSI
REM --------------------------------------------------------------------

set "CLICK_MODE=mouse"

call :CLICK
set "CLICK_RC=%ERRORLEVEL%"

if "%CLICK_RC%"=="0" (
    call "%CORE_DIR%logger.bat" OK "GO OFFLINE byl aktivovan kliknutim mysi."
    set "OFF_LIMIT=%TIMEOUT_OFFLINE_EFFECT%"
    goto WAIT_OFFLINE
)

call "%CORE_DIR%logger.bat" WARN "Automaticky klik se nepodaril."


REM --------------------------------------------------------------------
REM  3. POKUS - RUCNI KLIK
REM --------------------------------------------------------------------

call "%CORE_DIR%logger.bat" WARN "GO OFFLINE se nepodarilo stisknout automaticky."
call "%CORE_DIR%logger.bat" WARN "Otevri v Rockstar Launcheru Settings a klikni na GO OFFLINE."
call "%CORE_DIR%logger.bat" INFO "Skript bude cekat %TIMEOUT_OFFLINE_MANUAL% sekund."

if exist "%UIA_DUMP%" (
    call "%CORE_DIR%logger.bat" INFO "Diagnostika UI Automation: %UIA_DUMP%"
)

set "OFF_LIMIT=%TIMEOUT_OFFLINE_MANUAL%"


REM ====================================================================
REM  CEKANI NA OFFLINE STAV
REM ====================================================================

:WAIT_OFFLINE

set /a WAIT_COUNT=0

:WAIT_OFFLINE_LOOP

call :OFFLINE_STATE
set "OFF_RC=%ERRORLEVEL%"

if "%OFF_RC%"=="0" (
    call "%CORE_DIR%logger.bat" OK "Rockstar Launcher bezi v offline rezimu."
    goto SUCCESS
)

set /a WAIT_COUNT+=1

call "%CORE_DIR%logger.bat" INFO "Cekam na potvrzeni offline rezimu: %WAIT_COUNT% s z %OFF_LIMIT% s." WAIT F

if %WAIT_COUNT% GEQ %OFF_LIMIT% (
    call "%CORE_DIR%logger.bat" ERR "Rockstar Launcher se neprepnul do offline rezimu v limitu %OFF_LIMIT% s."
    goto FAILURE
)

timeout /t 1 /nobreak >nul
goto WAIT_OFFLINE_LOOP


REM ====================================================================
REM  USPESNY KONEC
REM ====================================================================

:SUCCESS

set "FINAL_RC=0"
goto END_MODULE


REM ====================================================================
REM  CHYBOVY KONEC
REM ====================================================================

:FAILURE

set "FINAL_RC=1"
goto END_MODULE


REM ====================================================================
REM  CENTRALNI KONEC MODULU
REM ====================================================================

:END_MODULE

if exist "%LOG_START%" del /q "%LOG_START%" >nul 2>&1

if "%OFFLINE_TEST%"=="1" (
    echo.
    echo ============================================================
    if "%FINAL_RC%"=="0" (
        echo  OFFLINE MODULE: SUCCESS
    ) else (
        echo  OFFLINE MODULE: FAILED
    )
    echo  Navratovy kod: %FINAL_RC%
    echo ============================================================
    echo.
    pause
)

endlocal & exit /b %FINAL_RC%


REM ====================================================================
REM  :ACTIVATE_LAUNCHER_WINDOW
REM
REM  Prevezato z launcher modulu. Vrati 0 pouze tehdy, kdy je okno
REM  Rockstar Launcheru opravdu v popredi.
REM ====================================================================

:ACTIVATE_LAUNCHER_WINDOW

set /a OFF_WINDOW_WAIT=0

:OFF_WINDOW_CHECK

set "OFF_WINDOW_STATUS="
set "OFF_WINDOW_PID="
set "OFF_WINDOW_HANDLE="

for /f "tokens=1-3 delims=|" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Get-Process -Name 'SocialClubHelper' -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -eq 'Rockstar Games Launcher' } | Select-Object -First 1; if($null -eq $p){ Write-Output 'NOWINDOW' } else { Write-Output ('FOUND|'+$p.Id+'|'+$p.MainWindowHandle) }"') do (
    set "OFF_WINDOW_STATUS=%%a"
    set "OFF_WINDOW_PID=%%b"
    set "OFF_WINDOW_HANDLE=%%c"
)

if "%OFF_WINDOW_STATUS%"=="FOUND" goto OFF_WINDOW_ACTIVATE

set /a OFF_WINDOW_WAIT+=1
call "%CORE_DIR%logger.bat" INFO "Cekam na okno Rockstar Launcheru: %OFF_WINDOW_WAIT% s z %TIMEOUT_WINDOW% s." WAIT F

if %OFF_WINDOW_WAIT% GEQ %TIMEOUT_WINDOW% (
    call "%CORE_DIR%logger.bat" ERR "Okno Rockstar Launcheru se nepodarilo nalezt do %TIMEOUT_WINDOW% s."
    exit /b 1
)

timeout /t 1 /nobreak >nul
goto OFF_WINDOW_CHECK


:OFF_WINDOW_ACTIVATE

call "%CORE_DIR%logger.bat" DEBUG "Okno nalezeno: PID %OFF_WINDOW_PID%, HWND %OFF_WINDOW_HANDLE%."

powershell -NoProfile -ExecutionPolicy Bypass -Command "$sig='[DllImport(\"user32.dll\")] public static extern bool ShowWindowAsync(IntPtr hWnd,int nCmdShow); [DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(IntPtr hWnd);'; Add-Type -MemberDefinition $sig -Name Win32 -Namespace OfflineWindow; $h=[IntPtr]::new([Int64]%OFF_WINDOW_HANDLE%); [OfflineWindow.Win32]::ShowWindowAsync($h,9) | Out-Null; [OfflineWindow.Win32]::SetForegroundWindow($h) | Out-Null" >nul 2>&1

set "OFF_FOREGROUND="

for /f "delims=" %%f in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$sig='[DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();'; Add-Type -MemberDefinition $sig -Name Win32 -Namespace OfflineForeground; [OfflineForeground.Win32]::GetForegroundWindow().ToInt64()"') do set "OFF_FOREGROUND=%%f"

if "%OFF_FOREGROUND%"=="%OFF_WINDOW_HANDLE%" (
    call "%CORE_DIR%logger.bat" OK "Rockstar Launcher okno je aktivni. PID %OFF_WINDOW_PID%, HWND %OFF_WINDOW_HANDLE%."
    exit /b 0
)

call "%CORE_DIR%logger.bat" ERR "Okno Rockstar Launcheru nebylo mozne aktivovat."
exit /b 1


REM ====================================================================
REM  :OFFLINE_STATE
REM
REM  Navratove kody:
REM    0 = offline + Signed In
REM    1 = online
REM    2 = offline, ale zatim neni Signed In
REM    3 = Command line zatim nenalezen
REM    9 = chyba
REM ====================================================================

:OFFLINE_STATE

powershell -NoProfile -ExecutionPolicy Bypass -Command "try{ $p=$env:ROCKSTAR_LOG; if(-not(Test-Path -LiteralPath $p)){exit 9}; $s=[datetime]::ParseExact((Get-Content -LiteralPath $env:LOG_START -Raw).Trim(),'yyyy-MM-dd HH:mm:ss',[Globalization.CultureInfo]::InvariantCulture); $lines=@(Get-Content -LiteralPath $p -ErrorAction Stop); $commandIndex=-1; for($i=0;$i -lt $lines.Count;$i++){ if($lines[$i] -match '^\[(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d).*startupinfo\] Command line:'){ $t=[datetime]::ParseExact($matches[1],'yyyy-MM-dd HH:mm:ss',[Globalization.CultureInfo]::InvariantCulture); if($t -ge $s){$commandIndex=$i} } }; if($commandIndex -lt 0){exit 3}; if($lines[$commandIndex] -notmatch '-scOfflineOnly'){exit 1}; for($j=$commandIndex+1;$j -lt $lines.Count;$j++){ if($lines[$j] -match 'Signed In'){exit 0} }; exit 2 }catch{exit 9}"

exit /b %ERRORLEVEL%


REM ====================================================================
REM  :CLICK
REM
REM  Pouziva stejnou UI Automation logiku jako puvodni overeny skript.
REM
REM  CLICK_MODE:
REM    invoke = UI Automation Invoke
REM    mouse  = fyzicky klik mysi
REM ====================================================================

:CLICK

powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=Get-Content -LiteralPath $env:SELF -Raw; $a=$t.IndexOf('#PS_CLICK_'+'BEGIN'); $b=$t.IndexOf('#PS_CLICK_'+'END'); if($a -lt 0 -or $b -le $a){exit 4}; $f=Join-Path $env:TEMP 'GTA_CZ_EN_offline_click.ps1'; Set-Content -LiteralPath $f -Value $t.Substring($a+15,$b-$a-15) -Encoding UTF8; $p=Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$f -WindowStyle Hidden -PassThru; if(-not $p.WaitForExit(70000)){try{$p.Kill()}catch{}; exit 5}; exit $p.ExitCode"

exit /b %ERRORLEVEL%


REM ====================================================================
REM  POWERSELL - UI AUTOMATION
REM ====================================================================

#PS_CLICK_BEGIN

$ErrorActionPreference = 'SilentlyContinue'


Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class Native {
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
}
'@

if (-not ('Native' -as [type])) {
    exit 4
}

[Native]::SetProcessDPIAware() | Out-Null

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes


# --------------------------------------------------------------------
# Vstupy z BAT
# --------------------------------------------------------------------

$mode = $env:CLICK_MODE

$names = @(
    $env:CLICK_NAMES -split '\|'
)

$rx = $env:CLICK_REGEX

$navNames = @()

if ($env:CLICK_NAV) {
    $navNames = @(
        $env:CLICK_NAV -split '\|'
    )
}


$AE = [System.Windows.Automation.AutomationElement]
$TS = [System.Windows.Automation.TreeScope]

$root = $AE::RootElement

$trueCond =
    [System.Windows.Automation.Condition]::TrueCondition

$btnCond =
    New-Object System.Windows.Automation.PropertyCondition(
        $AE::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Button
    )


# --------------------------------------------------------------------
# Rockstar Launcher okna
# --------------------------------------------------------------------

function Get-LauncherWindows {

    $list = @()

    # :ACTIVATE_LAUNCHER_WINDOW uz v BAT overilo skutecne
    # okno Rockstar Launcheru a ulozilo jeho HWND/PID.
    # UI Automation proto pouzije stejne okno primo.
    if ($env:OFF_WINDOW_HANDLE) {
        try {
            $h = [IntPtr]::new([Int64]$env:OFF_WINDOW_HANDLE)

            if ($h -ne [IntPtr]::Zero) {
                $w = $AE::FromHandle($h)

                if ($w) {
                    $list += $w
                }
            }
        }
        catch {
        }
    }

    if ($list.Count -gt 0) {
        return $list
    }

    # Fallback: SocialClubHelper je skutecny proces hostujici
    # viditelne okno Rockstar Games Launcheru.
    $pids = @(
        Get-Process -Name SocialClubHelper -ErrorAction SilentlyContinue |
        Where-Object {
            $_.MainWindowHandle -ne 0 -and
            $_.MainWindowTitle -eq 'Rockstar Games Launcher'
        } |
        ForEach-Object { $_.Id }
    )

    foreach (
        $w in $root.FindAll(
            $TS::Children,
            $trueCond
        )
    ) {

        $c = $w.Current

        if (
            ($pids -contains $c.ProcessId) -or
            (
                $c.Name -match 'Rockstar Games Launcher' -and
                $c.NativeWindowHandle -ne 0
            )
        ) {
            $list += $w
        }
    }

    return $list
}


# --------------------------------------------------------------------
# Fyzicky klik mysi
# --------------------------------------------------------------------

function Mouse-Click($el, $w) {

    $r = $el.Current.BoundingRectangle

    if (
        $r.IsEmpty -or
        $r.Width -le 0 -or
        $r.Height -le 0
    ) {
        return $false
    }

    $h = [IntPtr]$w.Current.NativeWindowHandle

    if ([Native]::IsIconic($h)) {
        [Native]::ShowWindow($h, 9) | Out-Null
    }

    [Native]::SetForegroundWindow($h) | Out-Null

    Start-Sleep -Milliseconds 300

    [Native]::SetCursorPos(
        [int]($r.X + $r.Width / 2),
        [int]($r.Y + $r.Height / 2)
    ) | Out-Null

    Start-Sleep -Milliseconds 100

    [Native]::mouse_event(
        0x0002,
        0,
        0,
        0,
        [UIntPtr]::Zero
    )

    Start-Sleep -Milliseconds 60

    [Native]::mouse_event(
        0x0004,
        0,
        0,
        0,
        [UIntPtr]::Zero
    )

    return $true
}


# --------------------------------------------------------------------
# Hledani GO OFFLINE
# --------------------------------------------------------------------

function Find-Target($w) {

    foreach ($n in $names) {

        $c =
            New-Object System.Windows.Automation.PropertyCondition(
                $AE::NameProperty,
                $n
            )

        $h =
            $w.FindFirst(
                $TS::Descendants,
                $c
            )

        if ($h) {
            return $h
        }
    }

    if ($rx) {

        foreach (
            $b in $w.FindAll(
                $TS::Descendants,
                $btnCond
            )
        ) {

            if ($b.Current.Name -imatch $rx) {
                return $b
            }
        }
    }

    return $null
}


# --------------------------------------------------------------------
# Hledani Settings
# --------------------------------------------------------------------

function Find-Nav($w) {

    $tab = $null
    $ty = 100000

    foreach ($nm in $navNames) {

        $c =
            New-Object System.Windows.Automation.PropertyCondition(
                $AE::NameProperty,
                $nm
            )

        foreach (
            $e in $w.FindAll(
                $TS::Descendants,
                $c
            )
        ) {

            $y = $e.Current.BoundingRectangle.Y

            if ($y -lt $ty) {
                $ty = $y
                $tab = $e
            }
        }
    }

    return $tab
}


# --------------------------------------------------------------------
# Invoke / Mouse
# --------------------------------------------------------------------

function Click-Element($el, $w) {

    $o = $null

    if (
        $el.TryGetCurrentPattern(
            [System.Windows.Automation.InvokePattern]::Pattern,
            [ref]$o
        )
    ) {

        try {
            $o.Invoke()
            return $true
        }
        catch {}
    }

    return (
        Mouse-Click $el $w
    )
}


# --------------------------------------------------------------------
# Hledani okna a GO OFFLINE
# --------------------------------------------------------------------

$target = $null
$topWin = $null

$lastNav =
    (Get-Date).AddSeconds(-60)

$deadline =
    (Get-Date).AddSeconds(45)



while (
    (Get-Date) -lt $deadline -and
    -not $target
) {

    foreach (
        $w in (Get-LauncherWindows)
    ) {

        $hit = Find-Target $w

        if ($hit) {

            $target = $hit
            $topWin = $w

            break
        }

        if (
            $navNames.Count -gt 0 -and
            ((Get-Date) - $lastNav).TotalSeconds -gt 10
        ) {

            $tab = Find-Nav $w

            if ($tab) {

                Click-Element $tab $w | Out-Null

                $lastNav = Get-Date

                Start-Sleep -Seconds 2
            }
        }
    }

    if (-not $target) {
        Start-Sleep -Seconds 1
    }
}


# --------------------------------------------------------------------
# Kliknuti
# --------------------------------------------------------------------


if ($target) {

    if ($mode -eq 'invoke') {

        try {


            $target.GetCurrentPattern(
                [System.Windows.Automation.InvokePattern]::Pattern
            ).Invoke()


            exit 0
        }
        catch {
            exit 3
        }

    }
    else {

        if (Mouse-Click $target $topWin) {
                                    exit 0
        }

        exit 3
    }
}


# --------------------------------------------------------------------
# GO OFFLINE nenalezeno
# --------------------------------------------------------------------


$out =
    New-Object System.Collections.Generic.List[string]

$wins =
    @(Get-LauncherWindows)

$out.Add(
    'Cas: ' +
    (Get-Date) +
    ', hledano: ' +
    $env:CLICK_NAMES
)

$out.Add(
    'Procesy Launcher.exe: ' +
    @(Get-Process -Name Launcher).Count +
    ', top-level oken: ' +
    $wins.Count
)

foreach (
    $w in $root.FindAll(
        $TS::Children,
        $trueCond
    )
) {

    $c = $w.Current

    $out.Add(
        (
            'TOP | pid={0} | name="{1}" | class={2}' -f
            $c.ProcessId,
            $c.Name,
            $c.ClassName
        )
    )
}

$walker =
    [System.Windows.Automation.TreeWalker]::ControlViewWalker

$script:count = 0


function Dump-Node($el, $depth) {

    if (
        $script:count -ge 1500 -or
        $depth -gt 14
    ) {
        return
    }

    $script:count++

    $c = $el.Current

    $nm =
        ($c.Name -replace '\s+', ' ')

    if ($nm.Length -gt 80) {
        $nm =
            $nm.Substring(0, 80)
    }

    $out.Add(
        (
            '{0}{1} | name="{2}" | class={3} | id={4}' -f
            (' ' * $depth),
            $c.ControlType.ProgrammaticName,
            $nm,
            $c.ClassName,
            $c.AutomationId
        )
    )

    $ch =
        $walker.GetFirstChild($el)

    while ($ch -ne $null) {

        Dump-Node $ch ($depth + 1)

        $ch =
            $walker.GetNextSibling($ch)
    }
}


foreach ($w in $wins) {
    Dump-Node $w 0
}

$out |
    Set-Content `
        -LiteralPath $env:UIA_DUMP `
        -Encoding UTF8

exit 2

#PS_CLICK_END
