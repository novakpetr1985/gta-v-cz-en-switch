# GTA V CZ/EN Switch - Launcher

## Účel

Modul Launcher zajišťuje přípravu a spuštění Rockstar Games Launcheru jako prvního funkčního kroku hlavního nástroje.

Jeho úkolem je:

1. ověřit dostupnost `LauncherPatcher.exe`,
2. zjistit, zda již běží `Launcher.exe`,
3. pokud Launcher neběží, spustit `LauncherPatcher.exe`,
4. počkat na spuštění `Launcher.exe`,
5. vyhledat viditelné okno Rockstar Launcheru,
6. obnovit okno, pokud je minimalizované,
7. pokusit se okno aktivovat do popředí,
8. vrátit výsledek hlavnímu orchestrátoru.

Modul samotný neukončuje celý běh aplikace. O konečné ukončení a udělení výsledného návratového kódu se stará hlavní orchestrátor.

---

## Soubory

Launcher je součástí následujícího celku:

```text
gta-v-cz-en-switch.bat
│
├── core/
│   └── logger.bat
│
├── config/
│   └── config.bat
│
└── scripts/
    └── launcher.bat
```

### `gta-v-cz-en-switch.bat`
[`gta-v-cz-en-switch.bat`](../gta-v-cz-en-switch.bat)

Hlavní vstupní bod aplikace.

Orchestrátor:

* inicializuje společný logger,
* načte a připraví prostředí aplikace,
* zavolá `scripts/launcher.bat`,
* vyhodnotí jeho návratový kód,
* při úspěchu pokračuje nebo ukončí aktuální běh,
* při chybě přejde na chybové ukončení,
* jako jediný uzavírá celý běh pomocí `FINISH`.

### [`scripts/launcher.bat`](../scripts/launcher.bat)

Vlastní funkční modul pro Rockstar Launcher.

Skript není určen k řízení celého běhu aplikace. Vrací pouze výsledek své vlastní funkce.

### [`core/logger.bat`](../core/logger.bat)

Centrální logger používaný Launcherem pro průběžné logování kroků, čekání, úspěchů a chyb.

### [`config/config.bat`](../config/config.bat)

Centrální konfigurace hodnot používaných Launcherem.

---

## Konfigurace

Launcher využívá následující hodnoty:

| Proměnná           | Význam                                                            |
| ------------------ | ----------------------------------------------------------------- |
| `ROCKSTAR_PATCHER` | Cesta k `LauncherPatcher.exe`                                     |
| `ROCKSTAR_LOG_DIR` | Adresář Rockstar Launcheru připravený pro další práci s jeho logy |
| `TIMEOUT_LAUNCHER` | Maximální doba čekání na `Launcher.exe`                           |
| `TIMEOUT_WINDOW`   | Maximální doba čekání na viditelné okno Rockstar Launcheru        |

Výchozí konfigurace je umístěna v:

```text
config/config.bat
```

Konfigurace je načítána centrálně a Launcher ji pouze využívá.

---

## Průběh

Launcher pracuje ve dvou hlavních krocích.

### KROK 1/2 – Příprava Rockstar Launcheru

Nejprve se ověří konfigurace a dostupnost `LauncherPatcher.exe`.

Pokud `Launcher.exe` již běží:

* Launcher se znovu nespouští,
* zjistí se PID existujícího procesu,
* pokračuje se na čekání a aktivaci okna.

Pokud `Launcher.exe` neběží:

* připraví se informace o zahájení běhu,
* spustí se `LauncherPatcher.exe`,
* pokračuje se čekáním na `Launcher.exe`.

---

### KROK 2/2 – Čekání na Launcher a aktivace okna

Po spuštění nebo nalezení `Launcher.exe` skript čeká na dostupnost jeho viditelného okna.

Pokud okno není okamžitě dostupné, probíhá opakovaná kontrola až do hodnoty `TIMEOUT_WINDOW`.

Po nalezení okna se:

1. zjistí jeho PID,
2. zjistí jeho HWND,
3. okno se případně obnoví,
4. provede se pokus o jeho aktivaci do popředí,
5. ověří se výsledek aktivace.

Úspěšný výsledek je předán zpět hlavnímu orchestrátoru.

---

## Návratové kódy

Launcher používá jednoduchý návratový model:

| Kód | Význam                                               |
| --: | ---------------------------------------------------- |
| `0` | Launcher běží a jeho okno bylo nalezeno a aktivováno |
| `1` | Funkci Launcheru se nepodařilo dokončit              |

Hlavní orchestrátor návratový kód vyhodnocuje pomocí `ERRORLEVEL`.

---

## Integrace s loggerem

Launcher nepoužívá vlastní systém logování.

Veškeré provozní informace zapisuje prostřednictvím:

```text
core/logger.bat
```

Log obsahuje například:

* zahájení kroku,
* informace o cestě k patcheru,
* spuštění patcheru,
* nalezení `Launcher.exe`,
* PID procesu,
* čekání na okno,
* nalezení okna,
* výsledek aktivace,
* ukončení kroku.

Launcher nepoužívá `FINISH`, protože uzavření celého běhu patří hlavnímu orchestrátoru.

---

## Integrace s hlavním orchestrátorem

Hlavní orchestrátor volá:

```bat
call "%~dp0scripts\launcher.bat"
```

Následně vyhodnotí návratový kód:

```bat
if errorlevel 1 goto END_ERROR
```

Launcher tedy zůstává samostatným funkčním modulem, zatímco orchestrátor řídí celkový životní cyklus aplikace.

Toto oddělení umožňuje přidávat další funkční moduly stejným způsobem bez přesouvání jejich vlastní logiky do hlavního skriptu.

---

## Stav Launcheru

Launcher je pro verzi `v0.3.0` považován za připravený.

### Ověřený scénář

Byl proveden test, při kterém:

* aplikace inicializovala logger,
* `LauncherPatcher.exe` byl nalezen a spuštěn,
* `Launcher.exe` byl nalezen,
* proběhlo čekání na okno,
* okno Rockstar Launcheru bylo nalezeno,
* okno bylo aktivováno,
* hlavní orchestrátor obdržel návratový kód `0`,
* celý běh skončil jako `SUCCESS`.

Finální zaznamenaný běh měl návratový kód:

```text
0
```

a celkovou dobu:

```text
10,92 s
```

Výsledek:

```text
SUCCESS
```

---

## Omezení

Aktuální verze řeší spuštění, nalezení a aktivaci Rockstar Launcheru.

Automatické ovládání obsahu jeho rozhraní, výběr konkrétní hry nebo práce s jeho tray menu není součástí tohoto modulu.

Tyto funkce budou případně řešeny v dalších etapách projektu.

---

## Další vývoj

Launcher je připraven jako samostatný základ pro další části nástroje.

Další funkční moduly budou přidávány odděleně a následně napojovány do hlavního orchestrátoru.

Dokumentace Launcheru zůstává samostatná, aby změny dalších modulů zbytečně nevytvářely konflikty v této dokumentaci.
