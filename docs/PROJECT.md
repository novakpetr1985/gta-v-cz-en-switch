# PROJECT

## Architektura projektu

## Účel

Projekt poskytuje sadu BAT skriptů pro správu přepínání české a anglické lokalizace hry Grand Theft Auto V Enhanced přes Rockstar Launcher.

## Struktura

```text
gta-v-cz-en-switch/
│
├── config/                         Konfigurace nástroje
│   └── config.bat                  Hlavní konfigurační soubor                  Bude doplněno
│
├── core/                           Sdílené komponenty pro skripty
│   └── colors.bat                  Centrální ANSI barevná paleta               Připraveno
│
├── diagnostics/                    Diagnostické nástroje a výstupy
│   └── .gitkeep                    Zachování prázdného adresáře v Gitu         Prázdný soubor
│
├── docs/                           Projektová dokumentace
│   ├── COLORS.md                   Dokumentace ANSI barevné palety             Připraveno
│   ├── GIT.md                      Pravidla repozitáře a Git workflow          Připraveno
│   ├── LICENSE-CZ.md               Český informativní překlad licence          Připraveno
│   └── PROJECT.md                  Architektura a princip projektu             Připraveno
│
├── logs/                           Provozní záznamy
│   └── .gitkeep                    Zachování prázdného adresáře v Gitu         Prázdný soubor
│
├── scripts/                        Funkční skripty nástroje
│   ├── launcher.bat                Práce s Rockstar Games Launcherem           Bude doplněno
│   ├── offline.bat                 Přepnutí launcheru do offline režimu        Bude doplněno
│   ├── switch-cz.bat               Přepnutí na českou lokalizaci               Bude doplněno
│   ├── switch-en.bat               Přepnutí na anglickou lokalizaci            Bude doplněno
│   ├── uia.bat                     Ověření dostupnosti služby                  Bude doplněno
│   └── update.bat                  Aktualizace nebo příprava souborů           Bude doplněno
│
├── tests/                          Testovací skripty a podpůrné soubory
│   └── .gitkeep                    Zachování prázdného adresáře v Gitu         Prázdný soubor
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
- [`core/`](../core/) – sdílené komponenty, například [`colors.bat`](../core/colors.bat). Soubory v této složce poskytují společnou logiku ostatním skriptům.
- [`diagnostics/`](../diagnostics/) – lokálně generované diagnostické výstupy pro řešení problémů. Jejich obsah se neukládá do Gitu; verzován zůstává pouze soubor `.gitkeep`.
- [`docs/`](../docs/) – projektová dokumentace, architektura a pravidla projektu.
- [`logs/`](../logs/) – lokálně generované provozní záznamy. Jejich obsah se neukládá do Gitu; verzován zůstává pouze soubor `.gitkeep`.
- [`scripts/`](../scripts/) – vlastní funkční skripty nástroje, například přepínání jazyka, aktualizace nebo ověření dostupnosti služby.
- [`tests/`](../tests/) – testovací skripty, testovací data a podpůrné soubory.

## Klíčové soubory v kořenu

- [`.gitattributes`](../.gitattributes) – pravidla pro konce řádků a textové soubory.
- [`.gitignore`](../.gitignore) – pravidla pro soubory a složky neukládané do Gitu.
- [`CHANGELOG.md`](../CHANGELOG.md) – přehled významných změn mezi verzemi.
- [`LICENSE`](../LICENSE) – MIT licence projektu.
- [`LICENSE-CZ.md`](./LICENSE-CZ.md) – český informativní překlad licence MIT.
- [`README.md`](../README.md) – stručný úvod do projektu a odkazy na dokumentaci.

## Zásady

- Společná logika patří do [`core/`](../core/).
- Funkční skripty patří do [`scripts/`](../scripts/).
- Zdrojové skripty se neukládají do [`logs/`](../logs/) ani [`diagnostics/`](../diagnostics/).
- Provozní logy a diagnostické výstupy nesmí obsahovat citlivé údaje.
- Generovaná lokální data se necommitují.
