# CHANGELOG

## [v0.5.0] - UI Automation - 2026-10-27

### Přidáno

- Základní vrstva Windows UI Automation v [`scripts/uia.bat`](scripts/uia.bat).
- Vyhledání hlavního okna Rockstar Games Launcheru přes proces `SocialClubHelper` a jeho `MainWindowHandle`.
- Obnova minimalizovaného Launcheru a ověření skutečného foreground HWND.
- Podpora aktivace UI prvků přes `InvokePattern`.
- Podpora fyzické aktivace prvků pomocí mouse click.
- Vyhledávání cílových prvků podle `Name`.
- Volitelný regex pro prvky typu `Button`.
- Volitelná UI navigace před hledáním cílového prvku.
- Diagnostický dump stromu UI Automation.
- Samostatný diagnostický test aktivace pomocí `uia.bat --activate`.
- Bezpečnostní timeout pro PowerShell helper.
- Standardizované návratové kódy `0`, `2`, `3`, `4` a `5`.
- Dokumentace UIA v [`docs/UIA.md`](docs/UIA.md).
- Integrace UIA do hlavního vstupního bodu [`gta-v-cz-en-switch.bat`](gta-v-cz-en-switch.bat).
- Automatizovaná testovací sada UIA v [`tests/uia/`](tests/uia/).
- Samostatné testy úspěšného běhu, nenalezení prvku, diagnostického dumpu, běhu bez dumpu, neplatného vstupu, timeoutu hledání a timing diagnostiky.

### Ověřeno

- Aktivace minimalizovaného Rockstar Games Launcheru.
- Ověření skutečného foreground HWND.
- Vyhledání prvku `PLAY`.
- Aktivace `PLAY` přes `InvokePattern`.
- Následná reakce Rockstar Launcheru potvrzující zpracování akce.
- Načtení centrální konfigurace před spuštěním UIA.
- Inicializace centrálního loggeru před spuštěním UIA.
- Převzetí návratového kódu UIA hlavním orchestrátorem a jeho předání volajícímu.
- Kompletní UIA testovací sada: `7 / 7` testů PASSED.
- Testování `SUCCESS`, `NOT_FOUND` a `ERROR` výsledků.
- Vytvoření a kontrola diagnostického dumpu.
- Ověření, že úspěšný běh bez požadavku na dump diagnostický dump nevytvoří.
- Ověření timing diagnostiky včetně událostí `START`, `UIAUTOMATION_READY`, `FIND_NAME_START`, `FIND_NAME_END` a `TARGET_NOT_FOUND`.

### Poznámka

- UIA zůstává generickou ovládací vrstvou bez business logiky; konkrétní workflow budou implementovat vyšší funkční moduly.
- Test spuštění hry může být následně ovlivněn stavem instalace GTA V Enhanced a kontrolami Rockstar Launcheru; taková reakce není sama o sobě chybou UIA.
- Kompletní testovací sada UIA je ověřena na `feature/scripts-uia`; výsledný celek bude následně znovu ověřen v samostatné testovací větvi.

## [v0.4.0] - Offline Module - 2026-10-26

### Přidáno

- Samostatný funkční Offline modul [`scripts/offline.bat`](scripts/offline.bat).
- Kontrola aktuálního stavu Rockstar Games Launcheru pomocí `launcher.log`.
- Detekce již aktivního offline režimu.
- Automatické otevření Settings a hledání akce `GO OFFLINE`.
- Ovládání `GO OFFLINE` pomocí Windows UI Automation `Invoke`.
- Fallback na fyzický klik myší při selhání UI Automation.
- Manuální fallback při selhání automatických metod.
- Ověření skutečného offline režimu pomocí parametru `-scOfflineOnly` a následného stavu `Signed In`.
- Interní stavové vyhodnocení `OFFLINE_STATE`.
- Návratové kódy modulu pro nadřazený orchestrátor.
- Napojení na centrální konfiguraci [`config/config.bat`](config/config.bat).
- Napojení na centrální logger [`core/logger.bat`](core/logger.bat).
- Diagnostický UI Automation dump při selhání hledání prvku.
- Samostatné testování Offline modulu bez závislosti na `launcher.bat`.
- Dokumentace Offline modulu [`docs/OFFLINE.md`](docs/OFFLINE.md).
- Orchestrace Offline modulu přes hlavní vstupní bod [`gta-v-cz-en-switch.bat`](gta-v-cz-en-switch.bat) pro aktuální testovací workflow.
- Vyhodnocení návratového kódu Offline modulu hlavním orchestrátorem.

### Opraveno

- CMD/PowerShell zpracování automatického fyzického kliku bylo upraveno tak, aby bylo spolehlivé při volání z BAT skriptu.
- Automatické ovládání používá víceúrovňový fallback místo jediného způsobu aktivace `GO OFFLINE`.
- Potvrzení offline režimu není založeno pouze na kliknutí, ale na skutečném stavu zaznamenaném v `launcher.log`.
- Časové limity Offline modulu jsou řízeny centrální konfigurací.
- Opravena kompatibilita [`scripts/offline.bat`](scripts/offline.bat) odstraněním UTF-8 BOM, který způsoboval chybnou interpretaci prvního příkazu při spuštění v CMD.

## [v0.3.0] - Rockstar Launcher - 2026-10-25

### Přidáno

- Funkční modul [`scripts/launcher.bat`](scripts/launcher.bat) pro spuštění a aktivaci Rockstar Games Launcheru.
- Konfigurace `ROCKSTAR_PATCHER`, `TIMEOUT_LAUNCHER` a `TIMEOUT_WINDOW`.
- Dokumentace modulu [`docs/LAUNCHER.md`](docs/LAUNCHER.md).

### Opraveno

- Testovací režim launcheru nyní po úspěchu zobrazí správný HWND.

## [v0.2.0] - Central Configuration - 2026-10-23

### Přidáno

- Centrální konfigurační soubor [`config/config.bat`](config/config.bat).
- Konfigurační hodnoty `LOG_KEEP` a `LOG_LEVEL`.
- Načítání centrální konfigurace loggerem.
- Testy centrální konfigurace.

### Opraveno

- Test výchozích hodnot konfigurace se nyní izoluje od proměnných zděděných z prostředí.
- Dokumentace upřesňuje, že `LOG_LEVEL` je připraveno pro budoucí filtrování a aktuálně neovlivňuje zápis loggeru.

## [v0.1.0] - Central Logger - 2026-10-23

### Přidáno

- Centrální logger pro průběžné logování běhu nástroje.
- Samostatný provozní log pro každé spuštění.
- Centrální `gta-v-cz-en-switch-latest.log` pro poslední dokončený běh.
- Logovací úrovně `DEBUG`, `INFO`, `WARN` a `ERROR`.
- Evidence jednotlivých kroků a měření jejich doby.
- Měření celkové doby běhu.
- Retence provozních logů (posledních 30 běhů; `latest` se do počtu nezapočítává).
- Identifikátor běhu s milisekundami a ID procesu.
- Automatické uzavření rozpracovaného kroku při `FINISH`.
- Bezpečný zápis do logu a konzole pro zprávy se znaky `& | < > !`.
- Test loggeru pro standardní úspěšný běh.
- Test loggeru pro záměrně předčasně ukončený běh.
- Možnost spustit testy bez pauzy pomocí proměnné `NOPAUSE`.

## [v0.0.0] - Initial Project Foundation - 2026-10-23

### Přidáno

- Počáteční struktura repozitáře.
- Pravidla pro konce řádků v souborech BAT a dokumentaci – [`.gitattributes`](.gitattributes).
- Ignorování provozních logů a generovaných výstupů – [`.gitignore`](.gitignore).
- Společná ANSI barevná paleta – [`colors.bat`](core/colors.bat).
- Připravená struktura pro konfiguraci, funkce a hlavní vstupní bod.
