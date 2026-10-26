# Offline Module

## Přehled

`offline.bat` je samostatný funkční modul projektu **GTA V CZ/EN Switch**. Jeho úkolem je přepnout **Rockstar Games Launcher** do offline režimu a ověřit, že byl offline režim skutečně aktivován.

Offline modul je v současné fázi vyvíjen a testován **nezávisle na `launcher.bat`**. Při samostatném běhu pouze předpokládá, že Rockstar Games Launcher je již spuštěný.

Modul je navržen tak, aby:

- mohl být spuštěn samostatně,
- nebyl závislý na `launcher.bat`,
- mohl být později volán z hlavního orchestrátoru,
- používal centrální konfiguraci projektu,
- používal centrální logger,
- vracel návratový kód pro nadřazený orchestrátor,
- při selhání automatického ovládání umožnil ruční dokončení.

---

## Umístění

```text
scripts/offline.bat
```

Tento dokument je uložen v:

```text
docs/OFFLINE.md
```

Modul využívá společné komponenty projektu:

```text
config/config.bat
core/logger.bat
```

Při selhání hledání cílového prvku UI Automation může být vytvořen diagnostický výstup:

```text
diagnostics/gta_v_cz_en_offline_uia_dump.txt
```

---

## Předpoklady samostatného běhu

Offline modul při samostatném testování nepřipravuje ani nespouští Rockstar Games Launcher.

Před spuštěním musí být:

- Rockstar Games Launcher spuštěný,
- dostupný `launcher.log`,
- načtená centrální konfigurace,
- dostupný centrální logger.

To je záměrné. Offline modul je samostatná funkce a jeho současný vývoj není závislý na dokončení ani spuštění `launcher.bat`.

---

## Účel modulu

Offline modul provádí následující workflow:

```text
Kontrola Launcheru a launcher.log
        │
        ▼
Zjištění aktuálního stavu
        │
        ├── Offline + Signed In
        │       └── SUCCESS
        │
        └── Online
                │
                ▼
        Aktivace Rockstar Launcheru
                │
                ▼
             Settings
                │
                ▼
           GO OFFLINE
                │
        ┌───────┴────────┐
        ▼                ▼
 UI Automation      Fyzický klik
    Invoke              myší
        │                │
        └───────┬────────┘
                │
                ▼
         Ruční fallback
                │
                ▼
        Ověření offline stavu
                │
                ▼
             SUCCESS
```

---

## Ověření offline režimu

Modul nepovažuje samotné stisknutí `GO OFFLINE` za dostatečné.

Po aktivaci offline režimu sleduje `launcher.log` a ověřuje:

1. aktuální běh Rockstar Launcheru,
2. řádek `startupinfo] Command line:`,
3. přítomnost parametru:

```text
-scOfflineOnly
```

4. následný stav:

```text
Signed In
```

Teprve kombinace `-scOfflineOnly` a následného `Signed In` je považována za potvrzený offline režim.

---

## Kontrola aktuálního stavu

Před pokusem o přepnutí modul nejprve kontroluje aktuální stav Launcheru.

Používá časový marker vytvořený před kontrolou logu, aby mohl rozlišit záznamy vztahující se k aktuálnímu běhu.

Interní kontrola `OFFLINE_STATE` používá tyto stavy:

| Kód | Stav |
| :---: | :---: |
| `0` | Offline režim je aktivní a je potvrzen `Signed In` |
| `1` | Launcher je online |
| `2` | Offline režim je detekován, ale zatím není potvrzen `Signed In` |
| `3` | Rozhodující `Command line` záznam zatím nebyl nalezen |
| `9` | Chyba při čtení nebo zpracování `launcher.log` |

Tyto interní kódy jsou používány pro rozhodování uvnitř modulu.

---

## Přepnutí do offline režimu

Pokud je Launcher online, modul otevře Settings a pokusí se aktivovat `GO OFFLINE`.

### 1. UI Automation Invoke

První pokus používá Windows UI Automation a metodu `Invoke`.

Hledaný prvek může být identifikován například pomocí:

```text
GO OFFLINE
Go Offline
Go offline
```

a navigace přes:

```text
SETTINGS
Settings
```

Pokud je `Invoke` úspěšný, modul pokračuje na ověření offline režimu.

### 2. Fyzický klik myší

Pokud UI Automation `Invoke` selže, modul použije fyzický klik myší.

Pokud je klik úspěšný, pokračuje stejně na ověření offline režimu.

### 3. Ruční fallback

Pokud selžou oba automatické způsoby, modul uživatele vyzve k ručnímu kliknutí na:

```text
Settings → GO OFFLINE
```

Po ručním zásahu modul nepovažuje operaci automaticky za úspěšnou. Nadále kontroluje `launcher.log` a čeká na skutečné potvrzení offline režimu.

---

## Časové limity

Modul používá dvě časová omezení z centrální konfigurace:

| Konfigurace | Význam |
| :---: | :---: |
| `TIMEOUT_OFFLINE_EFFECT` | Maximální doba čekání na potvrzení po automatickém kliknutí |
| `TIMEOUT_OFFLINE_MANUAL` | Maximální doba pro ruční dokončení operace |

Aktuální výchozí hodnoty jsou definovány v `config/config.bat`.

Časový limit představuje **maximální dobu čekání**, nikoliv pevnou dobu, po kterou modul vždy čeká.

Jakmile je offline stav potvrzen, modul pokračuje okamžitě.

---

## Návratový kód modulu

Pro komunikaci s budoucím orchestrátorem používá modul výsledný návratový kód:

| Návratový kód | Výsledek |
| :---: | :---: |
| `0` | Offline režim byl úspěšně potvrzen |
| `1` | Nepodařilo se přepnout Launcher do offline režimu |
| `9` | Kritická chyba, například problém s `launcher.log` |

Orchestrátor může výsledek vyhodnotit například:

```bat
call "%~dp0scripts\offline.bat"

if errorlevel 1 goto END_ERROR
```

Při návratovém kódu `0` může orchestrátor pokračovat dalším krokem.

---

## Logger

Offline modul je napojen na centrální logger projektu.

Loguje zejména:

- začátek jednotlivých kroků,
- aktivaci okna Rockstar Launcheru,
- použitou metodu aktivace `GO OFFLINE`,
- čekání na potvrzení offline režimu,
- úspěšné dokončení,
- chyby.

Příklad úspěšného průběhu:

```text
STEP [3/3] Prepinam Rockstar Launcher do offline rezimu.
INFO Oteviram Settings a hledam GO OFFLINE.
SUCCESS GO OFFLINE byl aktivovan metodou Invoke.
WAIT Cekam na potvrzeni offline rezimu...
SUCCESS Rockstar Launcher bezi v offline rezimu.
```

---

## Diagnostika UI Automation

Výkonnostní timing diagnostika není součástí produkčního běhu.

Při selhání hledání prvku UI Automation může být vytvořen diagnostický dump:

```text
diagnostics/gta_v_cz_en_offline_uia_dump.txt
```

Dump slouží pouze k analýze problému s UI Automation.

Běžný úspěšný běh tento diagnostický soubor nepotřebuje.

---

## Samostatné spuštění

Offline modul lze během vývoje spustit samostatně:

```bat
scripts\offline.bat
```

Před spuštěním musí být Rockstar Games Launcher již spuštěný.

Samostatný test ověřuje vlastní funkčnost Offline modulu bez volání `launcher.bat`.

---

## Aktuální stav testování

Offline modul byl samostatně ověřen s funkčním automatickým ovládáním přes Windows UI Automation `Invoke`.

Ověřený průběh:

```text
1. Příprava offline režimu
2. Aktivace okna Rockstar Launcheru
3. Otevření Settings
4. Aktivace GO OFFLINE pomocí UI Automation Invoke
5. Ověření offline režimu přes launcher.log
6. Návratový kód 0
```

Automatická metoda `Invoke` byla při testu úspěšná, takže fyzický klik a ruční fallback slouží jako záložní mechanismy a nebyly v tomto úspěšném běhu použity.

Integrační test s `launcher.bat` bude proveden až v samostatné integrační fázi.

---

## Integrační workflow

Offline modul je integrován s Launcher modulem v testovací větvi `test/scripts-launcher-offline`.

Aktuální vývojový model je:

```text
Launcher ────────→ samostatné testy
     │
     │
Offline ─────────→ samostatné testy
     │
     ▼
pozdější integrační test
```

Po spojení obou modulů může hlavní orchestrátor používat například:

```text
gta-v-cz-en-switch.bat
        │
        ├── launcher.bat
        │
        └── offline.bat
```

Samostatné spuštění modulu zůstává podporované pro diagnostiku.

---

## Související dokumentace

- [README.md](../README.md) – hlavní dokumentace projektu
- [PROJECT.md](PROJECT.md) – architektura projektu
- [GIT.md](GIT.md) – Git workflow
- [COLORS.md](COLORS.md) – ANSI barevná paleta
- [gta-v-cz-en-switch.bat](../gta-v-cz-en-switch.bat) – hlavní vstupní bod
- [config/config.bat](../config/config.bat) – centrální konfigurace
- [core/logger.bat](../core/logger.bat) – centrální logger
- [scripts/launcher.bat](../scripts/launcher.bat) – samostatný Launcher modul
- [scripts/offline.bat](../scripts/offline.bat) – implementace Offline modulu
