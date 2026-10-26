# README

## GTA V CZ/EN Switch

Nástroj pro Windows určený k přepínání české a anglické lokalizace hry Grand Theft Auto V Enhanced přes Rockstar Games Launcher.

## Stav projektu

Základní struktura a pravidla repozitáře jsou připravené; implementace společných komponent a jednotlivých funkcí se doplňuje postupně.

| Modul | Stav | Verze |
| :---: | :---: | :---: |
| Logger | OK | v0.1.0 |
| Config | OK | v0.2.0 |
| Launcher | OK | v0.3.0 |
| Offline | OK | v0.4.0 |

## Struktura projektu

- [`config/`](config/) – konfigurace
    - [`config.bat`](config/config.bat) – hlavní konfigurační soubor
- [`core/`](core/) – společné komponenty pro BAT skripty
- [`diagnostics/`](diagnostics/) – diagnostické nástroje a výstupy
- [`docs/`](docs/) – základní a technická dokumentace projektu
- [`logs/`](logs/) – provozní záznamy
- [`scripts/`](scripts/) – jednotlivé funkce nástroje
- [`tests/`](tests/) – testovací skripty a soubory
    - [`logger/`](tests/logger/) – testy centrálního loggeru
        - [`test-logger-success.bat`](tests/logger/test-logger-success.bat) – test standardního úspěšného běhu s automatickou kontrolou logu
        - [`test-logger-failure.bat`](tests/logger/test-logger-failure.bat) – test předčasně ukončeného běhu s automatickou kontrolou logu
    - [`config/`](tests/config/) – testy centrální konfigurace
        - [`test-config-defaults.bat`](tests/config/test-config-defaults.bat) – ověření výchozích hodnot konfigurace
        - [`test-config-overrides.bat`](tests/config/test-config-overrides.bat) – ověření zachování přepsaných hodnot
        - [`test-config-partial-override.bat`](tests/config/test-config-partial-override.bat) – ověření částečného přepsání konfigurace

## Nezávislé moduly

V současné fázi jsou Launcher a Offline vyvíjeny jako dva samostatné moduly.

```text
dev
├── feature/launcher
│       └── launcher.bat
│
└── feature/offline
        └── offline.bat
```

Offline modul při samostatném testu předpokládá, že Rockstar Games Launcher je již spuštěný. Nevolá `launcher.bat` a není na něm při běhu závislý.

Po dokončení a samostatném otestování obou modulů bude provedena jejich integrace do hlavního orchestrátoru.

## Hlavní vstupní bod

Hlavním vstupním bodem aplikace je [`gta-v-cz-en-switch.bat`](gta-v-cz-en-switch.bat).

Finální workflow bude postupně procházet jednotlivými moduly:

```text
gta-v-cz-en-switch.bat
        │
        ▼
launcher.bat
        │
        ▼
offline.bat
        │
        ▼
další funkce
```

Jednotlivé moduly jsou navrženy tak, aby mohly být během vývoje testovány také samostatně. Propojení bude součástí následné integrační fáze.

## Dokumentace

Podrobnější dokumentace projektu:

- [`COLORS.md`](docs/COLORS.md) – ANSI barevná paleta
- [`GIT.md`](docs/GIT.md) – Pravidla repozitáře a Git workflow
- [`PROJECT.md`](docs/PROJECT.md) – Architektura projektu
- [`OFFLINE.md`](docs/OFFLINE.md) – Offline modul

## Licence

Projekt je vydán pod licencí MIT. Podrobnosti jsou uvedeny v souboru [`LICENSE`](LICENSE).

Pro snazší porozumění je k dispozici také [český informativní překlad licence](docs/LICENSE-CZ.md). Právně rozhodující je vždy originální anglické znění licence.
