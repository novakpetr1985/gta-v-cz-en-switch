# PROJECT

## Architektura projektu

## Účel

Projekt poskytuje sadu BAT skriptů pro správu přepínání české a anglické lokalizace hry Grand Theft Auto V Enhanced přes Rockstar Launcher.

## Struktura

```text
gta-v-cz-en-switch/
│
├── config/                                   Konfigurace nástroje
│   └── config.bat                            Hlavní konfigurační soubor                  Připraveno
│
├── core/                                     Sdílené komponenty pro skripty
│   ├── colors.bat                            Centrální ANSI barevná paleta               Připraveno
│   └── logger.bat                            Centrální logger                            Připraveno
│
├── diagnostics/                              Diagnostické nástroje a výstupy
│   └── .gitkeep                              Zachování prázdného adresáře v Gitu         Prázdný soubor
│
├── docs/                                     Projektová dokumentace
│   ├── COLORS.md                             Dokumentace ANSI barevné palety             Připraveno
│   ├── GIT.md                                Pravidla repozitáře a Git workflow          Připraveno
│   ├── LICENSE-CZ.md                         Český informativní překlad licence          Připraveno
│   ├── PROJECT.md                            Architektura a princip projektu             Připraveno
│   └── UIA.md                                Dokumentace Windows UI Automation           Připraveno
│
├── logs/                                     Provozní záznamy
│   └── .gitkeep                              Zachování prázdného adresáře v Gitu         Prázdný soubor
│
├── scripts/                                  Funkční skripty nástroje
│   ├── launcher.bat                          Práce s Rockstar Games Launcherem           Bude doplněno
│   ├── offline.bat                           Přepnutí launcheru do offline režimu        Bude doplněno
│   ├── switch-cz.bat                         Přepnutí na českou lokalizaci               Bude doplněno
│   ├── switch-en.bat                         Přepnutí na anglickou lokalizaci            Bude doplněno
│   ├── uia.bat                               Windows UI Automation vrstva                Připraveno
│   └── update.bat                            Aktualizace nebo příprava souborů           Bude doplněno
│
├── tests/                                    Testovací skripty a podpůrné soubory
│   ├── logger/                               Testy centrálního loggeru
│   │   ├── test-logger-failure.bat           Záměrně předčasně ukončený běh              Připraveno
│   │   └── test-logger-success.bat           Standardní úspěšný běh                      Připraveno
│   ├── config/                               Testy centrální konfigurace
│   │   ├── test-config-defaults.bat          Výchozí hodnoty konfigurace                Připraveno
│   │   ├── test-config-overrides.bat         Zachování přepsaných hodnot               Připraveno
│   │   └── test-config-partial-override.bat  Částečné přepsání konfigurace      Připraveno
│   └── uia/                                  Testy Windows UI Automation
│       ├── test-uia-success.bat              Úspěšná aktivace `PLAY`              Připraveno
│       ├── test-uia-not-found.bat            Nenalezení cílového prvku            Připraveno
│       ├── test-uia-dump.bat                 Diagnostický dump                    Připraveno
│       ├── test-uia-no-dump-success.bat      Úspěch bez dumpu                     Připraveno
│       ├── test-uia-invalid-input.bat        Neplatný vstup                      Připraveno
│       ├── test-uia-timeout.bat              Timeout hledání                      Připraveno
│       └── test-uia-timing.bat               Timing diagnostika                   Připraveno
│
├── .gitattributes                  Pravidla pro konce řádků a textové soubory  Připraveno
├── .gitignore                      Pravidla pro ignorované soubory             Připraveno
├── CHANGELOG.md                    Přehled významných změn mezi verzemi        Připraveno
├── gta-v-cz-en-switch.bat          Hlavní vstupní bod nástroje                 Bude doplněno
├── LICENSE                         Licence projektu                            Připraveno
└── README.md                       Stručný úvod a odkazy na dokumentaci        Připraveno
```

## Popis složek a souborů

- [`gta-v-cz-en-switch.bat`](../gta-v-cz-en-switch.bat) – hlavní vstupní bod nástroje.
- [`config/`](../config/) – konfigurace nástroje. Obsahuje hodnoty používané jednotlivými skripty.
- [`core/`](../core/) – sdílené komponenty, například [`colors.bat`](../core/colors.bat) a [`logger.bat`](../core/logger.bat). Soubory v této složce poskytují společnou logiku ostatním skriptům.
- [`diagnostics/`](../diagnostics/) – lokálně generované diagnostické výstupy pro řešení problémů. Jejich obsah se neukládá do Gitu; verzován zůstává pouze soubor `.gitkeep`.
- [`docs/`](../docs/) – projektová dokumentace, architektura, technická dokumentace a pravidla projektu.
- [`logs/`](../logs/) – lokálně generované provozní záznamy. Jejich obsah se neukládá do Gitu; verzován zůstává pouze soubor `.gitkeep`.
- [`scripts/`](../scripts/) – vlastní funkční skripty nástroje, například přepínání jazyka, aktualizace nebo Windows UI Automation.
- [`tests/`](../tests/) – testovací skripty, testovací data a podpůrné soubory.
  - [`tests/logger/`](../tests/logger/) – testy centrálního loggeru.
  - [`test-logger-success.bat`](../tests/logger/test-logger-success.bat) – ověřuje standardní úspěšný průběh loggeru a automaticky kontroluje obsah logu.
  - [`test-logger-failure.bat`](../tests/logger/test-logger-failure.bat) – ověřuje průběžné logování při záměrném předčasném ukončení běhu a automaticky kontroluje obsah logu.
  - [`tests/config/`](../tests/config/) – testy centrální konfigurace.
  - [`tests/uia/`](../tests/uia/) – automatizované testy Windows UI Automation.
    - `test-uia-success.bat` – ověřuje úspěšnou aktivaci prvku `PLAY`.
    - `test-uia-not-found.bat` – ověřuje výsledek `NOT_FOUND`.
    - `test-uia-dump.bat` – ověřuje vytvoření a obsah diagnostického dumpu.
    - `test-uia-no-dump-success.bat` – ověřuje úspěšný běh bez vytvoření dumpu.
    - `test-uia-invalid-input.bat` – ověřuje odmítnutí neplatného vstupu.
    - `test-uia-timeout.bat` – ověřuje chování při limitu hledání.
    - `test-uia-timing.bat` – ověřuje timing diagnostiku a očekávané události.

## Klíčové soubory v kořenu

- [`.gitattributes`](../.gitattributes) – pravidla pro konce řádků a textové soubory.
- [`.gitignore`](../.gitignore) – pravidla pro soubory a složky neukládané do Gitu.
- [`CHANGELOG.md`](../CHANGELOG.md) – přehled významných změn mezi verzemi.
- [`LICENSE`](../LICENSE) – MIT licence projektu.
- [`LICENSE-CZ.md`](./LICENSE-CZ.md) – český informativní překlad licence MIT.
- [`README.md`](../README.md) – stručný úvod do projektu a odkazy na dokumentaci.

## Konfigurace

Centrální konfigurace nástroje je umístěna v [`config/config.bat`](../config/config.bat).

Konfigurační soubor je načítán jednotlivými komponentami pomocí `CALL` a obsahuje výchozí hodnoty sdílené napříč aplikací.

Aktuálně jsou definovány:

- `LOG_KEEP` – počet posledních provozních logů, které mají být zachovány. Výchozí hodnota je `30`.
- `LOG_LEVEL` – výchozí úroveň loggeru pro budoucí filtrování zpráv. Aktuálně je nastavena na `INFO`, logger ji však zatím nepoužívá jako filtr; `DEBUG` a `DETAIL` záznamy se proto nadále zapisují do logu.

Hodnoty jsou nastavovány pouze v případě, že již nejsou definovány volajícím skriptem.

### Testy konfigurace

Testy v [`tests/config/`](../tests/config/) ověřují základní chování centrální konfigurace.

- [`test-config-defaults.bat`](../tests/config/test-config-defaults.bat) – ověřuje výchozí hodnoty `LOG_KEEP=30` a `LOG_LEVEL=INFO`.
- [`test-config-overrides.bat`](../tests/config/test-config-overrides.bat) – ověřuje zachování hodnot předem nastavených volajícím skriptem.
- [`test-config-partial-override.bat`](../tests/config/test-config-partial-override.bat) – ověřuje zachování přednastavené hodnoty a současné doplnění chybějící výchozí hodnoty.

## Logger

Centrální logger je umístěn v [`core/logger.bat`](../core/logger.bat).

Logger poskytuje společné logování pro jednotlivé skripty nástroje a zapisuje události průběžně během běhu.

Každé spuštění vytváří vlastní provozní log s jedinečným identifikátorem běhu (`RUN_ID`). Ten obsahuje datum, čas s milisekundami a ID pomocného procesu PowerShellu, aby se rychle po sobě nebo souběžně spuštěné běhy nesdílely jeden soubor. Dokončený běh je následně dostupný také prostřednictvím `gta-v-cz-en-switch-latest.log` (kopie posledního dokončeného logu).

Logger podporuje úrovně:

- `DEBUG`
- `INFO`
- `WARN`
- `ERROR`

Součástí logování je také evidence kroků, měření jejich doby, měření celkové doby běhu a informace o výsledku dokončení.

`FINISH` automaticky uzavře případný rozpracovaný krok, takže jeho doba i počet dotazů zůstanou zaznamenány.

Retence ponechává posledních 30 běhů (`LOG_KEEP`), řazených podle názvu s `RUN_ID`. Soubor `gta-v-cz-en-switch-latest.log` se do tohoto počtu nezapočítává, protože jeho název neodpovídá vzoru `gta-v-cz-en-switch_*.log`.

Zprávy předávané loggeru mohou obsahovat znaky `& | < > !`. Dvojité uvozovky (`"`) se ve zprávách nepoužívají; místo nich se používá apostrof.

Po prvním volání logger zpřístupní volajícímu skriptu proměnné `RUN_ID`, `RUN_LOG`, `LOG_FILE`, `LATEST_LOG`, `LOG_DIR`, `CORE_DIR` a `PROJECT_DIR`; není nutné je znovu sestavovat. Stav loggeru zůstává ve stejném prostředí, proto má skript, který jej používá, podle potřeby začínat příkazem `SETLOCAL`.

Při předčasném ukončení běhu bez volání `FINISH` zůstává zachován samostatný log s posledním průběžně zaznamenaným stavem. Takový běh neaktualizuje `gta-v-cz-en-switch-latest.log` a neobsahuje `SCRIPT_END`.

### Testy loggeru

Testy v [`tests/logger/`](../tests/logger/) volají logger a po dokončení automaticky kontrolují obsah aktuálního logu (`RUN_LOG`) i kopii `gta-v-cz-en-switch-latest.log`. Výsledek kontrol je vypsán jako `[ OK ]` nebo `[FAIL]`.

- Návratový kód testu: `0` = všechny kontroly prošly, `1` = některá kontrola selhala nebo nebyl nalezen logger.
- `test-logger-failure.bat` záměrně nevolá `FINISH`; kód `0` zde znamená, že se logger při předčasném ukončení chová správně.
- Pro spuštění bez čekání na klávesu: `set NOPAUSE=1`.
- Automaticky se neověřuje, že `DEBUG` a zprávy s parametrem `F` nejsou vidět v konzoli; to je nutné zkontrolovat při spuštění.

## UI Automation

Windows UI Automation vrstva je umístěna v [`scripts/uia.bat`](../scripts/uia.bat).

UIA slouží jako společná nízkoúrovňová vrstva pro práci s grafickým rozhraním Windows a Rockstar Games Launcheru. Modul je připraven pro vyhledávání a aktivaci UI prvků a pro diagnostiku problémů při jejich nalezení.

Pro podrobný popis použití a chování modulu je k dispozici [`UIA.md`](./UIA.md).

UIA je aktuálně ověřeno kompletní automatizovanou sadou `7 / 7` testů PASSED. Testy pokrývají úspěšnou aktivaci, nenalezení prvku, diagnostický dump, běh bez dumpu, neplatný vstup, timeout hledání a timing diagnostiku.


## Zásady

- Společná logika patří do [`core/`](../core/).
- Funkční skripty patří do [`scripts/`](../scripts/).
- Zdrojové skripty se neukládají do [`logs/`](../logs/) ani [`diagnostics/`](../diagnostics/).
- Provozní logy a diagnostické výstupy nesmí obsahovat citlivé údaje.
- Generovaná lokální data se necommitují.
