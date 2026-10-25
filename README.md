# README

## GTA V CZ/EN Switch

Nástroj pro Windows určený k přepínání české a anglické lokalizace hry Grand Theft Auto V Enhanced přes Rockstar Games Launcher.

## Stav projektu

Základní struktura a pravidla repozitáře jsou připravené; implementace společných komponent a jednotlivých funkcí se doplňuje postupně.

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

## Dokumentace

Podrobnější dokumentace projektu:

- [`COLORS.md`](docs/COLORS.md) – ANSI barevná paleta
- [`GIT.md`](docs/GIT.md) – Pravidla repozitáře a Git workflow
- [`LAUNCHER.md`](docs/LAUNCHER.md) – Dokumentace modulu Rockstar Launcher
- [`PROJECT.md`](docs/PROJECT.md) – Architektura projektu

## Licence

Projekt je vydán pod licencí MIT. Podrobnosti jsou uvedeny v souboru [`LICENSE`](LICENSE).

Pro snazší porozumění je k dispozici také [český informativní překlad licence](docs/LICENSE-CZ.md). Právně rozhodující je vždy originální anglické znění licence.
