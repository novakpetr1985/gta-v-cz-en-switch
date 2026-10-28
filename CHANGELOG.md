# CHANGELOG

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
- Opravena kompatibilita[`scripts/offline.bat`](scripts/offline.bat) odstraněním UTF-8 BOM, který způsoboval chybnou interpretaci prvního příkazu při spuštění v CMD.

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
- Retence provozních logů (posledních 30 běhů, řazení podle `RUN_ID`; `latest` se do počtu nezapočítává).
- Identifikátor běhu s milisekundami a ID procesu, aby rychlé nebo souběžné běhy nesdílely stejný log.
- Automatické uzavření rozpracovaného kroku při `FINISH`.
- Bezpečný zápis do logu a konzole pro zprávy se znaky `& | < > !`.
- Test loggeru pro standardní úspěšný běh s automatickou kontrolou obsahu logu a návratovým kódem.
- Test loggeru pro záměrně předčasně ukončený běh s automatickou kontrolou logu a návratovým kódem.
- Možnost spustit testy bez pauzy pomocí proměnné `NOPAUSE`.

## [v0.0.0] - Initial Project Foundation - 2026-10-23

### Přidáno

- Počáteční struktura repozitáře.
- Pravidla pro konce řádků v souborech BAT a dokumentaci – [`.gitattributes`](.gitattributes).
- Ignorování provozních logů a generovaných výstupů – [`.gitignore`](.gitignore).
- Společná ANSI barevná paleta – [`colors.bat`](core/colors.bat).
- Připravené prázdné soubory pro konfiguraci, jednotlivé funkce a hlavní vstupní bod – [`config.bat`](config/config.bat), [`scripts/`](scripts/), [`gta-v-cz-en-switch.bat`](gta-v-cz-en-switch.bat).
- Základní projektová dokumentace:
  - Dokumentace ANSI barevné palety – [COLORS.md](docs/COLORS.md).
  - Dokumentace Git workflow a pravidel repozitáře – [GIT.md](docs/GIT.md).
  - Dokumentace architektury projektu – [PROJECT.md](docs/PROJECT.md).
- MIT licence projektu – [LICENSE](LICENSE).
- Český informativní překlad licence – [LICENSE-CZ.md](docs/LICENSE-CZ.md).
