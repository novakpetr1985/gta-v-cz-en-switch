# UIA – Windows UI Automation

## Účel

`scripts/uia.bat` je generická nízkoúrovňová vrstva pro ovládání prvků grafického rozhraní Rockstar Games Launcheru pomocí Windows UI Automation.

Modul neobsahuje business logiku konkrétního workflow.

```text
vyšší funkční modul
        │
        ▼
     uia.bat
        │
        ├── Launcher window
        ├── UI Automation
        ├── element search
        ├── InvokePattern / mouse
        └── result
```

Konkrétní workflow, například offline režim, aktualizace nebo spuštění hry, mají rozhodovat vyšší funkční moduly.

---

## Vstupy

### Povinné

| Proměnná | Hodnoty | Význam |
|---|---|---|
| `UIA_MODE` | `invoke`, `mouse` | způsob aktivace |
| `UIA_NAMES` | seznam oddělený `|` | názvy hledaných prvků |

Příklad:

```bat
set "UIA_MODE=invoke"
set "UIA_NAMES=PLAY"
call "%UIA_FILE%"
```

### Volitelné

| Proměnná | Význam |
|---|---|
| `UIA_REGEX` | regex pro hledání tlačítek |
| `UIA_NAV` | navigace UI stromem před hledáním cíle |
| `UIA_WINDOW_HANDLE` | explicitní HWND okna Launcheru |
| `UIA_WINDOW_PROCESS` | proces Launcheru; výchozí `SocialClubHelper` |
| `UIA_WINDOW_TITLE` | přesný titulek; výchozí `Rockstar Games Launcher` |
| `UIA_DUMP` | požadavek na diagnostický dump |
| `UIA_DUMP_TIMEOUT` | maximální doba diagnostického dumpu v sekundách; výchozí `8`, maximum `20` |
| `UIA_DUMP_PATTERNS` | hodnota `1` doplní do dumpu podporované UIA patterns; může výrazně zpomalit průchod stromem |
| `UIA_TIMEOUT` | limit hledání; výchozí `45` |
| `UIA_TIMING` | diagnostické časové informace |

---

## Zpětná kompatibilita

UIA zachovává podporu starších názvů proměnných:

| Starší proměnná | UIA proměnná |
|---|---|
| `CLICK_MODE` | `UIA_MODE` |
| `CLICK_NAMES` | `UIA_NAMES` |
| `CLICK_REGEX` | `UIA_REGEX` |
| `CLICK_NAV` | `UIA_NAV` |
| `OFF_WINDOW_HANDLE` | `UIA_WINDOW_HANDLE` |

Pokud je současně nastavena nová i stará proměnná, přednost má `UIA_*`.

---

## Identifikace Launcheru

Výchozí identifikace používá:

```text
proces:  SocialClubHelper
titulek: Rockstar Games Launcher
```

UIA nejprve využije platný `UIA_WINDOW_HANDLE`.

Pokud explicitní HWND není k dispozici, vyhledá proces `UIA_WINDOW_PROCESS`, zkontroluje jeho `MainWindowHandle` a následně ověří přesný `UIA_WINDOW_TITLE`.

Tento mechanismus je důležitý zejména při práci s minimalizovaným Launcherem.

---

## Aktivace okna

Před hledáním UI elementu UIA:

1. získá HWND Launcheru,
2. obnoví minimalizované okno,
3. zavolá `SetForegroundWindow`,
4. krátce počká,
5. ověří pomocí `GetForegroundWindow`, že okno skutečně získalo foreground.

Úspěšná aktivace je základní podmínkou další práce.

Pokud ověření foreground selže, modul vrací chybu aktivace.

---

## Inicializace Windows UI Automation

PowerShell helper načte:

- `UIAutomationClient`
- `UIAutomationTypes`

a vytvoří root automation element.

Pro vlastní nízkoúrovňovou práci s okny a myší používá modul také nativní Win32 API prostřednictvím C# helperu.

Použité mechanismy zahrnují například:

- `SetForegroundWindow`
- `ShowWindow`
- `GetForegroundWindow`
- `SetCursorPos`
- `mouse_event`
- DPI awareness

---

## Hledání prvku

Výchozí hledání pracuje podle vlastnosti `Name`.

Například:

```text
UIA_NAMES=PLAY
```

znamená hledání elementu s názvem `PLAY`.

Pro tlačítka lze volitelně použít `UIA_REGEX`.

Pokud je nastaveno `UIA_NAV`, provede se nejprve navigace UI stromem a teprve následně hledání cílového prvku.

---

## Invoke mode

Při:

```bat
set "UIA_MODE=invoke"
```

se modul pokusí najít podporovaný `InvokePattern` a vyvolat akci přímo přes UI Automation.

Výhoda:

- nevyžaduje fyzické umístění kurzoru na tlačítko,
- pracuje přímo s UI Automation prvkem,
- je vhodný pro standardní tlačítka podporující `InvokePattern`.

---

## Mouse mode

Při:

```bat
set "UIA_MODE=mouse"
```

modul použije fyzickou simulaci myši.

Před kliknutím zajistí aktivaci okna a získá pozici cílového elementu.

Native helper následně nastaví kurzor a provede mouse click.

Tento režim je určen jako alternativa pro prvky, které nelze spolehlivě aktivovat přes `InvokePattern`.

---

## Diagnostika

UIA při nenalezení cíle vytvoří diagnostický výstup UI stromu.

Diagnostika slouží zejména k:

- nalezení správného názvu elementu,
- ověření typu elementu,
- zjištění dostupných patternů při volbě `UIA_DUMP_PATTERNS=1`,
- analýze změn UI Launcheru.

Diagnostické výstupy patří do lokální diagnostické vrstvy projektu a nemají být součástí běžného verzovaného provozního obsahu.

Dump se zapisuje průběžně a má vlastní limit `UIA_DUMP_TIMEOUT`. Pokud limit vyprší, soubor zůstane zachován jako částečný a běh stále vrátí `2` pro nenalezený cíl. Diagnostika tedy nemění výsledek vlastního hledání na timeout helperu.

---

## Bezpečnostní timeout

PowerShell helper je chráněn bezpečnostním timeoutem.

Pokud pomocný proces překročí povolený čas, UIA vrací:

```text
5 = PowerShell helper exceeded safety timeout
```

Cílem je zabránit zablokování hlavního BAT procesu při neočekávaném stavu UI nebo PowerShellu.

---

## Návratové kódy

| Kód | Význam |
|---:|---|
| `0` | Cíl byl úspěšně aktivován |
| `2` | Cílový prvek nebyl nalezen |
| `3` | Cíl nebylo možné aktivovat |
| `4` | Neplatný vstup nebo chyba inicializace UI Automation |
| `5` | PowerShell helper překročil bezpečnostní timeout |

Volající modul má vždy pracovat s `ERRORLEVEL`.

---

## Samostatný test aktivace Launcheru

UIA obsahuje diagnostický self-test:

```powershell
.\uia.bat --activate
```

Test ověřuje:

- nalezení procesu `SocialClubHelper`,
- nalezení hlavního HWND,
- přesný titulek `Rockstar Games Launcher`,
- aktivaci okna,
- skutečný foreground HWND.

Self-test vždy používá výchozí identifikaci Launcheru, aby nebyl ovlivněn náhodnými hodnotami zděděnými z prostředí.

---

## Ověření PLAY

Funkce byla ověřena pomocí:

```powershell
$env:UIA_MODE="invoke"
$env:UIA_NAMES="PLAY"
$env:UIA_REGEX=""
$env:UIA_NAV=""
.\uia.bat
```

Test prokázal:

1. nalezení Rockstar Games Launcheru,
2. aktivaci jeho okna,
3. nalezení prvku `PLAY`,
4. aktivaci přes `InvokePattern`,
5. reakci Rockstar Launcheru na akci.

Následná reakce Launcheru může záviset na aktuálním stavu instalace GTA V Enhanced. Taková následná kontrola Launcheru sama o sobě není chybou UIA, pokud byla akce `PLAY` skutečně přijata.

---

## Integrace do hlavního orchestrátoru

Hlavní vstupní bod:

```text
gta-v-cz-en-switch.bat
```

již obsahuje UIA jako aktuální integrační/testovací krok.

Tok je:

```text
gta-v-cz-en-switch.bat
        │
        ├── config/config.bat
        │
        ├── core/logger.bat
        │
        └── scripts/uia.bat
                │
                ▼
        UIA result / ERRORLEVEL
                │
                ▼
        logger → FINISH
                │
                ▼
        exit /b
```

Orchestrátor před UIA:

- načte Config,
- inicializuje Logger,
- zapíše začátek kroku.

Po návratu UIA:

- převezme `ERRORLEVEL`,
- zapíše úspěch nebo chybu,
- provede `FINISH`,
- vrátí stejný návratový kód.

V této etapě není nutná další změna orchestrátoru.

---

## Architektonické omezení

`uia.bat` nesmí obsahovat rozhodování typu:

```text
"přepni do offline režimu"
"spusť update"
"změň jazyk"
"spusť GTA"
```

UIA pouze provede nízkoúrovňovou operaci požadovanou volajícím.

Správná architektura je:

```text
offline.bat  → UIA → konkrétní UI prvek
update.bat   → UIA → konkrétní UI prvek
launcher.bat → UIA → konkrétní UI prvek
switch-*.bat → vyšší workflow
```

---

## Stav v0.5.0

UIA je v této etapě:

- implementováno,
- samostatně ověřeno,
- ověřeno na minimalizovaném Launcheru,
- ověřeno na aktivaci `PLAY`,
- integrováno do hlavního vstupního bodu,
- zdokumentováno.

Dalším krokem je integrační test celé cesty přes hlavní orchestrátor v samostatné testovací větvi.
